---
id: F-20
titulo: Registro de eventos de acceso
version: 0.4.2
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-14, RF-17, RF-31]
depende_de: [F-18]
---

# F-20 · Registro de eventos de acceso

## Objetivo

El sistema deja un evento de acceso cada vez que alguien inicia sesión, consulta o registra información de un paciente, registra una medición o intenta una acción que su rol no permite, y nadie puede cambiar ni borrar esos eventos. Así el auditor puede demostrar quién accedió a qué, cuándo, para qué y con qué resultado (O-04).

## Flujo principal

1. Un usuario inicia sesión, consulta o registra información de un paciente, abre la lista de pacientes con alta reciente, registra una medición, o intenta una acción que su rol no permite.
2. El sistema decide si la acción se permite o se deniega según el rol, la sede de la sesión, el propósito declarado y la relación con el paciente (F-18, F-05).
3. El sistema crea un evento de acceso con los datos de la sección *Datos*, antes de ejecutar la acción.
4. El evento queda disponible para el auditor en la auditoría de accesos (F-21).

## Flujos alternos

- **A1 · Acción denegada:** si el rol no permite la acción, el sistema la rechaza y crea el evento con resultado *Denegado*, sea o no sobre información de un paciente. Por ejemplo, un médico que intenta abrir la auditoría de accesos. El usuario no ve la información que pidió.
- **A2 · Acceso de emergencia:** si el médico declaró el propósito *Urgencia*, el acceso se permite y el evento queda con propósito *Urgencia*, que lo marca como emergencia para que el auditor lo revise (F-17).
- **A3 · Inicio de sesión exitoso:** al confirmar la sede, antes de abrir la sesión, el evento queda con la acción *Ingresar*, el recurso *Sesión*, sin paciente, con el propósito *No aplica*, el resultado *Permitido* y la sede elegida.
- **A4 · Inicio de sesión fallido:** el evento queda con la acción *Ingresar*, el recurso *Sesión*, sin paciente, el propósito *No aplica*, el resultado *Denegado*, el correo con el que se intentó en lugar del usuario, la IP y sin sede. Lo mismo pasa con cada intento durante un bloqueo del inicio de sesión (F-14).
- **A5 · Registro de una medición:** el evento queda con la acción *Registrar*, el recurso *Medición de indicador*, sin paciente y con el propósito *No aplica*.
- **A6 · Intento de editar o borrar un evento:** no existe ninguna opción para editar ni borrar un evento, para ningún rol, incluido el auditor.

## Reglas

- Se crea un evento por cada inicio de sesión, exitoso o fallido, por cada consulta o registro sobre información de un paciente, por cada apertura de la lista de pacientes con alta reciente (F-06) y por cada registro de una medición, se permita o se deniegue. Ninguno se omite.
- La única excepción es la búsqueda de pacientes (F-01), que solo muestra nombre y documento: no crea evento, salvo que se rechace por el rol.
- También se crea un evento *Denegado* por toda acción que el rol no permite, aunque no sea sobre información de un paciente (RF-21). Por ejemplo, cuando un médico o un administrativo intenta abrir la auditoría de accesos.
- La acción es siempre una de estas tres:
  - **Ingresar:** inicio de sesión.
  - **Consultar:** ver información de un paciente, abrir la lista de pacientes con alta reciente o intentar abrir la auditoría de accesos.
  - **Registrar:** agregar información de un paciente, por ejemplo una atención, o una medición de un indicador.
- El resultado es siempre *Permitido* o *Denegado*.
- El propósito es el que el usuario declaró en esa consulta o al registrar la atención: *Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* o *Urgencia*. El inicio de sesión y el registro de una medición llevan *No aplica*.
- Un evento es de emergencia si su propósito es *Urgencia*.
- La sede del evento es la que el usuario eligió al iniciar sesión. Un inicio de sesión fallido no tiene sede.
- La IP solo se registra en los inicios de sesión fallidos. En la entrega 2 es un dato simulado y en la entrega 3 no la manda quien intenta ingresar, sino que la registra el sistema (AD-15).
- Un evento creado no se puede editar ni borrar. Solo se pueden agregar eventos nuevos (AD-08).
- El evento se crea antes de ejecutar la acción. Si no se puede crear, la acción no se hace y el usuario ve "No se pudo completar la acción". Así ninguna acción queda sin registro (O-04).
- El cierre de sesión, manual (F-23) o por inactividad (F-15), no crea evento.
- Los datos son simulados: no se registran personas ni pacientes reales.

## Estados

Esta funcionalidad no tiene pantalla propia, porque el evento se crea sin que el usuario haga nada más. Lo que el usuario ve de ella es esto:

- **Cargando:** no aplica. El usuario ve el estado de la acción que hizo, por ejemplo la carga de la historia clínica.
- **Vacío:** no aplica.
- **Error:** si el evento no se pudo crear, la acción no se hace y el usuario ve "No se pudo completar la acción".

## Datos

Cada evento de acceso tiene:

- **Fecha y hora** en que pasó, por ejemplo "30 oct 2026 · 09:47".
- **Usuario** que hizo la acción, por su nombre. En un inicio de sesión fallido, el correo con el que se intentó.
- **Acción:** *Ingresar*, *Consultar* o *Registrar*.
- **Recurso** sobre el que se hizo, por ejemplo *Sesión*, *Datos básicos*, *Historia clínica*, *Riesgo de reingreso*, *Atención*, *Medición de indicador*, *Pacientes con alta reciente* o *Auditoría de accesos*.
- **Paciente** al que pertenece la información. Queda vacío en *Ingresar*, en *Medición de indicador* y cuando el recurso es *Pacientes con alta reciente* o *Auditoría de accesos*.
- **Propósito** declarado.
- **Resultado:** *Permitido* o *Denegado*.
- **Sede** de la sesión desde la que se hizo. Vacía en un inicio de sesión fallido.
- **IP**, solo en los inicios de sesión fallidos.

## Criterios de aceptación

- **CA-1** Dado que la Dra. Camila Martínez ingresó desde Clínica Vitalys Cali Norte, cuando inicia sesión, entonces el auditor ve en la auditoría de accesos un evento con su nombre, la fecha y hora, la acción *Ingresar*, el recurso *Sesión*, sin paciente, el propósito *No aplica*, el resultado *Permitido* y la sede Clínica Vitalys Cali Norte.
- **CA-2** Dado un médico con sesión iniciada, cuando consulta la historia clínica de un paciente declarando *Atención del paciente*, entonces el auditor ve en la auditoría de accesos un evento con la acción *Consultar*, el recurso *Historia clínica*, ese paciente, ese propósito y el resultado *Permitido*.
- **CA-3** Dado un médico con sesión iniciada, cuando registra una atención de un paciente, entonces el auditor ve en la auditoría de accesos un evento con la acción *Registrar*, el recurso *Atención*, ese paciente y el resultado *Permitido*.
- **CA-4** Dado un administrativo con sesión iniciada, cuando intenta consultar la historia clínica de un paciente, entonces no ve la historia y el auditor ve en la auditoría de accesos un evento con la acción *Consultar*, el recurso *Historia clínica* y el resultado *Denegado*.
- **CA-5** Dado un médico que declara *Urgencia* para un paciente con el que no tiene relación, cuando consulta su historia, entonces el acceso se permite y el evento queda con el propósito *Urgencia* y aparece en el filtro *Emergencia* de la auditoría.
- **CA-6** Dado cualquier rol, cuando busca una opción para editar o borrar un evento de acceso, entonces no la encuentra en ninguna parte de la app.
- **CA-7** Dado un usuario con sesión iniciada, cuando cierra sesión, entonces el auditor no ve en la auditoría de accesos ningún evento de ese cierre de sesión.
- **CA-8** *(movido a F-21 como CA-11)*
- **CA-9** Dado un médico con sesión iniciada, cuando intenta abrir la auditoría de accesos, entonces no la ve y el auditor ve un evento con la acción *Consultar*, el recurso *Auditoría de accesos*, sin paciente y con el resultado *Denegado*.
- **CA-10** Dado un inicio de sesión con una contraseña equivocada para el correo camila.martinez@vitalys.co, cuando el auditor revisa la auditoría, entonces ve un evento con ese correo en lugar del usuario, la acción *Ingresar*, el recurso *Sesión*, el resultado *Denegado*, la IP y sin sede.
- **CA-11** Dado un administrativo que registra una medición, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Registrar*, el recurso *Medición de indicador*, sin paciente, el propósito *No aplica* y el resultado *Permitido*.
- **CA-12** Dado un médico que intenta registrar una medición, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Registrar*, el recurso *Medición de indicador* y el resultado *Denegado*.
- **CA-13** Dado un médico que abre la lista de pacientes con alta reciente declarando *Seguimiento de reingreso*, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Consultar*, el recurso *Pacientes con alta reciente*, sin paciente, ese propósito y el resultado *Permitido*.
- **CA-14** Dado un médico que busca a un paciente por su nombre, cuando el auditor revisa la auditoría, entonces no ve ningún evento de esa búsqueda.
- **CA-15** Dado que el evento no se puede crear, cuando un médico intenta abrir la historia de un paciente, entonces no ve la historia y ve "No se pudo completar la acción".
- **CA-16** Dado que el evento no se puede crear, cuando un médico confirma el registro de una atención, entonces la atención no se guarda y ve "No se pudo completar la acción".

## Fuera de alcance

- Mostrar y filtrar los eventos, que es F-21.
- Decidir qué permite cada rol: eso es del control de acceso (F-18).
- Registrar el cierre de sesión, la consulta del tablero de indicadores, la consulta del perfil, la búsqueda permitida de pacientes o la consulta permitida de la auditoría por el auditor.
- Avisarle a alguien cuando ocurre un acceso denegado o de emergencia.

## Preguntas abiertas

- ¿Los nombres de recurso de la sección *Datos* son los definitivos? Hay que confirmarlos con quienes escriben las specs de cada pantalla.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión, alineada con los requisitos 0.1.0: inicio de sesión fallido con correo e IP, registro de mediciones y toda acción denegada.
- 0.2.0 · 2026-11-06 · Se agrega el recurso *Pacientes con alta reciente* para el rechazo de F-06. Se quita "servidor" de las reglas. Queda alineada con RF-14 0.2.0 y AD-07 0.2.0: el inicio de sesión fallido no tiene sede.
- 0.3.0 · 2026-11-06 · Abrir la lista de pacientes con alta reciente crea un evento (CA-13) y la búsqueda no (CA-14), como RF-14 0.3.0 y AD-07 0.3.0. Se cierra esa pregunta abierta.
- 0.4.0 · 2026-11-06 · Si el evento no se puede crear, la acción no se hace (CA-15). El bloqueo del inicio de sesión es por dispositivo (F-14 0.2.0). Se cierran 2 preguntas abiertas.
- 0.4.1 · 2026-11-06 · El propósito de un evento también es el que se declara al registrar una atención, como RF-19 0.5.0.
- 0.4.2 · 2026-11-06 · El evento se crea antes de ejecutar la acción (paso 3, regla y CA-16). El paso 2 suma la relación con el paciente. Alineada con RF-14 0.6.1 y AD-07 0.6.1.
