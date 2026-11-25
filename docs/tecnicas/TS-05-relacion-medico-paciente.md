---
id: TS-05
titulo: Relación médico-paciente
version: 0.1.0
fecha: 2026-11-24
estado: borrador
funcional: F-05 0.2.6
---

# TS-05 · Relación médico-paciente

## Resumen

El servicio de control de acceso decide si el médico tiene relación con el paciente: una atención suya con *Atención del paciente*, o un alta de los últimos 30 días en una de sus sedes. Los datos salen de la base por el servicio de pacientes. Una atención con *Urgencia* no da relación, ni por la atención ni por el alta que lleve.

## Preparación en Supabase

- La misma de TS-06: las tablas `paciente` y `atencion`, con `atencion.id_usuario` (el médico) y `atencion.proposito`, y datos de prueba que cubran los casos de los criterios (un alta de hace 10 días en Cali Norte, uno de hace 5 días en otra sede, uno de hace 40 días y uno con una atención de la Dra. Camila de hace 2 meses).

## Piezas

- `lib/services/access_control_service.dart` · **cambia** (T-16) · `hasRelationship(Usuario doctor, PacienteEnSeguimiento patient, DateTime today) → bool` y `decideConsultation(...)`. Reutiliza `tieneRelacion` y `evaluarConsulta` de `lib/reglas/reglas.dart`.
- `lib/services/patient_service.dart` · **cambia** (T-16) · cada paciente trae `medicosConAtencion`: los ids de los médicos con una atención suya con propósito *Atención del paciente*.
- `lib/services/patient_supabase.dart` · **cambia** (T-16) · lee `atencion` filtrando por `proposito = atencion_paciente`.
- `lib/screens/app_screen.dart` · **cambia** (T-16) · al abrir una historia o registrar una atención usa la decisión del servicio y, si no hay relación, muestra "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*." con los eventos *Denegado* de la historia y del riesgo.

## Estado

- Ninguno nuevo: la relación se calcula en cada consulta y no se guarda.

## Datos

- `atencion` (`id_paciente`, `id_sede`, `id_usuario`, `fecha_inicio`, `fecha_fin`, `proposito`) y `usuario_sede` para las sedes asignadas al médico.

## Paquetes y plataformas

- Ninguno nuevo.

## Tareas

- **T-16** Relación con datos de la base: tener relación por una atención propia con *Atención del paciente* o por un alta de los últimos 30 días en una sede asignada; *Urgencia* no da relación; una consulta sin relación se rechaza con su mensaje y sus eventos; la búsqueda no exige relación; si no se puede verificar, se ve "No se pudo verificar el acceso" con *Reintentar*. · CA-1, CA-2, CA-3, CA-4, CA-5, CA-6, CA-7, CA-8, CA-9 · depende de: T-11, T-13
  - Prueba: como la Dra. Camila abrir un paciente dado de alta en Cali Norte hace 10 días y ver la historia; uno de otra sede, sin atención suya y con *Atención del paciente*, y ver el rechazo; uno de hace 40 días y ver el rechazo; uno con una atención suya de hace 2 meses y ver la historia; declarar *Urgencia* y ver la historia marcada; registrar una atención con *Urgencia* y después abrir con *Atención del paciente* para ver el rechazo; buscar a un paciente de otra sede y encontrarlo.

## Preguntas abiertas

- ¿Quién valida la relación si alguien llama a Supabase sin pasar por la app? Hoy solo la app; una política en la base podría repetirlo.

## Historial

- 0.1.0 · 2026-11-24 · Primera versión.
