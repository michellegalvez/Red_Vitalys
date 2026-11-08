---
id: F-02
titulo: Historia unificada del paciente
version: 0.1.9
fecha: 2026-11-08
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
4. El sistema crea dos eventos de acceso *Consultar*, uno sobre *Historia clínica* y otro sobre *Riesgo de reingreso*, porque la historia muestra también el riesgo (F-07). Si no puede crearlos, no muestra la historia y no hace la consulta (F-20).
5. El sistema muestra los datos del paciente.
6. El sistema muestra el identificador del paciente en cada sistema de origen.
7. El sistema muestra las atenciones de todas las sedes, de la más reciente a la más antigua.
8. El sistema muestra el riesgo de reingreso del paciente y por qué lo tiene (F-07).

## Flujos alternos

- **A1 · Paciente sin atenciones:** se ven los datos y los identificadores, y en lugar de las atenciones "Este paciente no tiene atenciones registradas".
- **A2 · Sin relación y sin *Urgencia*:** el acceso se rechaza, no se ve la historia y quedan los eventos *Denegado* de *Historia clínica* y de *Riesgo de reingreso* (F-05).
- **A3 · Otro rol:** si un administrativo o un auditor intenta abrir la historia, se rechaza y queda un evento *Denegado* (F-18).
- **A4 · Registrar una atención:** desde la historia el médico puede registrar una atención (F-04).

## Reglas

- Solo el médico ve la historia clínica.
- La historia muestra las atenciones de todas las sedes de la red, no solo las de la sede de la sesión.
- El paciente se identifica por un único registro unificado. Los identificadores de cada sistema de origen son datos suyos (AD-09).
- Cada atención muestra su tipo (*Hospitalización*, *Urgencias* o *Consulta externa*), su estado (*Finalizada* si tiene fecha de alta, *En curso* si no), la sede, la fecha de inicio y, si la tiene, la de alta, la duración, el destino al alta y el médico que la registró.
- Las fechas de las atenciones van como "29 sep 2026" y, con alta, como "29 sep 2026 – 14 oct 2026". La duración va como "15 d", o "Mismo día" si el inicio y el alta son el mismo día.
- El documento se muestra enmascarado, por ejemplo "CC ··· 7654", hasta que el médico elige *Mostrar documentos*; los identificadores por sistema de origen se enmascaran igual, por ejemplo "HCE-···7654". Mostrarlo no crea otro evento, porque la consulta ya quedó registrada. En la búsqueda (F-01) y en los datos básicos del administrativo (F-03) el documento se ve completo.
- La sede de cada atención se muestra con su nombre corto, por ejemplo "Cali Norte".
- Las atenciones van ordenadas por fecha de inicio, de la más reciente a la más antigua; con la misma fecha, la registrada después va primero.
- Abrir la historia con un propósito crea dos eventos, *Historia clínica* y *Riesgo de reingreso*, con el mismo propósito, resultado y sede de la sesión; se permiten o se deniegan juntos. Si el rol no puede abrir la historia, el rechazo crea un solo evento *Denegado* sobre el recurso pedido (F-18).
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando historia…".
- **Vacío:** el mensaje de A1.
- **Error:** si la historia no se puede cargar, se ve "No se pudo cargar la historia" con la opción *Reintentar*.

## Datos

- **Datos del paciente:** los datos básicos de F-03 (nombre, documento, fecha de nacimiento, sexo y teléfono) más la edad y la dirección.
- **Identificadores:** por cada sistema de origen, el nombre del sistema y el identificador del paciente en él.
- **Atenciones:** tipo, estado, sede, fecha de inicio, fecha de alta, duración, destino al alta y médico. El contador dice "N registros".

## Criterios de aceptación

- **CA-1** Dado un médico con relación con un paciente que tiene atenciones en Clínica Vitalys Cali Norte y en otra sede, cuando abre su historia, entonces ve sus datos, su identificador en cada sistema de origen y las atenciones de las 2 sedes, de la más reciente a la más antigua (O-01).
- **CA-2** Dado un paciente con identificadores distintos en 2 sistemas de origen, cuando el médico abre su historia, entonces ve los 2 identificadores, cada uno con el nombre de su sistema.
- **CA-3** Dado un paciente sin atenciones, cuando el médico abre su historia, entonces ve "Este paciente no tiene atenciones registradas".
- **CA-4** Dado un médico con sesión iniciada, cuando abre la historia declarando *Atención del paciente*, entonces en la auditoría de accesos queda un evento con la acción *Consultar*, el recurso *Historia clínica*, ese paciente, ese propósito y el resultado *Permitido*.
- **CA-5** Dado un médico sin relación con el paciente que declara *Atención del paciente*, cuando intenta abrir su historia, entonces no la ve y quedan dos eventos *Denegado*, uno sobre *Historia clínica* y otro sobre *Riesgo de reingreso*.
- **CA-6** Dado un administrativo, cuando intenta abrir la historia de un paciente, entonces no la ve y queda un evento *Denegado*.
- **CA-7** Dado que la historia no se puede cargar, cuando el médico la abre, entonces ve "No se pudo cargar la historia" y, al elegir *Reintentar*, el sistema la carga otra vez.
- **CA-8** Dados los datos simulados, cuando el médico abre una historia, entonces se muestra en menos de 2 segundos (RNF-06).
- **CA-9** Dados los datos simulados, cuando el médico busca a los pacientes con atenciones en 2 sedes o más, entonces hay al menos 3 y cada uno muestra sus atenciones de todas las sedes (RNF-04).
- **CA-10** Dada una atención de tipo *Hospitalización* con fecha de alta, cuando el médico abre la historia, entonces ve su tipo, el estado *Finalizada*, la sede, las fechas de inicio y de alta, la duración, el destino al alta y el médico.
- **CA-11** Dado un médico que abre la historia de un paciente con propósito permitido, cuando el auditor revisa la auditoría, entonces ve dos eventos con ese paciente y ese propósito: uno sobre *Historia clínica* y otro sobre *Riesgo de reingreso*.
- **CA-12** Dado un paciente con el documento CC 79457654, cuando el médico abre su historia, entonces ve "CC ··· 7654" y, al elegir *Mostrar documentos*, ve el número completo.
- **CA-13** Dado un paciente con identificador "HCE-0007654" en su sistema de origen, cuando el médico abre su historia, entonces ve "HCE-···7654" y, al elegir *Mostrar documentos*, ve el identificador completo.
- **CA-14** Dada una atención registrada en Clínica Vitalys Cali Norte, cuando el médico abre la historia, entonces la ve con la sede "Cali Norte".

## Fuera de alcance

- Buscar al paciente (F-01) y registrar una atención (F-04).
- El riesgo de reingreso y su explicación se definen en F-06 y F-07; la historia los muestra (paso 8). Calcular el riesgo no es de la app (AD-10).
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
- 0.1.5 · 2026-11-08 · Coherencia con F-03: el médico ve los mismos datos básicos dentro de la historia, incluido el teléfono.
- 0.1.6 · 2026-11-08 · Atenciones y documento como en el Figma: tipo, estado, fechas, duración y destino; documento enmascarado con Mostrar documentos; la historia muestra también el riesgo y crea dos eventos (Historia clínica y Riesgo de reingreso); se agregan edad, dirección y CA-10 a CA-12.
- 0.1.7 · 2026-11-08 · Una sola regla de eventos: abrir la historia crea dos (historia y riesgo) y se permiten o se deniegan juntos; el rechazo por rol crea uno. El documento enmascarado solo vale en la historia, las atenciones tienen su clave de orden y los datos del paciente remiten a F-03.
- 0.1.8 · 2026-11-08 · Los identificadores por sistema se enmascaran como el documento y la sede de la atención se muestra con su nombre corto.
- 0.1.9 · 2026-11-08 · Criterios nuevos para los identificadores enmascarados (CA-13) y la sede con nombre corto (CA-14).
