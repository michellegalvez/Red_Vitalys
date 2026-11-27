---
id: P-04
titulo: Historia clínica y registro de atenciones en Supabase
version: 0.1.0
fecha: 2026-11-26
estado: hecho
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
specs: [F-02, F-04, F-07]
requisitos: [RF-02, RF-04, RF-19, RF-25]
invariantes: [AD-01, AD-02, AD-07, AD-08, AD-09, AD-10]
tareas: T-04
---

# P-04 · Historia clínica y registro de atenciones en Supabase

## Objetivo

Consultar la historia clínica unificada de un paciente (datos personales, identificadores por sistema de origen, atenciones y riesgo de reingreso a 30 días con sus factores explicativos) desde Supabase, y permitir el registro persistente de nuevas atenciones médicas con recálculo de riesgo, garantizando la auditoría previa obligatoria (AD-07) y el manejo de estados de carga y error con reintento.

## Enfoque técnico

- **Repositorio con doble implementación (AD-02, AD-03):** Se define la interfaz `HistoriaRepositorio` con métodos para consultar la historia (`obtenerHistoria`) y registrar una atención (`registrarAtencion`). Se implementa `HistoriaMemoria` para pruebas y modo desconectado, e `HistoriaSupabase` conectada a PostgREST.
- **Esquema de base de datos idempotente (AD-09, AD-10):** Se crean las tablas `paciente`, `identificador_paciente`, `atencion`, `prediccion_reingreso` y `factor_riesgo` respetando el MER. Además se añade la restricción de llave foránea hacia `paciente` en `evento_auditoria`.
- **Seguridad y RLS:**
  - Lectura permitida a usuarios autenticados para visualizar la historia clínica unificada en la red.
  - Inserción en `atencion` restringida a médicos autenticados (`id_usuario = auth.uid()`).
  - Trigger o inserción automática de predicción de riesgo y factores asociados al registrar una atención para reflejar el impacto en el riesgo de reingreso.
- **Auditoría obligatoria previa (AD-07):** Toda consulta de historia clínica y todo intento de registro de atención exige el registro y confirmación previa del evento de auditoría en `AuditoriaRepositorio`. Si la auditoría falla, la consulta o inserción se aborta inmediatamente.
- **Resiliencia en UI:** En `AppScreen`, `PacientePage` y `RegistrarAtencionPage` se integran estados de carga explícitos (`Cargando historia…`, `Guardando atención…`), vista de error con botón *Reintentar* y preservación de los datos ingresados en el formulario en caso de fallo en el guardado.

## Componentes

| Pieza | Ruta | Responsabilidad | |
|---|---|---|---|
| Esquema y RLS | `supabase/migraciones/004_pacientes_atenciones_riesgo.sql` | Tablas de pacientes, atenciones, riesgo, FK de auditoría y políticas RLS | nuevo |
| Interfaz | `lib/repositorios/historia_repositorio.dart` | Contrato de consulta y registro de atenciones | nuevo |
| En memoria | `lib/repositorios/historia_memoria.dart` | Implementación en memoria para pruebas y modo simulado | nuevo |
| Supabase | `lib/repositorios/historia_supabase.dart` | Implementación con cliente Supabase (PostgREST) | nuevo |
| Fuente de datos | `lib/datos/fuente_de_datos.dart` | Selector `elegirHistoria` | cambia |
| Pantallas y estado | `lib/screens/app_screen.dart` | Carga asíncrona, reintento, auditoría previa obligatoria | cambia |
| Páginas | `lib/screens/app_screen_paginas.dart` / `app_screen_guardado.dart` | Orquestación de guardado asíncrono y mensajes de error | cambia |
| Pruebas | `test/historia_repositorio_test.dart` | Pruebas de traducción, repositorios, auditoría AD-07 y resiliencia | nuevo |

## Cambios

- **Se agrega:** Migración `004_pacientes_atenciones_riesgo.sql`, `HistoriaRepositorio`, `HistoriaMemoria`, `HistoriaSupabase`, pruebas en `test/historia_repositorio_test.dart`.
- **Se modifica:** `lib/datos/fuente_de_datos.dart` con `elegirHistoria`, `AppScreen` para gestionar la carga de la historia y el guardado asíncrono con auditoría previa `AD-07`, `app_screen_guardado.dart` y `app_screen_paginas.dart`.
- **No se toca:** El módulo de indicadores ni el módulo de administración/auditoría.

## Riesgos y decisiones abiertas

- **Conversión de factores de riesgo:** Postgres almacena `contribucion` en `numeric(8,4)` mientras que el dominio de la app maneja enteros (`int`). El repositorio realiza el redondeo matemático garantizando la consistencia de `basePoints`.
- **Documento principal:** Se utiliza `es_principal = true` en `identificador_paciente` para identificar el documento visible por defecto.

## Verificación

- `dart format lib test` sin cambios.
- `flutter analyze` sin advertencias ni errores.
- `flutter test` pasa todas las pruebas unitarias y de integración.
- `bash docs/verificar.sh` pasa sin fallas.
- Criterios de aceptación de F-02, F-04 y F-07 cubiertos.

## Historial

- 0.1.0 · 2026-11-26 · Primera versión del plan.
