---
id: F-16
titulo: Declaración del propósito de consulta
version: 0.3.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-19]
depende_de: [F-18]
---

# F-16 · Declaración del propósito de consulta

## Objetivo

El usuario dice para qué va a consultar la información de un paciente o registrarle una atención, cada vez que lo hace, y ese propósito queda en el registro de accesos (O-05).

## Flujo principal

1. El usuario elige un paciente para consultar su información.
2. El sistema le muestra los propósitos que su rol puede declarar.
3. El usuario elige uno y confirma.
4. El sistema sigue con la consulta y registra el propósito en el evento de acceso (F-20).

## Flujos alternos

- **A1 · Sin elegir:** si el usuario confirma sin elegir un propósito, se ve "Elija el propósito de la consulta" y no se sigue.
- **A2 · Cancelar:** si el usuario cancela, vuelve a donde estaba y no se consulta nada ni se crea un evento.
- **A3 · Propósito no permitido para el rol:** si el sistema recibe un propósito que el rol del usuario no permite, la consulta se rechaza y queda un evento *Denegado* (F-18).

## Reglas

- Se declara en cada consulta a la información de un paciente. No se hereda de una consulta anterior ni se guarda en la sesión (AD-05).
- No hay un propósito elegido por defecto.
- También se declara al abrir la lista de pacientes con alta reciente (F-06).
- También se declara al registrar una atención: *Atención del paciente*, o *Urgencia* si el médico no tiene relación con el paciente (F-04).
- El registro de una medición no pide propósito. Su evento queda con *No aplica* (F-12).
- Los propósitos son 5: *Atención del paciente*, *Consulta de historia clínica*, *Seguimiento de reingreso*, *Revisión de calidad* y *Urgencia*.
- El médico ve los 5. El administrativo solo *Revisión de calidad*. El auditor no declara ninguno, porque no consulta pacientes.
- El propósito *Urgencia* se trata en F-17.
- Sin propósito no se muestra ninguna información del paciente.
- Los datos son simulados.

## Estados

- **Cargando:** no aplica.
- **Vacío:** no aplica, porque todo rol que consulta tiene al menos un propósito.
- **Error:** no aplica.

## Datos

- **Propósitos** que el rol puede declarar.
- **Propósito elegido** para esa consulta.

## Criterios de aceptación

- **CA-1** Dado un médico, cuando elige un paciente para consultarlo, entonces ve los 5 propósitos y ninguno elegido.
- **CA-2** Dado un administrativo, cuando elige un paciente, entonces ve solo *Revisión de calidad*.
- **CA-3** Dado un médico que eligió un paciente, cuando confirma sin elegir un propósito, entonces ve "Elija el propósito de la consulta" y no ve la información del paciente.
- **CA-4** Dado un médico que consultó a un paciente con *Atención del paciente*, cuando abre a otro paciente, entonces el propósito no viene elegido.
- **CA-5** Dado un médico que eligió un paciente, cuando cancela la declaración, entonces vuelve a la pantalla anterior y no queda ningún evento.
- **CA-6** Dado un médico que declara *Seguimiento de reingreso*, cuando consulta la historia de un paciente, entonces en la auditoría queda el evento con ese propósito.
- **CA-7** Dado que el sistema recibe la consulta de un administrativo con el propósito *Urgencia*, cuando la procesa, entonces no se muestra la información del paciente y queda un evento con el resultado *Denegado*.
- **CA-8** Dado un médico, cuando entra a la lista de pacientes con alta reciente, entonces ve los 5 propósitos, ninguno elegido, antes de ver la lista.

## Fuera de alcance

- Pedir una justificación escrita.
- La decisión de permitir o denegar, que es de F-18, y el acceso de emergencia, que es F-17.

## Preguntas abiertas

- ¿Con un solo propósito posible, el sistema lo puede elegir solo? Hoy el administrativo tiene que elegirlo.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.2.0 · 2026-11-06 · El propósito también se declara al abrir la lista de pacientes con alta reciente (CA-8). CA-7 y el flujo alterno A3 se redactan a nivel del sistema, porque un administrativo no puede declarar *Urgencia* desde la app.
- 0.3.0 · 2026-11-06 · El propósito también se declara al registrar una atención, y la medición no lo pide. Se cierra esa pregunta abierta.
- 0.3.1 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.3.2 · 2026-11-06 · Redacción: el *Objetivo* incluye el registro de una atención, como las *Reglas* y RF-19 0.5.0.
- 0.3.3 · 2026-11-06 · CA-3 y CA-5 tienen la forma Dado / cuando / entonces.
