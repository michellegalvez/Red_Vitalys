---
id: F-05
titulo: Relación médico-paciente
version: 0.2.6
fecha: 2026-11-08
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-24, RF-25]
depende_de: [F-16, F-18]
---

# F-05 · Relación médico-paciente

## Objetivo

El médico puede consultar pacientes de cualquier sede de la red, pero solo ve la historia y registra atenciones de aquellos con los que tiene relación. Con los demás tiene que declarar *Urgencia*, y ese acceso queda marcado para el auditor (O-01, O-05).

## Flujo principal

1. El médico elige un paciente de cualquier sede y declara el propósito de la consulta (F-16).
2. El sistema revisa si el médico tiene relación con el paciente.
3. Si la tiene, el sistema crea el evento *Permitido* y, si pudo crearlo, permite ver la historia clínica y el riesgo de reingreso con cualquier propósito de los 5 que su rol permite. Son dos eventos, el de la historia y el del riesgo (F-02).

## Flujos alternos

- **A1 · Sin relación y sin *Urgencia*:** el sistema rechaza la consulta, no muestra la historia ni el riesgo, y crea los eventos *Denegado* de la historia y del riesgo con el propósito declarado. El médico ve "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*." (F-18).
- **A2 · Sin relación con *Urgencia*:** el acceso se permite y queda marcado como emergencia (F-17).
- **A3 · Relación nueva:** cuando el médico registra una atención del paciente declarando *Atención del paciente* (F-04), desde ese momento tiene relación. Si la registra con *Urgencia*, no la tiene.

## Reglas

- El médico tiene relación con un paciente si se cumple una de estas dos condiciones:
  - Registró al menos una atención suya declarando *Atención del paciente*.
  - El paciente fue dado de alta en los últimos 30 días en una de las sedes asignadas al médico.
- Una atención registrada con *Urgencia* no da relación, ni por la atención ni por el alta que ella lleve en una sede del médico. Así un acceso de emergencia no se vuelve permanente.
- La relación se evalúa en cada consulta.
- La relación se exige para ver la historia clínica y el riesgo de reingreso, y para registrar una atención (F-04). No se exige para buscar al paciente ni para que el administrativo vea sus datos básicos (F-03).
- El paciente puede ser de cualquier sede de la red. La sede de la sesión no limita a quién se busca.
- El administrativo y el auditor no tienen relación con ningún paciente, porque no ven historia ni riesgo.
- Los datos son simulados.

## Estados

Esta funcionalidad no tiene pantalla propia. Lo que el médico ve de ella es la historia o el rechazo de la consulta.

- **Cargando:** no aplica. Se ve el estado de la consulta (F-02).
- **Vacío:** no aplica.
- **Error:** si el sistema no puede verificar la relación, se rechaza la consulta y se ve "No se pudo verificar el acceso" con la opción *Reintentar*.

## Datos

- **Médico** y **sedes asignadas** del médico.
- **Atenciones** que el médico registró, con su propósito.
- **Fecha de alta** y **sede del alta** del paciente.
- **Relación:** existe o no existe, para ese médico y ese paciente.

## Criterios de aceptación

- **CA-1** Dado que la Dra. Camila Martínez tiene asignada Clínica Vitalys Cali Norte, cuando abre la historia de un paciente dado de alta en esa sede hace 10 días, declarando *Atención del paciente*, entonces el acceso se permite.
- **CA-2** Dada la Dra. Martínez, cuando abre la historia de un paciente dado de alta hace 5 días en otra sede que no tiene asignada, sin atención suya y declarando *Atención del paciente*, entonces no ve la historia y quedan los eventos *Denegado* de la historia y del riesgo.
- **CA-3** Dado un paciente dado de alta en Cali Norte hace 40 días y sin atención de la Dra. Martínez, cuando ella abre su historia declarando *Atención del paciente*, entonces no la ve y quedan los eventos *Denegado* de la historia y del riesgo.
- **CA-4** Dado un paciente con una atención registrada por la Dra. Martínez en otra sede hace 2 meses declarando *Atención del paciente*, cuando ella abre su historia declarando *Consulta de historia clínica*, entonces el acceso se permite.
- **CA-5** Dado un paciente sin relación con la Dra. Martínez, cuando declara *Urgencia*, entonces ve la historia y el evento queda marcado como emergencia.
- **CA-6** Dada la Dra. Martínez sin relación con un paciente, cuando registra una atención suya con *Urgencia* y después abre su historia declarando *Atención del paciente*, entonces no la ve, ve "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*." y quedan los eventos *Denegado* de la historia y del riesgo.
- **CA-7** Dada la Dra. Martínez, cuando busca a un paciente de otra sede sin relación, entonces lo encuentra y ve su nombre y documento.
- **CA-8** Dado que no se puede verificar la relación, cuando el médico abre una historia, entonces ve "No se pudo verificar el acceso", no ve la historia y, al elegir *Reintentar*, el sistema verifica otra vez.
- **CA-9** Dado un paciente dado de alta en Cali Norte hace 40 días, con una atención registrada por la Dra. Martínez declarando *Atención del paciente*, cuando ella abre su historia declarando *Atención del paciente*, entonces el acceso se permite, porque la atención le da relación aunque el alta ya no cuente.

## Fuera de alcance

- Asignar sedes a los médicos, que viene ya hecho en los datos simulados.
- El acceso de emergencia en sí, que es F-17.
- Mostrar la historia, que es F-02.

## Preguntas abiertas

- ¿La atención registrada con *Atención del paciente* da relación para siempre o hay un límite de tiempo? Hoy es para siempre.
- ¿Si el paciente tiene una cita o un seguimiento activo con el médico, también cuenta como relación? Hoy no existen las citas.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Redacción: el título pasa a *Relación médico-paciente*.
- 0.1.2 · 2026-11-06 · A1 muestra el mensaje de relación de F-18. Se cierra esa pregunta abierta.
- 0.1.3 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.1.4 · 2026-11-06 · La relación también se exige para registrar una atención, como RF-25 0.5.0 y F-04.
- 0.2.0 · 2026-11-06 · Una atención registrada con *Urgencia* no da relación (A3, CA-6, CA-9), como RF-25 0.6.0.
- 0.2.1 · 2026-11-06 · Redacción: la pregunta abierta sobre la duración de la relación habla de la atención registrada con *Atención del paciente*.
- 0.2.2 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
- 0.2.3 · 2026-11-08 · Coherencia con F-02 y F-03: el médico ve los datos básicos dentro de la historia, que sí exige relación.
- 0.2.4 · 2026-11-08 · Formato: el criterio CA-9 pasa después del CA-8, para que los criterios vayan en orden.
- 0.2.5 · 2026-11-08 · Coherencia con F-02: abrir la historia crea dos eventos, el de la historia y el del riesgo, y se permiten o se deniegan juntos.
- 0.2.6 · 2026-11-08 · Una atención registrada con Urgencia no da relación aunque lleve fecha de alta en una sede del médico.
