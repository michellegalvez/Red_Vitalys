---
id: P-03
titulo: Autenticación con Supabase Auth y cierre de sesión
version: 0.1.0
fecha: 2026-11-25
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
specs: [F-13, F-14, F-15, F-18, F-23]
requisitos: [RF-18, RF-32, RF-33, RF-34, RF-35, RF-36, RF-37]
invariantes: [AD-02, AD-03, AD-04, AD-07, AD-14]
tareas: T-03
---

# P-03 · Autenticación con Supabase Auth y cierre de sesión

## Objetivo

Conectar el flujo de autenticación de la aplicación con Supabase Auth (`signInWithPassword` y `signOut`), leyendo el rol y las sedes asignadas desde las tablas `usuario` y `usuario_sede` en PostgreSQL (AD-04). Mantiene el flujo de selección de sede obligatoria (F-13), el bloqueo de 5 intentos fallidos por 15 minutos en el dispositivo (F-14), el cierre automático por 15 minutos de inactividad (F-15), el control de acceso por rol (F-18), y el cierre explícito de sesión (F-23). Garantiza que el evento de auditoría de ingreso se persista exitosamente antes de abrir la sesión (AD-07).

## Enfoque técnico

- **Repositorio de autenticación con doble implementación (AD-02, AD-03):** Se crea una interfaz `AuthRepositorio` con métodos `iniciarSesion`, `obtenerUsuarioActual`, `obtenerSedesAsignadas`, `cerrarSesion`, `estaSesionIniciada`. La implementación en memoria (`AuthMemoria`) atiende pruebas y entorno simulado sin conexión, mientras que `AuthSupabase` interactúa con `supabase.auth` y consulta las tablas `usuario`, `rol` y `usuario_sede` con PostgREST.
- **Selección de repositorio en `fuente_de_datos.dart`:** Si Supabase está listo (`cliente != null`), se provee `AuthSupabase`; en caso contrario se recurre a `AuthMemoria`.
- **Eliminación de la sesión puente:** Se remueve `lib/repositorios/sesion_supabase.dart`, ya que la sesión en Supabase ahora es gobernada directamente por el repositorio de autenticación real.
- **Garantía de auditoría previa (AD-07):** Antes de completar el ingreso del usuario (`_confirmarSede`), se realiza `await auditoria.agregar(...)`. Si la persistencia del evento de auditoría falla, la sesión no se abre, se revierte la sesión autenticada y se muestra el mensaje de error con opción de reintento.
- **Aprovisionamiento automático en la base:** Trigger idempotente en `supabase/migraciones/004_auth_registro_usuario.sql` que al insertar un nuevo usuario en `auth.users` registra su entrada en `public.usuario` con rol `medico` por defecto y sin sedes, activando el flujo alterno F-13 A3 si no cuenta con sedes en `usuario_sede`.
- **El estado vive en la Screen:** `AppScreen` preserva el estado global de sesión, usuario activo, sede elegida, temporizador de inactividad y banderas de carga/error (`<<Cargando...>>` / `Reintentar`).

Alternativas descartadas:

| Alternativa | Por qué no |
|---|---|
| Guardar roles y sedes en los metadatos de Supabase Auth (`app_metadata`) | Viola la invariante AD-04 (roles y sedes deben residir en la base relacional, no en tokens Auth) |
| Abrir la sesión antes de confirmar el guardado en auditoría | Viola la invariante AD-07 y la spec F-13 paso 5 |
| Dejar `SesionSupabase` como puente secundario | Deja código muerto y doble llamado asíncrono descoordinado |

## Componentes

| Pieza | Ruta | Responsabilidad | |
|---|---|---|---|
| Trigger de usuario nuevo | `supabase/migraciones/004_auth_registro_usuario.sql` | Trigger `after insert` en `auth.users` hacia `public.usuario` y RLS | nuevo |
| Interfaz Auth | `lib/repositorios/auth_repositorio.dart` | Contrato de operaciones de autenticación y carga de perfil | nuevo |
| Auth en memoria | `lib/repositorios/auth_memoria.dart` | Implementación basada en datos simulados | nuevo |
| Auth en Supabase | `lib/repositorios/auth_supabase.dart` | Implementación con `GoTrueClient` y PostgREST | nuevo |
| Sesión puente | `lib/repositorios/sesion_supabase.dart` | Eliminación del puente temporal | borrado |
| Fuente de datos | `lib/datos/fuente_de_datos.dart` | Instanciación del repositorio Auth según configuración | cambia |
| Screen anfitriona | `lib/screens/app_screen.dart` | Flujo de login, sede, inactividad, auditoría y cierre | cambia |
| Configuración de arranque | `lib/main.dart` | Paso de `authRepositorio` a `AppScreen` | cambia |
| Pruebas | `test/auth_repositorio_test.dart` | Pruebas unitarias de repositorio, mapeo de roles y fallos | nuevo |

## Cambios

**Se agrega:** `AuthRepositorio`, `AuthMemoria`, `AuthSupabase`, migración `004_auth_registro_usuario.sql` y pruebas de autenticación.

**Se modifica:** `lib/datos/fuente_de_datos.dart`, `lib/screens/app_screen.dart`, `lib/main.dart` y documentación técnica (`README.md`, `prd.md`, `requisitos.md`, `architectural_spine.md`).

**Se elimina:** `lib/repositorios/sesion_supabase.dart`.

## Riesgos y decisiones abiertas

- **Latencia de red en inicio de sesión:** Al involucrar autenticación + consulta relacional de sedes + inserción de auditoría, se provee feedback visual continuo (`<<Cargando...>>` / estado ingresando) para evitar múltiples envíos.
- **Manejo de cuentas sin sedes:** El sistema reconoce explícitamente cuentas creadas sin sedes (F-13 A3), generando el evento denegado y evitando bloqueos indeseados en el dispositivo.

## Verificación

- `flutter analyze` y `flutter test` pasan sin advertencias.
- Migración idempotente aplicable en Supabase SQL Editor.
- Inicio de sesión con credenciales correctas consulta `usuario_sede` y muestra la lista de sedes asignadas (F-13).
- 5 intentos fallidos consecutivos bloquean el acceso en el cliente por 15 minutos (F-14).
- 15 minutos de inactividad cierran la sesión y retornan a la pantalla de acceso con mensaje informativo (F-15).
- Auditoría previa comprobada: si la auditoría falla, la sesión no se completa (AD-07).
- `dart format lib test` y `bash docs/verificar.sh` pasan sin fallas.

## Historial

- 0.1.0 · 2026-11-25 · Primera versión del plan de autenticación con Supabase Auth.
