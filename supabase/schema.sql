-- =====================================================================
-- CRM de Gestión de Cobranzas — Alchico
-- Script de base de datos para Supabase.
-- Ejecutar una sola vez en: Supabase › SQL Editor › New query › Run
-- =====================================================================

-- 1) Perfiles de usuario (uno por cada usuario de Authentication)
create table if not exists public.perfiles (
  id      uuid primary key references auth.users on delete cascade,
  email   text,
  nombre  text,
  rol     text not null default 'asesor' check (rol in ('duena', 'asesor')),
  creado  timestamptz not null default now()
);

-- Al crear un usuario en Authentication se crea su perfil como 'asesor'
create or replace function public.nuevo_usuario()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfiles (id, email, nombre)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'nombre', new.email))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.nuevo_usuario();

-- 2) Documentos del CRM (configuración, base diaria, asignaciones,
--    gestiones, recuperos, solicitudes, historial de cargas)
create table if not exists public.docs (
  path             text primary key,                         -- ej. 'config/main', 'gestiones/2026-11-16_a1'
  coleccion        text not null,                            -- ej. 'gestiones'
  mes              text generated always as (data->>'mes') stored,
  data             jsonb not null,
  actualizado      timestamptz not null default now(),
  actualizado_por  uuid default auth.uid()
);
create index if not exists docs_coleccion_idx on public.docs (coleccion);
create index if not exists docs_coleccion_mes_idx on public.docs (coleccion, mes);

-- 3) ¿El usuario actual es administrador?
--    Dueña (rol 'duena') o asesor marcado como Admin en la tabla de referencias.
create or replace function public.es_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles where id = auth.uid() and rol = 'duena')
      or exists (
        select 1
        from public.docs d,
             jsonb_array_elements(coalesce(d.data->'asesores', '[]'::jsonb)) a
        where d.path = 'config/main'
          and a->>'uid' = auth.uid()::text
          and coalesce((a->>'admin')::boolean, false)
      );
$$;

-- 4) Permisos (Row Level Security)
alter table public.perfiles enable row level security;
alter table public.docs     enable row level security;

drop policy if exists "perfiles: leer" on public.perfiles;
create policy "perfiles: leer" on public.perfiles
  for select to authenticated using (true);

drop policy if exists "docs: leer" on public.docs;
create policy "docs: leer" on public.docs
  for select to authenticated using (true);

-- Administradores: escriben todo (base, asignaciones, recuperos, referencias)
drop policy if exists "docs: admin escribe" on public.docs;
create policy "docs: admin escribe" on public.docs
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- Todos los usuarios: registran gestiones
drop policy if exists "docs: gestiones" on public.docs;
create policy "docs: gestiones" on public.docs
  for all to authenticated
  using (coleccion = 'gestiones') with check (coleccion = 'gestiones');

-- Cada usuario: su propia solicitud de vinculación
drop policy if exists "docs: solicitud propia" on public.docs;
create policy "docs: solicitud propia" on public.docs
  for all to authenticated
  using (path = 'solicitudes/' || auth.uid()::text)
  with check (path = 'solicitudes/' || auth.uid()::text and coleccion = 'solicitudes');

-- 5) Tiempo real: todos ven los cambios al instante
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;

-- 6) Restringir la ejecución directa de las funciones internas
revoke execute on function public.nuevo_usuario() from public, anon, authenticated;
revoke execute on function public.es_admin() from public, anon;
grant execute on function public.es_admin() to authenticated;

-- =====================================================================
-- DESPUÉS de crear tu usuario en Authentication › Users, ejecutá
-- (reemplazando el correo) para quedar como dueña/administradora:
--
--   update public.perfiles set rol = 'duena', nombre = 'Rocío'
--   where email = 'TU-CORREO@ejemplo.com';
-- =====================================================================
