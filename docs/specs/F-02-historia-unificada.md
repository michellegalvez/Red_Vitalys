---
id: F-02
titulo: Historia unificada del paciente
version: 0.1.4
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-02]
depende_de: [F-01, F-05, F-16, F-18]
---

# F-02 · Historia unificada del paciente

## Objetivo

El médico ve en un solo lugar los datos de un paciente, su identificador en cada sistema de origen y sus atenciones de todas las sedes, para decidir con la historia completa (O-01).

## Flujo principal

1. El médico elige un paciente, desde la búsqueda (F-01) o desde la lista de pacientes con alta reciente (F-06).
2. El sistema le pide declarar el propósito de la consulta (F-16).
3. El sistema verifica que el médico tenga relación con el paciente o que haya declarado *Urgencia* (F-05, F-17).
4. El sistema crea un evento de acceso *Consultar* sobre *Historia clínica*. Si no puede crearlo, no muestra la historia (F-20).
5. El sistema muestra los datos del paciente.
6. El sistema muestra el identificador del paciente en cada sistema de origen.
7. El sistema muestra las atenciones de todas las sedes, de la más reciente a la más antigua.

## Flujos alternos

- **A1 · Paciente sin atenciones:** se ven los datos y los identificadores, y en lugar de las atenciones "Este paciente no tiene atenciones registradas".
- **A2 · Sin relación y sin *Urgencia*:** el acceso se rechaza, no se ve la historia y queda un evento *Denegado* (F-05).
- **A3 · Otro rol:** si un administrativo o un auditor intenta abrir la historia, se rechaza y queda un evento *Denegado* (F-18).
- **A4 · Registrar una atención:** desde la historia el médico puede registrar una atención (F-04).

## Reglas

- Solo el médico ve la historia clínica.
- La historia muestra las atenciones de todas las sedes de la red, no solo las de la sede de la sesión.
- El paciente se identifica por un único registro unificado. Los identificadores de cada sistema de origen son datos suyos (AD-09).
- Cada atención muestra su fecha, la sede, el médico que la hizo, el motivo de consulta y el diagnóstico.
- Las fechas van en el formato "30 oct 2026 · 09:47".
- Cada consulta crea un evento, se permita o se deniegue, con el propósito declarado y la sede de la sesión.
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando historia…".
- **Vacío:** el mensaje de A1.
- **Error:** si la historia no se puede cargar, se ve "No se pudo cargar la historia" con la opción *Reintentar*.

## Datos

- **Datos del paciente:** nombre, documento, fecha de nacimiento y sexo.
- **Identificadores:** por cada sistema de origen, el nombre del sistema y el identificador del paciente en él.
- **Atenciones:** fecha y hora, sede, médico, motivo de consulta y diagnóstico.

## Criterios de aceptación

- **CA-1** Dado un médico con relación con un paciente que tiene atenciones en Clínica Vitalys Cali Norte y en otra sede, cuando abre su historia, entonces ve sus datos, su identificador en cada sistema de origen y las atenciones de las 2 sedes, de la más reciente a la más antigua (O-01).
- **CA-2** Dado un paciente con identificadores distintos en 2 sistemas de origen, cuando el médico abre su historia, entonces ve los 2 identificadores, cada uno con el nombre de su sistema.
- **CA-3** Dado un paciente sin atenciones, cuando el médico abre su historia, entonces ve "Este paciente no tiene atenciones registradas".
- **CA-4** Dado un médico con sesión iniciada, cuando abre la historia declarando *Atención del paciente*, entonces en la auditoría de accesos queda un evento con la acción *Consultar*, el recurso *Historia clínica*, ese paciente, ese propósito y el resultado *Permitido*.
- **CA-5** Dado un médico sin relación con el paciente que declara *Atención del paciente*, cuando intenta abrir su historia, entonces no la ve y queda un evento *Denegado*.
- **CA-6** Dado un administrativo, cuando intenta abrir la historia de un paciente, entonces no la ve y queda un evento *Denegado*.
- **CA-7** Dado que la historia no se puede cargar, cuando el médico la abre, entonces ve "No se pudo cargar la historia" y, al elegir *Reintentar*, el sistema la carga otra vez.
- **CA-8** Dados los datos simulados, cuando el médico abre una historia, entonces se muestra en menos de 2 segundos (RNF-06).
- **CA-9** Dados los datos simulados, cuando el médico busca a los pacientes con atenciones en 2 sedes o más, entonces hay al menos 3 y cada uno muestra sus atenciones de todas las sedes (RNF-04).

## Fuera de alcance

- Buscar al paciente (F-01) y registrar una atención (F-04).
- El riesgo de reingreso y su explicación (F-06, F-07).
- Editar o borrar atenciones ya registradas.
- Exportar o imprimir la historia.

## Preguntas abiertas

- ¿La historia se muestra completa o hay un límite de atenciones o de años?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Se confirman los datos de una atención, y los mensajes de rechazo quedan definidos en F-18. Se cierran 2 preguntas abiertas.
- 0.1.2 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.1.3 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
- 0.1.4 · 2026-11-06 · Formato: línea en blanco antes de los encabezados y lista de criterios sin cortes.
