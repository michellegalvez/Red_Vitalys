---
id: F-03
titulo: Datos básicos del paciente
version: 0.1.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-03]
depende_de: [F-01, F-16, F-18]
---

# F-03 · Datos básicos del paciente

## Objetivo

El administrativo consulta los datos básicos de un paciente de cualquier sede, sin ver su historia clínica ni su riesgo de reingreso (O-01).

## Flujo principal

1. El administrativo elige un paciente en la búsqueda (F-01).
2. El sistema le pide declarar el propósito de la consulta (F-16), que para su rol es *Revisión de calidad*.
3. El sistema crea un evento de acceso *Consultar* sobre *Datos básicos*. Si no puede crearlo, no muestra los datos (F-20).
4. El sistema muestra los datos básicos del paciente.

## Flujos alternos

- **A1 · Historia o riesgo:** el administrativo no ve ninguna opción para abrir la historia clínica ni el riesgo de reingreso. Si intenta acceder a ellos, se rechaza y queda un evento *Denegado* (F-18).
- **A2 · Propósito no permitido:** si intenta declarar un propósito distinto de *Revisión de calidad*, se rechaza y queda un evento *Denegado* (F-18).
- **A3 · Auditor:** el auditor no puede consultar datos básicos. Si lo intenta, se rechaza y queda un evento *Denegado*.

## Reglas

- Pueden ver los datos básicos el administrativo y el médico. El médico los ve dentro de la historia unificada (F-02).
- Los datos básicos no incluyen atenciones, diagnósticos, riesgo de reingreso ni identificadores de los sistemas de origen.
- El administrativo puede consultar pacientes de cualquier sede.
- Cada consulta crea un evento, con el propósito declarado y la sede de la sesión.
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando datos del paciente…".
- **Vacío:** no aplica, porque el paciente viene de la búsqueda.
- **Error:** si no se pueden cargar, se ve "No se pudieron cargar los datos" con la opción *Reintentar*.

## Datos

- **Nombre** completo.
- **Documento:** tipo y número.
- **Fecha de nacimiento.**
- **Sexo.**
- **Teléfono.**

## Criterios de aceptación

- **CA-1** Dado un administrativo que declara *Revisión de calidad*, cuando abre a un paciente, entonces ve su nombre, documento, fecha de nacimiento, sexo y teléfono.
- **CA-2** Dado un administrativo viendo los datos básicos, cuando revisa la pantalla, entonces no ve atenciones, diagnósticos ni riesgo de reingreso, y no hay ninguna opción para abrirlos.
- **CA-3** Dado un administrativo, cuando consulta los datos básicos de un paciente, entonces en la auditoría de accesos queda un evento con la acción *Consultar*, el recurso *Datos básicos*, ese paciente, el propósito *Revisión de calidad* y el resultado *Permitido*.
- **CA-4** Dado un administrativo, cuando intenta consultar la historia clínica de un paciente, entonces no la ve y queda un evento con el recurso *Historia clínica* y el resultado *Denegado*.
- **CA-5** Dado que el sistema recibe la consulta de un administrativo con el propósito *Urgencia*, cuando la procesa, entonces no se muestra la información del paciente y queda un evento con el resultado *Denegado*.
- **CA-6** Dado que los datos no se pueden cargar, cuando el administrativo abre a un paciente, entonces ve "No se pudieron cargar los datos" y, al elegir *Reintentar*, el sistema los carga otra vez.
- **CA-7** Dado un administrativo con sesión iniciada en una sede, cuando abre a un paciente atendido solo en otra sede, entonces ve sus datos básicos.

## Fuera de alcance

- Editar los datos del paciente.
- La historia clínica y el riesgo de reingreso, que son F-02, F-06 y F-07.
- Buscar al paciente, que es F-01.

## Preguntas abiertas

- Si el administrativo solo tiene un propósito posible, ¿tiene que elegirlo o el sistema lo selecciona?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · CA-5 se redacta a nivel del sistema, porque un administrativo no puede declarar *Urgencia* desde la app.
- 0.1.2 · 2026-11-06 · Se confirman los datos básicos, y los mensajes de rechazo quedan definidos en F-18. Se cierran 2 preguntas abiertas.
- 0.1.3 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
