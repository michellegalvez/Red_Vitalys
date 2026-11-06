---
id: F-04
titulo: Registro de una atención
version: 0.3.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-04]
depende_de: [F-02, F-05, F-16, F-18]
---

# F-04 · Registro de una atención

## Objetivo

El médico registra la atención que acaba de dar a un paciente, y esa atención pasa a formar parte de su historia unificada, visible para los médicos de cualquier sede (O-01).

## Flujo principal

1. El médico está en la historia de un paciente (F-02), elige *Registrar atención* y declara el propósito (F-16): *Atención del paciente*, o *Urgencia* si no tiene relación con el paciente.
2. El sistema muestra el formulario con la sede de la sesión propuesta y la fecha y hora actuales.
3. El médico escribe el motivo de consulta y el diagnóstico, y confirma.
4. El sistema crea un evento de acceso *Registrar* sobre *Atención*. Si no puede crearlo, no guarda la atención (F-20).
5. El sistema guarda la atención y vuelve a la historia, donde la atención aparece primera.

## Flujos alternos

- **A1 · Otra sede:** el médico elige una sede distinta de la propuesta. La atención queda con esa sede.
- **A2 · Campos vacíos:** si falta el motivo o el diagnóstico, se ve "Complete el motivo y el diagnóstico" y no se guarda.
- **A3 · Fecha futura:** si la fecha y hora son posteriores a la actual, se ve "La fecha no puede ser futura" y no se guarda.
- **A4 · Error al guardar:** se ve "No se pudo registrar la atención" y lo que el médico escribió se conserva.
- **A5 · Otro rol:** si un administrativo o un auditor intenta registrar una atención, se rechaza y queda un evento *Denegado* (F-18).

## Reglas

- Solo el médico registra atenciones.
- El propósito de una atención es *Atención del paciente* si el médico tiene relación con el paciente, o *Urgencia* si no la tiene. Sin relación y sin *Urgencia*, el registro se rechaza con el mensaje de relación de F-18.
- El médico solo registra una atención de un paciente con el que tiene relación o para el que declaró *Urgencia* (F-05, F-17).
- Para registrar una atención de un paciente sin relación, el médico abre primero su historia declarando *Urgencia* y vuelve a declarar *Urgencia* al registrar. Son dos consultas, y las dos quedan marcadas como emergencia.
- La sede propuesta es la de la sesión. El médico puede elegir cualquier sede de la red.
- El evento de auditoría lleva la sede de la sesión, aunque la atención se haya registrado en otra (AD-05).
- El motivo y el diagnóstico son obligatorios.
- Una atención registrada no se edita ni se borra en esta versión.
- Registrar una atención con *Atención del paciente* le da al médico relación con ese paciente. Con *Urgencia* no se la da (F-05).
- Los datos son simulados.

## Estados

- **Cargando:** mientras se guarda, se ve "Guardando atención…" y no se puede confirmar de nuevo.
- **Vacío:** no aplica.
- **Error:** el mensaje de A4.

## Datos

- **Paciente.**
- **Fecha y hora** de la atención, por defecto la actual.
- **Sede** de la atención, por defecto la de la sesión.
- **Médico** que la registra, que es el usuario con sesión iniciada.
- **Motivo de consulta** y **diagnóstico**.

## Criterios de aceptación

- **CA-1** Dada la Dra. Camila Martínez en la historia de un paciente con el que tiene relación, cuando elige *Registrar atención*, entonces ve el formulario con la sede Clínica Vitalys Cali Norte propuesta.
- **CA-2** Dado el formulario con motivo y diagnóstico completos, cuando el médico confirma, entonces vuelve a la historia y ve la atención nueva primera, con su nombre, la fecha y la sede.
- **CA-3** Dado el formulario, cuando el médico elige otra sede y confirma, entonces la atención queda con esa sede.
- **CA-4** Dado el formulario sin diagnóstico, cuando el médico confirma, entonces ve "Complete el motivo y el diagnóstico" y la atención no se guarda.
- **CA-5** Dado el formulario con una fecha posterior a la actual, cuando el médico confirma, entonces ve "La fecha no puede ser futura" y la atención no se guarda.
- **CA-6** Dado que el guardado falla, cuando el médico confirma, entonces ve "No se pudo registrar la atención" y el formulario conserva lo que escribió.
- **CA-7** Dado un médico que registró una atención, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Registrar*, el recurso *Atención*, ese paciente y el resultado *Permitido*.
- **CA-8** Dado un administrativo, cuando intenta registrar una atención, entonces no puede y queda un evento con la acción *Registrar*, el recurso *Atención* y el resultado *Denegado*.
- **CA-9** Dado un médico de otra sede, cuando abre la historia del mismo paciente con relación, entonces ve la atención registrada con su sede.
- **CA-10** Dado un médico sin relación con un paciente, cuando registra una atención declarando *Atención del paciente*, entonces la atención no se registra y ve "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*."
- **CA-11** Dado un médico sin relación con un paciente, cuando registra una atención declarando *Urgencia*, entonces la atención se registra y el auditor la ve en el filtro *Emergencia*.
- **CA-12** Dado un médico que registró una atención con *Urgencia* para un paciente sin relación, cuando después abre su historia declarando *Atención del paciente*, entonces no la ve y ve "No tiene relación con este paciente. Si es una emergencia, declare *Urgencia*."

## Fuera de alcance

- Editar o borrar una atención.
- Recetas, órdenes de exámenes o adjuntar archivos.
- La historia unificada, que es F-02.

## Preguntas abiertas

- ¿Se puede registrar una atención con una fecha pasada? Se permitió, pero sin un límite de antigüedad.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.2.0 · 2026-11-06 · El médico declara el propósito al registrar: *Atención del paciente*, o *Urgencia* sin relación (CA-10, CA-11). Se confirman los campos de la atención. Se cierran 3 preguntas abiertas.
- 0.3.0 · 2026-11-06 · Una atención registrada con *Urgencia* no da relación (CA-12), y registrar sin relación exige dos consultas con *Urgencia*, como RF-25 0.6.0.
- 0.3.1 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
