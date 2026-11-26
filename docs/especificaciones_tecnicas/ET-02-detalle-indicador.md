---
documento: especificacion_tecnica
id: ET-02
titulo: Detalle del indicador
version: 0.1.0
fecha: 2026-11-26
estado: borrador
basado_en: [F-09 0.1.3, F-10 0.1.3, F-11 0.1.1, AD-02, AD-03, AD-11]
---

# ET-02 · Detalle del indicador

## Alcance

Especifica `DetalleIndicadorPage`: tendencia mensual, comparación entre sedes y mediciones recientes del indicador elegido. La misma página se reutiliza para cualquier `IdIndicador`; el detalle de reingreso es una instancia de esa página, no una implementación paralela.

El detalle no tiene un servicio ni una consulta a la base propios. Recibe del estado anfitrión la misma lista `List<Medicion>` cargada para el tablero y recalcula sus proyecciones con funciones puras.

## Componentes y responsabilidades

| Componente | Responsabilidad |
|---|---|
| `lib/screens/app_screen.dart` | Mantiene `_indicadorAbierto`, `_sedeTendencia` y `_mediciones` en el estado de la sesión. |
| `lib/screens/app_screen_paginas.dart::_detalleIndicador` | Resuelve metadatos, filtra sedes aplicables y deriva tendencia, comparación y filas recientes. |
| `lib/reglas/indicadores.dart` | Implementa `tendenciaDe`, `comparacionDe`, `valorRed` y `medicionesRecientes`; no accede a Flutter ni a la base. |
| `lib/pages/indicadores_page.dart::DetalleIndicadorPage` | Presenta los datos y emite `onElegirSede` y `onVolver`. |
| `lib/widgets/indicadores/grafica_tendencia.dart` | Dibuja la tendencia recibida por la página. |
| `lib/widgets/indicadores/barras_por_sede.dart` | Dibuja la comparación recibida por la página. |
| `lib/widgets/indicadores/tabla_mediciones.dart` | Presenta las mediciones recientes recibidas por la página. |
| `lib/widgets/carga.dart` | Presenta carga, error y reintento para cada sección del detalle. |

## Contratos de datos

`DetalleIndicadorPage` recibe:

- `Indicador`, `sedesDisponibles` y `sedeTendencia` (nulo significa toda la red).
- `List<PuntoTendencia>`, `List<FilaSede>`, el promedio del periodo más reciente y `List<FilaMedicion>`.
- `cargando`, `hayError`, `onReintentar`, `onElegirSede` y `onVolver`.

Los tipos de salida viven en `lib/modelos/indicadores.dart`. La página no modifica `Medicion` ni las listas recibidas.

## Flujo de datos

```mermaid
sequenceDiagram
  participant U as Usuario
  participant P as IndicadoresPage
  participant S as AppScreen
  participant R as reglas/indicadores.dart
  participant D as DetalleIndicadorPage
  U->>P: Selecciona un indicador
  P->>S: onAbrirDetalle(id)
  S->>S: Guarda id y limpia sede elegida
  S->>R: tendenciaDe, comparacionDe, valorRed, medicionesRecientes
  R-->>S: Proyecciones del indicador
  S->>D: Indicador + datos + callbacks
  U->>D: Elige una sede
  D->>S: onElegirSede(sedeId)
  S->>S: setState(_sedeTendencia)
  S->>R: Recalcula tendencia para esa sede
  R-->>D: Se actualiza la tendencia; no se consulta la base
```

Al abrir el detalle, `_sedeTendencia` se inicializa a `null`, por lo que la tendencia corresponde a toda la red. Al cambiar el selector, solo cambia ese estado y se recalcula `tendenciaDe`; no hay una nueva petición a Supabase. *Volver* limpia el indicador abierto y la sede seleccionada.

## Transformaciones

- `tendenciaDe(...)` construye seis meses cerrados, del más antiguo al más reciente. Con `sedeId == null` calcula el promedio de red por mes; con sede, toma la medición de esa sede. Los meses sin dato conservan valor nulo.
- `comparacionDe(...)` usa el último periodo cerrado y devuelve sedes aplicables, su valor y su marca. Ordena de peor a mejor según la dirección del indicador; las sedes sin medición quedan al final.
- `valorRed(...)` calcula el promedio simple del último periodo cerrado para la referencia de red.
- `medicionesRecientes(...)` devuelve las mediciones de los seis meses cerrados, de la más reciente a la más antigua y, dentro del periodo, por nombre de sede. Cada marca compara contra el promedio de red de ese mismo periodo.
- `indicadorDe(...)` y `aplica(...)` usan el catálogo estático de `lib/reglas/indicadores.dart`. El filtro de sedes no consulta `indicador_tipo_sede`.

Las funciones reciben `_datos.hoy`; en el estado actual esa fecha es el valor fijo simulado del 6 de noviembre de 2026. La tendencia, comparación y lista reciente se mantienen sincronizadas porque parten de `_mediciones` y de las mismas reglas compartidas.

## Fuente de datos y estados

`IndicatorSupabase.listMeasurements()` es el único lector remoto. Devuelve las mediciones necesarias para F-08 a F-11 en una sola carga; el detalle filtra en memoria. Al registrar una medición exitosamente, el anfitrión la agrega a `_mediciones`, de modo que las proyecciones del tablero y el detalle se actualizan en la sesión.

El estado de carga/error es compartido por las tres secciones del detalle:

| Condición | Mensaje |
|---|---|
| Cargando tendencia | “Cargando tendencia…” |
| Error de lectura en la tendencia | “No se pudo cargar la tendencia” |
| Cargando comparación | “Cargando comparación…” |
| Error de lectura en la comparación | “No se pudo cargar la comparación” |
| Cargando mediciones recientes | “Cargando mediciones…” |
| Error de lectura de mediciones | “No se pudieron cargar las mediciones” |

Cada *Reintentar* vuelve a cargar la lista completa, no una sección aislada. Los estados de vacío se calculan con la lista cargada: tendencia sin valores, comparación sin mediciones en el periodo y lista reciente sin filas.

## Persistencia y seguridad

El detalle es de solo lectura y no escribe en la base. En Supabase, las filas provienen de `medicion_indicador`, con sus relaciones a `indicador` y `sede`; RLS permite su lectura a usuarios autenticados con rol reconocido. Los nombres de sede se resuelven contra el conjunto local compartido. Los datos se mantienen en el estado de `AppScreen` mientras dura la sesión de la app.

Las credenciales se obtienen de `Entorno`; se usa la publishable key junto con Auth y las políticas RLS. El detalle no contiene ni transmite datos de pacientes.

## Límites y dependencias

- El catálogo y el tipo de sede aplicable se derivan de `lib/reglas/indicadores.dart` y `DatosSimulados`; la tabla `indicador_tipo_sede` de Supabase no es consultada actualmente.
- La fecha de referencia es fija por `DatosSimulados.hoy`. Para que los periodos remotos avancen después del cambio de mes, se deberá inyectar una fecha de operación real o configurable.
- Si Supabase no está configurado, el mismo detalle usa las mediciones simuladas. La conexión remota efectiva requiere las migraciones previas y `009_indicadores.sql`.
- No se usa Realtime ni paginación; las actualizaciones de una medición nueva se reflejan mediante el estado local tras el guardado.
- La persistencia del evento de auditoría de una nueva medición no forma parte del detalle. En el código actual ese evento se añade al estado local; la integración con una auditoría remota debe tratarse aparte para cumplir AD-07.

## Trazabilidad de validación

- Reglas compartidas: `test/indicadores_test.dart`, `test/indicadores_specs_test.dart`.
- Carga y reintento del servicio: `test/indicadores_servicio_test.dart`.
- Specs funcionales: `docs/specs/F-09-tendencia-indicador.md`, `docs/specs/F-10-comparacion-sedes.md` y `docs/specs/F-11-mediciones-recientes.md`.

## Historial

- 0.1.0 · 2026-11-26 · Primera versión técnica basada en el detalle y su integración actual.
