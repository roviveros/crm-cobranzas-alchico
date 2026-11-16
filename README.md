# CRM de Gestión de Cobranzas — Alchico

Plataforma web para asignar la cartera en mora a los asesores, registrar gestiones y promesas de pago, detectar recuperos y calcular el saldo vencido de cada cliente.

- **Página:** GitHub Pages (este repositorio).
- **Datos y usuarios:** Supabase (base de datos con inicio de sesión y permisos por rol).
- **Costo:** ambos servicios son gratuitos en el volumen previsto.

| Archivo | Contenido |
| --- | --- |
| `index.html` | La aplicación completa |
| `config.js` | Dirección y clave pública de Supabase (se completa una vez) |
| `supabase/schema.sql` | Tablas y permisos de la base de datos (se ejecuta una vez) |

---

## Paso 1 — Proyecto en Supabase

> **Ya realizado (16/11/2026):** proyecto `crm-cobranzas-alchico` (región São Paulo) creado, `schema.sql` aplicado y `config.js` completado. Quedan solo los puntos 4 y 5 de este paso.

Para crearlo desde cero en otra cuenta:

1. Entrar a [supabase.com](https://supabase.com) y crear una cuenta (puede ser con GitHub).
2. **New project**: nombre `crm-cobranzas-alchico`, una contraseña de base de datos segura (guardarla) y la región más cercana (São Paulo).
3. Cuando el proyecto esté listo, ir a **SQL Editor › New query**, pegar todo el contenido de `supabase/schema.sql` y presionar **Run**.
4. Ir a **Authentication › Sign In / Providers › Email** y **desactivar "Allow new users to sign up"**. Así solo la administradora crea usuarios.
5. Ir a **Authentication › URL Configuration** y en **Site URL** poner la dirección de GitHub Pages (Paso 3), por ejemplo `https://USUARIO.github.io/crm-cobranzas-alchico/`.

## Paso 2 — Conectar la página con Supabase

1. En Supabase, **Project Settings › API**: copiar **Project URL** y la clave pública (**anon public**, o **publishable** en proyectos nuevos).
2. Editar `config.js` en este repositorio y reemplazar los dos valores.

> La clave *anon public* puede estar en el repositorio: es pública por diseño. **Nunca** subir la clave *service_role*.

## Paso 3 — Publicar con GitHub Pages

1. En el repositorio: **Settings › Pages**.
2. **Source:** *Deploy from a branch* · **Branch:** `main` · carpeta `/ (root)` · **Save**.
3. En 1 o 2 minutos la página queda disponible en `https://USUARIO.github.io/crm-cobranzas-alchico/`.

## Paso 4 — Crear los usuarios

1. Supabase › **Authentication › Users › Add user › Create new user**: correo y contraseña, marcando **Auto Confirm User**.
2. Crear primero el usuario de la administradora y luego ejecutar en **SQL Editor** (con su correo):

   ```sql
   update public.perfiles set rol = 'duena', nombre = 'Rocío'
   where email = 'correo@ejemplo.com';
   ```

3. Crear un usuario por asesor y enviarle el enlace de la página con su correo y contraseña inicial.
4. Al ingresar por primera vez, cada asesor elige su nombre y la administradora aprueba la vinculación en **Referencias**.

## Permisos

| Perfil | Puede |
| --- | --- |
| Dueña (`rol = duena`) | Todo: cargar la base, editar referencias, reasignar, aprobar asesores |
| Asesor marcado **Admin** en Referencias | Lo mismo que la dueña |
| Asesor | Registrar gestiones y promesas, consultar cartera, agenda, efectividad y recuperos |

Los permisos se aplican en la base de datos (Row Level Security), no solo en la pantalla.

## Uso diario

1. Exportar el Inventario de Cartera del sistema.
2. **Carga de base** › seleccionar el archivo › **Procesar vista previa** › **Confirmar y guardar**.
3. Todos los usuarios ven la base, las asignaciones y los recuperos actualizados al instante.

## Contraseñas

- El enlace **¿Olvidaste tu contraseña?** envía un correo para restablecerla.
- El correo integrado de Supabase admite pocos envíos por hora; si se usa seguido, configurar un servidor de correo propio en **Authentication › Emails › SMTP Settings**.

## Respaldo

Supabase › **Table Editor › docs** permite exportar los datos a CSV. En el plan gratuito, un proyecto sin uso durante 7 días se pausa y se reactiva desde el panel.
