---
id: F-01
titulo: Búsqueda de pacientes
version: 0.1.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-01]
depende_de: [F-13, F-16, F-18]
---

# F-01 · Búsqueda de pacientes

## Objetivo

El médico y el administrativo encuentran a un paciente de cualquier sede escribiendo su nombre o su número de documento, y lo ven una sola vez aunque cada sede lo tenga registrado con un identificador distinto (O-01).

## Flujo principal

1. El usuario entra a *Buscar pacientes*.
2. Escribe un nombre o un número de documento.
3. El sistema muestra los pacientes que coinciden, cada uno una sola vez, con su nombre y su número de documento, y el contador de resultados, por ejemplo "3 pacientes".
4. El usuario elige un paciente.
5. El sistema le pide declarar el propósito de la consulta (F-16) y, según el rol, abre la historia unificada del médico (F-02) o los datos básicos del administrativo (F-03).

## Flujos alternos

- **A1 · Sin resultados:** si ningún paciente coincide, se ve "No se encontró ningún paciente con ese nombre o documento" y el contador dice "0 pacientes".
- **A2 · Texto muy corto:** si el usuario escribe menos de 3 caracteres, se ve "Escriba al menos 3 caracteres" y no se busca.
- **A3 · Rol sin permiso:** si un auditor intenta buscar pacientes, la acción se rechaza y queda registrada como *Denegado* (F-18).

## Reglas

- Pueden buscar el médico y el administrativo. El auditor no.
- El nombre se busca por cualquier parte del nombre o de los apellidos. El documento se busca por el número completo.
- La búsqueda no distingue mayúsculas ni tildes.
- Un paciente aparece una sola vez, aunque tenga más de un identificador en distintos sistemas de origen.
- Los resultados van ordenados por nombre, de la A a la Z, y no hay paginación.
- Los resultados solo muestran el nombre y el documento, ningún dato clínico.
- Buscar no crea un evento de acceso, porque solo muestra el nombre y el documento (RF-14 exceptúa la búsqueda). El evento se crea al abrir al paciente (F-02, F-03). Si la búsqueda se rechaza por el rol, sí se crea un evento *Denegado*.
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Buscando…" en lugar de los resultados.
- **Vacío:** el mensaje de A1.
- **Error:** si la búsqueda falla, se ve "No se pudo buscar. Intente de nuevo." con la opción *Reintentar*.

## Datos

- **Texto buscado.**
- Por cada resultado: **nombre** y **número de documento**, con su tipo (por ejemplo, cédula).
- **Contador** de pacientes.

## Criterios de aceptación

- **CA-1** Dado un médico con sesión iniciada, cuando escribe el número de documento de un paciente que existe, entonces ve a ese paciente con su nombre y su documento y el contador "1 paciente".
- **CA-2** Dado un administrativo, cuando escribe una parte del apellido en minúsculas y sin tilde, entonces ve todos los pacientes cuyo nombre la contiene, ordenados de la A a la Z.
- **CA-3** Dado un paciente con atenciones en 2 sedes y un identificador distinto en cada una, cuando el médico lo busca, entonces aparece una sola vez.
- **CA-4** Dado un texto sin coincidencias, cuando el usuario busca, entonces ve "No se encontró ningún paciente con ese nombre o documento" y el contador dice "0 pacientes".
- **CA-5** Dado que el usuario escribe 2 caracteres, cuando intenta buscar, entonces ve "Escriba al menos 3 caracteres" y no ve resultados.
- **CA-6** Dado un auditor, cuando intenta buscar pacientes, entonces no ve resultados y en la auditoría de accesos queda un evento con la acción *Consultar*, el recurso *Datos básicos* y el resultado *Denegado*.
- **CA-7** Dado que la búsqueda falla, cuando el usuario busca, entonces ve "No se pudo buscar. Intente de nuevo." y, al elegir *Reintentar*, el sistema busca otra vez.
- **CA-8** Dado un médico que elige un paciente de los resultados, cuando lo abre, entonces el sistema le pide declarar el propósito de la consulta.
- **CA-9** Dados los datos simulados, cuando el usuario busca, entonces los resultados se muestran en menos de 2 segundos (RNF-06).

## Fuera de alcance

- Mostrar la historia o los datos básicos, que son F-02 y F-03.
- Filtrar por sede, edad u otro dato.
- Buscar por el identificador de un sistema de origen.
- Crear, editar o fusionar pacientes.

## Preguntas abiertas

- ¿Se debe poder buscar por el identificador que el paciente tiene en cada sistema de origen?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Redacción: "varios identificadores" pasa a "más de un identificador".
- 0.1.2 · 2026-11-06 · La búsqueda no crea evento, y RF-14 lo exceptúa. Depende también de F-16. Se cierra esa pregunta abierta.
- 0.1.3 · 2026-11-06 · Se confirman el mínimo de 3 caracteres, la búsqueda por documento completo y los textos de los estados. Se cierran 2 preguntas abiertas.
