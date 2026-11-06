---
id: F-20
titulo: Registro de eventos de acceso
version: 0.1.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-14, RF-17]
depende_de: []
---

# F-20 · Registro de eventos de acceso

## Objetivo

El sistema deja un evento de acceso cada vez que alguien inicia sesión o consulta o registra información de un paciente, y nadie puede cambiar ni borrar esos eventos. Así el auditor puede demostrar quién accedió a qué, cuándo, para qué y con qué resultado (O-04).

## Flujo principal

1. Un usuario inicia sesión, o consulta o registra información de un paciente.
2. El sistema decide si la acción se permite o se deniega según el rol, la sede de la sesión y el propósito declarado.
3. El sistema crea un evento de acceso con los datos de la sección *Datos*.
4. El evento queda disponible para el auditor en la auditoría de accesos (F-21).

## Flujos alternos

- **A1 · Acción denegada:** si el rol no permite la acción, el sistema la rechaza y crea el evento con resultado *Denegado*. El usuario no ve la información que pidió.
- **A2 · Acceso de emergencia:** si el médico declaró el propósito *Urgencia*, el acceso se permite y el evento queda con propósito *Urgencia*, que lo marca como emergencia para que el auditor lo revise.
- **A3 · Inicio de sesión:** al iniciar sesión, el evento queda con la acción *Ingresar*, el recurso *Sesión*, sin paciente y con el propósito *No aplica*.
- **A4 · Intento de editar o borrar un evento:** no existe ninguna opción para editar ni borrar un evento, para ningún rol, incluido el auditor.

## Reglas

- Se crea un evento por cada inicio de sesión y por cada consulta o registro sobre información de un paciente, se permita o se deniegue. Ninguno se omite.
- La acción es siempre una de estas tres:
  - **Ingresar:** inicio de sesión.
  - **Consultar:** ver información de un paciente.
  - **Registrar:** agregar información de un paciente, por ejemplo una atención.
- El resultado es siempre *Permitido* o *Denegado*.
- El propósito es el que el usuario declaró en esa consulta: *Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* o *Urgencia*. El inicio de sesión lleva *No aplica*.
- Un evento es de emergencia si su propósito es *Urgencia*.
- La sede del evento es la que el usuario eligió al iniciar sesión.
- Un evento creado no se puede editar ni borrar. Solo se pueden agregar eventos nuevos.
- El cierre de sesión no crea evento en esta versión.
- Los datos son simulados: no se registran personas ni pacientes reales.

## Estados

Esta funcionalidad no tiene pantalla propia, porque el evento se crea sin que el usuario haga nada más. Lo que el usuario ve de ella es esto:

- **Cargando:** no aplica. El usuario ve el estado de la acción que hizo, por ejemplo la carga de la historia clínica.
- **Vacío:** no aplica.
- **Error:** si el evento no se pudo crear, ver *Preguntas abiertas*.

## Datos

Cada evento de acceso tiene:

- **Fecha y hora** en que pasó, por ejemplo "30 oct 2026 · 09:47".
- **Usuario** que hizo la acción, por su nombre.
- **Acción:** *Ingresar*, *Consultar* o *Registrar*.
- **Recurso** sobre el que se hizo, por ejemplo *Sesión*, *Datos básicos*, *Historia clínica*, *Riesgo de reingreso* o *Atención*.
- **Paciente** al que pertenece la información. Queda vacío en *Ingresar*.
- **Propósito** declarado.
- **Resultado:** *Permitido* o *Denegado*.
- **Sede** de la sesión desde la que se hizo.

## Criterios de aceptación

- **CA-1** Dado que la Dra. Camila Martínez ingresó desde Clínica Vitalys Cali Norte, cuando inicia sesión, entonces se crea un evento con su nombre, la fecha y hora, la acción *Ingresar*, el recurso *Sesión*, sin paciente, el propósito *No aplica*, el resultado *Permitido* y la sede Clínica Vitalys Cali Norte.
- **CA-2** Dado un médico con sesión iniciada, cuando consulta la historia clínica de un paciente declarando *Atención del paciente*, entonces se crea un evento con la acción *Consultar*, el recurso *Historia clínica*, ese paciente, ese propósito y el resultado *Permitido*.
- **CA-3** Dado un médico con sesión iniciada, cuando registra una atención de un paciente, entonces se crea un evento con la acción *Registrar*, el recurso *Atención*, ese paciente y el resultado *Permitido*.
- **CA-4** Dado un administrativo con sesión iniciada, cuando intenta consultar la historia clínica de un paciente, entonces la consulta se rechaza y se crea un evento con la acción *Consultar*, el recurso *Historia clínica* y el resultado *Denegado*.
- **CA-5** Dado un médico que declara *Urgencia* para un paciente con el que no tiene una atención ni un seguimiento, cuando consulta su historia, entonces el acceso se permite y el evento queda con el propósito *Urgencia* y aparece en el filtro *Emergencia* de la auditoría.
- **CA-6** Dado cualquier rol, cuando busca una opción para editar o borrar un evento de acceso, entonces no la encuentra en ninguna parte de la app.
- **CA-7** Dado un usuario con sesión iniciada, cuando cierra sesión, entonces no se crea ningún evento.
- **CA-8** Dados los datos simulados, cuando el auditor abre la auditoría, entonces hay al menos 8 eventos, al menos 1 *Denegado* y al menos 1 con propósito *Urgencia* (RNF-04).

## Fuera de alcance

- Mostrar y filtrar los eventos, que es F-21.
- Decidir qué permite cada rol: eso es del control de acceso, que especifica otro integrante del equipo (RF-21).
- Registrar el cierre de sesión, la consulta del tablero de indicadores, la consulta del perfil o la consulta de la auditoría misma.
- Avisarle a alguien cuando ocurre un acceso denegado o de emergencia.

## Preguntas abiertas

- Si el evento no se puede crear, ¿se deja continuar la acción o se bloquea? Bloquearla asegura el 100 % de O-04.
- Un intento de inicio de sesión fallido, por ejemplo con la contraseña equivocada, ¿crea un evento *Denegado*? Si es así, ¿qué usuario queda en el evento?
- ¿Registrar una medición de un indicador crea un evento? RF-14 solo habla de la información de un paciente.
- ¿Los nombres de recurso de la sección *Datos* son los definitivos? Hay que confirmarlos con quienes escriben las specs de cada pantalla.

## Historial

- 0.1.0 · 2026-11-05 · Primera versión.
- 0.1.1 · 2026-11-06 · Autores: los 4 integrantes del equipo.
