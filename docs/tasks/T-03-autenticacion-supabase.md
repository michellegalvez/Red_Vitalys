---
id: T-03
titulo: Tareas de autenticación con Supabase Auth
version: 0.1.0
fecha: 2026-11-25
plan: P-03
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
---

# T-03 · Autenticación con Supabase Auth

Plan: [P-03](../plans/P-03-autenticacion-supabase.md)

## Tareas

- [x] **T-03.1** · Crear la migración SQL idempotente para el trigger de usuario nuevo en `public.usuario` desde `auth.users`, con RLS y asignación de rol inicial `medico` sin sedes.
  - Toca: `supabase/migraciones/004_auth_registro_usuario.sql`
  - Se comprueba: ejecución idempotente sin errores en PostgreSQL y presencia de función/trigger.

- [x] **T-03.2** · Definir la interfaz `AuthRepositorio` y su implementación en memoria `AuthMemoria`.
  - Toca: `lib/repositorios/auth_repositorio.dart`, `lib/repositorios/auth_memoria.dart`, `test/auth_repositorio_test.dart`
  - Se comprueba: `flutter test test/auth_repositorio_test.dart` pasa validando login exitoso, credenciales erróneas y carga de sedes.

- [x] **T-03.3** · Crear la implementación `AuthSupabase` usando `supabase_flutter` y consultas PostgREST a `usuario` y `usuario_sede`.
  - Toca: `lib/repositorios/auth_supabase.dart`, `test/auth_repositorio_test.dart`
  - Se comprueba: `flutter analyze` sin advertencias y pruebas unitarias de mapeo cubiertas.

- [x] **T-03.4** · Exponer `AuthRepositorio` en `fuente_de_datos.dart` e inyectarlo en `main.dart`.
  - Toca: `lib/datos/fuente_de_datos.dart`, `lib/main.dart`
  - Se comprueba: la app compila y selecciona `AuthSupabase` si hay cliente o `AuthMemoria` en modo local.

- [x] **T-03.5** · Conectar `AppScreen` con `AuthRepositorio`, retirando `SesionSupabase` y sus llamadas.
  - Toca: `lib/screens/app_screen.dart`, `lib/repositorios/sesion_supabase.dart` (eliminar)
  - Se comprueba: `SesionSupabase` eliminado; el login y logout operan contra `AuthRepositorio`.

- [x] **T-03.6** · Asegurar invariante AD-07 en el flujo de ingreso: registrar y esperar auditoría antes de habilitar la sesión en `AppScreen`.
  - Toca: `lib/screens/app_screen.dart`
  - Se comprueba: si `auditoria.agregar` arroja excepción, la sesión se aborta y se muestra estado de error reintentable.

- [x] **T-03.7** · Validar las reglas de bloqueo por 5 intentos (F-14), inactividad de 15 minutos (F-15) y control de acceso por rol (F-18).
  - Toca: `test/app_screen_test.dart` o pruebas de integración relacionadas
  - Se comprueba: pruebas de inactividad, bloqueo temporal y cierre de sesión pasando en verde.

- [x] **T-03.8** · Actualizar documentos arquitectónicos y de producto (PRD, Requisitos, Architectural Spine, README).
  - Toca: `docs/prd.md`, `docs/requisitos.md`, `docs/architectural_spine.md`, `README.md`
  - Se comprueba: `bash docs/verificar.sh` pasa sin errores; `README.md` documenta la ejecución con `env.json` sin secretos expuestos.

- [x] **T-03.9** · Verificación final y limpieza de código.
  - Toca: todo el proyecto
  - Se comprueba: `dart format lib test` sin cambios, `flutter analyze` limpio, `flutter test` en verde y `bash docs/verificar.sh` exitoso.
