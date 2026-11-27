---
id: T-04
titulo: Tareas de historia clínica y atenciones en Supabase
version: 0.1.0
fecha: 2026-11-26
plan: P-04
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
---

# T-04 · Historia clínica y atenciones en Supabase

Plan: [P-04](../plans/P-04-historia-atencion-supabase.md)

## Tareas

- [x] **T-04.1** · Crear el script SQL idempotente de pacientes, atenciones, predicción de riesgo, factores y llave foránea de auditoría con políticas RLS de lectura e inserción para médicos.
  - Toca: `supabase/migraciones/004_pacientes_atenciones_riesgo.sql`
  - Se comprueba: script ejecutable sin errores; crea tablas `paciente`, `identificador_paciente`, `atencion`, `prediccion_reingreso`, `factor_riesgo`, activa RLS y contiene políticas de acceso.

- [x] **T-04.2** · Crear la interfaz abstracta `HistoriaRepositorio` y su implementación en memoria `HistoriaMemoria`.
  - Toca: `lib/repositorios/historia_repositorio.dart`, `lib/repositorios/historia_memoria.dart`
  - Se comprueba: `HistoriaMemoria` consulta historias unificadas y agrega atenciones recalculando el riesgo de forma determinista.

- [x] **T-04.3** · Crear la implementación `HistoriaSupabase` con consultas PostgREST relacionales y mapeo a modelos de dominio (`Patient`, `Encounter`, `ReadmissionRisk`, `RiskFactor`).
  - Toca: `lib/repositorios/historia_supabase.dart`
  - Se comprueba: mapea correctamente registros relacionales a los modelos de dominio y redondea contribuciones a enteros.

- [x] **T-04.4** · Agregar el selector `elegirHistoria` en `fuente_de_datos.dart` manteniendo el desacoplamiento de la fuente de datos (AD-02).
  - Toca: `lib/datos/fuente_de_datos.dart`
  - Se comprueba: devuelve `HistoriaSupabase` cuando `cliente != null` e `HistoriaMemoria` en su defecto.

- [x] **T-04.5** · Conectar `AppScreen` con el repositorio de historia, soportando estado de carga asíncrona, estado de error con *Reintentar* y auditoría obligatoria previa (AD-07).
  - Toca: `lib/screens/app_screen.dart`, `lib/screens/app_screen_paginas.dart`
  - Se comprueba: al seleccionar un paciente se verifica la auditoría antes de consultar; si la auditoría falla no se muestra la historia; si la consulta falla se muestra "No se pudo cargar la historia" y el botón *Reintentar*.

- [x] **T-04.6** · Conectar el guardado de atenciones con el repositorio y auditoría previa (AD-07), conservando los datos del formulario si falla.
  - Toca: `lib/screens/app_screen_guardado.dart`, `lib/pages/registrar_atencion_page.dart`
  - Se comprueba: al registrar atención se registra primero el evento de auditoría; si el guardado falla, la atención no se persiste y el formulario mantiene lo digitado (F-04 CA-6).

- [x] **T-04.7** · Crear pruebas unitarias y de integración para `HistoriaRepositorio`, estados de UI y auditoría previa AD-07.
  - Toca: `test/historia_repositorio_test.dart`
  - Se comprueba: `flutter test test/historia_repositorio_test.dart` pasa al 100%.

- [x] **T-04.8** · Verificación integral de la entrega y calidad de código.
  - Toca: `docs/modelo.md`, `docs/plans/README.md`, `docs/tasks/README.md`
  - Se comprueba: `dart format lib test` sin cambios, `flutter analyze` limpio, `flutter test` con 100% de éxito y `bash docs/verificar.sh` en OK.
