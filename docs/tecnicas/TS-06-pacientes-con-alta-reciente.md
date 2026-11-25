---
id: TS-06
titulo: Pacientes con alta reciente por riesgo de reingreso
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-06 0.3.6
---

# TS-06 · Pacientes con alta reciente por riesgo de reingreso

## Resumen

La lista deja de salir de los datos simulados y la entrega un servicio de pacientes, con una versión en memoria y otra de Supabase (AD-02, AD-03). El servicio trae las altas de los últimos 30 días con su riesgo guardado; la app no calcula el riesgo (AD-10). Abrir la lista pide el propósito y deja un evento.

## Preparación en Supabase

- Un script nuevo, `supabase/migraciones/004_pacientes_y_riesgo.sql`, con las tablas `paciente`, `identificador_paciente`, `atencion`, `prediccion_reingreso` y `factor_riesgo` del modelo (`docs/modelo.md`), sus políticas de acceso por rol y la lectura solo para el médico. Se corre a mano en el *SQL Editor*.
- Datos de prueba (RNF-04): 8 pacientes con alta en los últimos 30 días, 4 con riesgo de 70 o más, y 3 con atenciones en 2 sedes o más. La fecha de «hoy» de los datos es el 6 de noviembre de 2026.

## Piezas

- `lib/services/patient_service.dart` · **nueva** (T-13) · interfaz. `listRecentDischarges(DateTime today) → Future<List<PacienteEnSeguimiento>>`, ordenada por riesgo, luego por alta más reciente y luego por nombre.
- `lib/services/patient_memory.dart` · **nueva** (T-13) · versión en memoria, con `lib/datos/datos_simulados.dart`.
- `lib/services/patient_supabase.dart` · **nueva** (T-13) · versión Supabase; la única clase que consulta las tablas de pacientes.
- `lib/datos/fuente_de_datos.dart` · **cambia** (T-13) · elige entre las dos versiones.
- `lib/screens/app_screen.dart` · **cambia** (T-13, T-14, T-15) · guarda la lista que entrega el servicio. T-14 pide el propósito y crea el evento al abrir la lista. T-15 muestra la carga y el error reales.
- `lib/pages/seguimiento_page.dart` · **cambia** (T-13, T-15) · recibe la lista por el constructor; muestra el contador y el mensaje de vacío; en T-15 el error con *Reintentar*.
- `lib/widgets/carga.dart` · **cambia** (T-15) · en lugar de simular, recibe el estado real del servicio.

## Estado

- Screen anfitriona: la lista de pacientes, si está cargando o falló, y la solicitud de propósito de la lista. La Page solo guarda el texto de búsqueda que se escribe.

## Datos

- `paciente` (`id_paciente`, nombre, `fecha_nacimiento`, `sexo`), `atencion` (`id_sede`, `fecha_inicio`, `fecha_fin`, `id_usuario`, `proposito`), `prediccion_reingreso` (puntaje de 0 a 100, entero) y `sede`.
- Alta de los últimos 30 días, contada desde hoy.

## Paquetes y plataformas

- `supabase_flutter` · ya está. Sin paquetes nuevos.

## Tareas

- **T-13** Servicio de pacientes y lista ordenada: traer las altas de los últimos 30 días de toda la red, con riesgo, fecha y sede, ordenadas y con la alerta de 70 o más. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-10, CA-11, CA-14 · depende de: ninguna
  - Prueba: como la Dra. Camila ver 8 pacientes de mayor a menor riesgo con la alerta en los de 70 o más y el contador "8 pacientes"; ver uno dado de alta en otra sede; con riesgo 69 y 70 ver la alerta solo en el segundo; un alta de 31 días no aparece; sin altas ver el mensaje de vacío; dos pacientes con el mismo riesgo y alta salen por nombre.
- **T-14** Propósito y evento al abrir la lista: pedir el propósito antes de ver pacientes, crear el evento *Consultar* de *Pacientes con alta reciente* sin paciente, y rechazar al administrativo y al auditor con su evento. · CA-9, CA-12, CA-13, CA-15 · depende de: T-04, T-11, T-13
  - Prueba: entrar como médico y ver que pide el propósito sin mostrar pacientes; declarar *Seguimiento de reingreso* y ver el evento en la auditoría; abrir la lista con *Urgencia* y verlo en *Emergencia*; como administrativo no verla y ver el evento *Denegado*.
- **T-15** Carga y error reales de la lista: mostrar "Cargando pacientes…" mientras el servicio responde y "No se pudo cargar la lista" con *Reintentar* si falla. · CA-8 · depende de: T-13
  - Prueba: apagar la red, abrir la lista y ver el error; volver a prender la red y elegir *Reintentar* para ver la lista.

## Preguntas abiertas

- ¿Se permite filtrar la lista por sede o por riesgo? F-06 lo deja fuera de alcance.
- ¿Cuánto se tarda en traer la lista con muchos pacientes? F-06 CA-10 pide menos de 2 segundos con los datos simulados.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
