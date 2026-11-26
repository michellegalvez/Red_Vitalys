---
id: P-04
titulo: Pasar a Supabase lo que sigue en memoria
version: 0.1.0
fecha: 2026-11-26
estado: en curso
autores: [Juan Diego Valverde Fierro]
specs: [F-01, F-02, F-03, F-04, F-07, F-08, F-09, F-10, F-11, F-12, F-20, F-21]
requisitos: []
invariantes: [AD-02, AD-03, AD-06, AD-07, AD-08, AD-10, AD-11]
tareas: T-18 a T-24 en docs/impl_progress.md
---

# P-04 · Pasar a Supabase lo que sigue en memoria

## Objetivo

Que la historia clínica, el riesgo, el registro de atenciones, los indicadores y las mediciones salgan de Supabase y se guarden ahí, y que la auditoría guarde el paciente de cada evento. No cambia lo que se ve ni las reglas de negocio.

## Enfoque técnico

Cada pieza sigue el patrón que ya usan el inicio de sesión y los pacientes: una interfaz, una versión en memoria y otra de Supabase, elegidas en `lib/datos/fuente_de_datos.dart` (AD-02, AD-03). La Screen anfitriona guarda el estado, con carga, error y *Reintentar*. Las tablas, los permisos y los datos de prueba van en scripts nuevos de `supabase/migraciones/`, con las fechas fijas de los datos simulados.

## Orden

| Tarea | Qué queda funcionando | Specs | Script |
|---|---|---|---|
| T-18 | La auditoría guarda y muestra el paciente de cada evento | F-20, F-21 | 006 |
| T-19 | Datos de la historia en la base: contacto, identificadores por sistema y atenciones anteriores | F-02, F-03 | 007 |
| T-20 | La historia, el riesgo y sus factores se leen de la base, con carga y error | F-02, F-03, F-07 | — |
| T-21 | Registrar una atención la guarda en la base y da la relación | F-04, F-05 | 008 |
| T-22 | Tablas de indicadores con sus mediciones de prueba | F-08 | 009 |
| T-23 | El tablero y el detalle leen las mediciones de la base, con carga y error | F-08, F-09, F-10, F-11 | — |
| T-24 | Registrar una medición la guarda en la base, sin repetirla | F-12 | 009 |

La búsqueda de pacientes (F-01) ya lee de la base desde T-13. El acceso, la foto y la auditoría ya estaban conectados.

## Cambios

**Se agrega:** servicios de historia e indicadores, y los scripts 006 a 009.

**Se modifica:** el repositorio de auditoría, `lib/datos/fuente_de_datos.dart`, `lib/main.dart` y la Screen anfitriona.

**No se toca:** las specs funcionales, el PRD, los requisitos ni la spine.

## Riesgos y decisiones abiertas

- **Rama de Gabriela (`feat/auth-gabriela`):** resuelve el inicio de sesión que también resuelve esta rama (F-13, F-14, F-15, F-18, F-23). Un merge de prueba da conflictos en `AGENTS.md`, `lib/main.dart` y `lib/screens/app_screen.dart`. Falta decidir con el equipo cuál queda.
- **Numeración:** su `004_auth_registro_usuario.sql` repite el número de `004_pacientes_y_riesgo.sql`, y su archivo de tareas usa `T-03`, como `docs/impl_progress.md`.
- **Registro público:** en Supabase está habilitado y el disparador de ese script 004 crea como médico a toda cuenta nueva. El script 005 impide que una cuenta sin sedes lea pacientes, pero conviene deshabilitar el registro en el panel.

## Verificación

- `flutter analyze` y `flutter test` pasan, y `bash docs/verificar.sh` queda sin fallas.
- Cada tarea se comprueba contra el proyecto `red-vitalys` con cada rol.

## Historial

- 0.1.0 · 2026-11-26 · Primera versión.
