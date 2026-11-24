---
id: P-01
titulo: Auditoría de accesos guardada en Supabase
version: 0.1.0
fecha: 2026-11-23
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
specs: [F-20, F-21]
requisitos: [RF-14, RF-15, RF-16, RF-17, RF-31]
invariantes: [AD-02, AD-03, AD-07, AD-08, AD-15]
tareas: T-01
---

# P-01 · Auditoría de accesos guardada en Supabase

## Objetivo

Que los eventos de acceso se guarden en la tabla `evento_auditoria` de Supabase, que nadie pueda editarlos ni borrarlos, y que la pantalla del auditor los lea de ahí. Al cerrar y abrir la app, los eventos siguen.

Deja además un único punto, `AuditoriaRepositorio.agregar`, que el resto del equipo llama cuando pase sus acciones a Supabase.

## Enfoque técnico

- **Un repositorio con dos implementaciones (AD-02, AD-03).** Una interfaz `AuditoriaRepositorio` con `agregar(evento)` y `listar()`. La implementación en memoria envuelve la lista de hoy y sirve para las pruebas; la de Supabase usa `supabase_flutter`. La elección se hace en `fuente_de_datos.dart`.
- **Solo agregar, en la base (AD-08).** La regla vive en Postgres (`supabase/migraciones/001_base_y_auditoria.sql`): un trigger rechaza `update` y `delete`, se quitan esos permisos y las políticas de RLS solo permiten `insert` y `select`. La interfaz del repositorio tampoco ofrece editar ni borrar.
- **Quién lee y quién escribe.** Escribe cualquier usuario con sesión, solo con su propio id. Un inicio de sesión fallido se escribe sin sesión y sin usuario. Lee solo el auditor.
- **La IP la pone la base (AD-15).** La app no manda la IP; la base la lee de la cabecera de la petición.
- **Escribir antes de actuar (AD-07).** `agregar` devuelve un `Future` que falla si no se pudo guardar. El inicio de sesión espera ese resultado y, si falla, no abre la sesión (F-13 paso 5).
- **Sesión puente.** La política de seguridad exige una sesión de Supabase. Mientras Gabriela no conecte el inicio de sesión con Auth (F-13), la app entra con los usuarios simulados y además inicia sesión en Supabase con el mismo correo y contraseña, solo para tener sesión. Es temporal y se borra cuando F-13 use Auth de verdad.
- **Los ids de la base no son los simulados.** La app usa `u1` y `s1`; la base usa uuid y números. El repositorio traduce al guardar y al leer: el usuario sale de la sesión, y la sede se busca por su nombre en la tabla `sede`.

Alternativas descartadas:

| Alternativa | Por qué no |
|---|---|
| Dejar la lista en memoria y subirla a Supabase de vez en cuando | La memoria seguiría siendo la fuente; lo prohíbe el enunciado y se perdería al cerrar la app |
| Políticas abiertas, sin sesión, hasta que llegue Auth | Cualquiera podría leer la auditoría. Quedaría peor que la spine, que solo acepta ese riesgo para los inicios de sesión fallidos |
| Volver `_registrarEvento` asíncrono en los 11 puntos donde se usa | Toca código de los demás (atenciones, mediciones, pacientes). Cada quien lo cambia al pasar su acción a Supabase |

## Componentes

| Pieza | Ruta | Responsabilidad | |
|---|---|---|---|
| Tablas y reglas | `supabase/migraciones/001_base_y_auditoria.sql` | Tablas, trigger de solo agregar, RLS y datos de sedes | nuevo (hecho) |
| Usuarios de prueba | `supabase/migraciones/002_usuarios_de_prueba.sql` | Carga los 4 usuarios con sus sedes | nuevo (hecho) |
| Interfaz | `lib/repositorios/auditoria_repositorio.dart` | `agregar` y `listar`; sin editar ni borrar | nuevo |
| En memoria | `lib/repositorios/auditoria_memoria.dart` | La lista de hoy, para pruebas | nuevo |
| Supabase | `lib/repositorios/auditoria_supabase.dart` | Guarda y lee; traduce ids, acciones y recursos | nuevo |
| Sesión puente | `lib/repositorios/sesion_supabase.dart` | Inicia y cierra la sesión de Supabase junto al inicio simulado | nuevo (temporal) |
| Fuente | `lib/datos/fuente_de_datos.dart` | Elige el repositorio de auditoría | cambia |
| Screen | `lib/screens/app_screen.dart` | Escribe el ingreso por el repositorio y carga los eventos | cambia |
| Page | `lib/pages/auditoria_page.dart` | Estados de carga y de error con *Reintentar* | cambia |
| Pruebas | `test/auditoria_repositorio_test.dart` | Traducción de ids y enums; el repositorio en memoria | nuevo |

## Cambios

**Se agrega:** el repositorio (interfaz y dos implementaciones), la sesión puente y sus pruebas.

**Se modifica:** el inicio de sesión (escribe el evento de ingreso por el repositorio y espera el resultado), la carga de eventos de la Screen y la Page de auditoría (cargando y error).

**No se toca:** las acciones de pacientes, atenciones, mediciones e indicadores. Siguen llamando a `_registrarEvento`, que además de la lista guarda el evento en la base sin esperarlo. Cuando cada quien pase su acción a Supabase, cambia esa llamada por `await auditoria.agregar(...)` antes de ejecutar la acción.

## Riesgos y decisiones abiertas

- **Eventos guardados después de actuar.** Hasta que cada quien migre su acción, esas acciones guardan el evento sin esperarlo, así que AD-07 solo se cumple del todo en el inicio de sesión. Queda anotado para el resto del equipo.
- **El paciente de un evento.** La tabla `paciente` es de otra persona y todavía no existe. Hasta entonces `id_paciente` queda vacío en los eventos que lo llevan, y la pantalla del auditor muestra el paciente como no disponible. Se completa cuando exista `paciente`.
- **Los ids simulados de usuarios y de pacientes** no son los de la base. Para los usuarios se resuelve con el correo; para los pacientes, con la tabla `paciente` cuando exista.
- **Sesión puente en choque con F-13.** Gabriela cambia el inicio de sesión por Auth. La sesión puente vive en un solo archivo para que su retiro sea borrarlo y quitar una llamada.
- **Registro abierto de inicios fallidos** (spine, *Diferido*): se acepta con datos simulados y se cierra antes de usar datos reales.

## Verificación

- `flutter analyze` y `flutter test` pasan.
- Un ingreso exitoso y uno fallido aparecen como filas en `evento_auditoria` (*Table Editor*), con la IP puesta por la base.
- Entrar como Marcela (auditora) muestra esos eventos en la pantalla de auditoría; cerrar la app y volver a abrirla los conserva.
- Un `update` y un `delete` sobre `evento_auditoria` fallan con el mensaje del trigger, también desde el SQL Editor.
- Un médico no puede leer `evento_auditoria`.
- F-20: cada intento queda registrado, el ingreso antes de abrir la sesión; si no se puede guardar, la sesión no se abre.
- F-21: la lista del auditor trae los eventos de la base y los filtros *Denegados* y *Emergencia* funcionan igual; hay estado de carga y de error con *Reintentar*.

## Historial

- 0.1.0 · 2026-11-23 · Primera versión.
