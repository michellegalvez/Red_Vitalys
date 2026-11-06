---
id: F-06
titulo: Pacientes con alta reciente por riesgo de reingreso
version: 0.3.2
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-05, RF-06]
depende_de: [F-13, F-16, F-18, F-20]
---

# F-06 · Pacientes con alta reciente por riesgo de reingreso

## Objetivo

El médico ve a los pacientes dados de alta en los últimos 30 días en toda la red, ordenados del mayor al menor riesgo de volver a hospitalizarse, y distingue a los que tienen riesgo alto por una alerta (O-02).

## Flujo principal

1. El médico entra a *Pacientes con alta reciente*.
2. El sistema le pide declarar el propósito de la consulta (F-16).
3. El sistema crea un evento de acceso *Consultar* sobre *Pacientes con alta reciente*, sin paciente y con el propósito declarado. Si no puede crearlo, no muestra la lista (F-20).
4. El sistema muestra los pacientes dados de alta en los últimos 30 días, del mayor al menor riesgo de reingreso.
5. Cada paciente muestra su nombre, su riesgo de 0 a 100, la fecha de alta y la sede del alta. Los de 70 o más muestran además la alerta *Riesgo alto*.
6. El sistema muestra el contador de pacientes, por ejemplo "8 pacientes".
7. El médico elige un paciente y el sistema le pide declarar el propósito otra vez (F-16) y abre su riesgo con la explicación (F-07).

## Flujos alternos

- **A1 · Sin altas recientes:** se ve "No hay pacientes dados de alta en los últimos 30 días" y el contador dice "0 pacientes".
- **A2 · Otro rol:** si un administrativo o un auditor intenta abrir la lista, se rechaza y queda un evento *Denegado* con la acción *Consultar* y el recurso *Pacientes con alta reciente* (F-18, F-20).

## Reglas

- Solo el médico ve esta lista.
- La lista incluye a los pacientes de todas las sedes de la red, no solo los de las sedes del médico.
- Cuenta el alta de los últimos 30 días contando desde hoy.
- El riesgo es un número entero de 0 a 100. La alerta *Riesgo alto* se muestra con 70 o más. Con 69 no. El umbral se define en un solo lugar (AD-10).
- Si dos pacientes tienen el mismo riesgo, va primero el que tiene el alta más reciente.
- La app muestra el riesgo tal como está guardado y no lo calcula (AD-10).
- No hay paginación: se muestran todos los pacientes.
- Cada vez que el médico abre la lista se crea un evento *Consultar* sobre *Pacientes con alta reciente*, sin paciente y con el propósito declarado (F-20). Al abrir a un paciente se crea otro evento (F-07).
- El propósito se declara cada vez que se abre la lista y cada vez que se abre a un paciente. No se hereda (AD-05).
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando pacientes…".
- **Vacío:** el mensaje de A1.
- **Error:** si la lista no se puede cargar, se ve "No se pudo cargar la lista" con la opción *Reintentar*.

## Datos

- Por cada paciente: **nombre**, **riesgo de reingreso** (0 a 100), **alerta** *Riesgo alto* si es 70 o más, **fecha de alta** y **sede del alta**.
- **Contador** de pacientes.
- **Propósito** declarado al abrir la lista.

## Criterios de aceptación

- **CA-1** Dado un médico que declaró el propósito, cuando abre la lista, entonces ve los pacientes con alta en los últimos 30 días de mayor a menor riesgo y el contador, por ejemplo "8 pacientes".
- **CA-2** Dado un paciente con riesgo 70, cuando el médico abre la lista, entonces ve la alerta *Riesgo alto* en ese paciente.
- **CA-3** Dado un paciente con riesgo 69, cuando el médico abre la lista, entonces no ve la alerta en ese paciente.
- **CA-4** Dado un paciente dado de alta hace 31 días, cuando el médico abre la lista, entonces ese paciente no aparece.
- **CA-5** Dados 2 pacientes con riesgo 75, cuando el médico abre la lista, entonces el de alta más reciente aparece primero.
- **CA-6** Dado un paciente dado de alta en otra sede, cuando la Dra. Camila Martínez abre la lista, entonces lo ve.
- **CA-7** Dado que no hay altas recientes, cuando el médico abre la lista, entonces ve "No hay pacientes dados de alta en los últimos 30 días" y el contador dice "0 pacientes".
- **CA-8** Dado que la lista no se puede cargar, cuando el médico la abre, entonces ve "No se pudo cargar la lista" y, al elegir *Reintentar*, el sistema la carga otra vez.
- **CA-9** Dado un administrativo, cuando intenta abrir la lista, entonces no la ve y queda un evento con la acción *Consultar*, el recurso *Pacientes con alta reciente* y el resultado *Denegado*.
- **CA-10** Dados los datos simulados, cuando el médico abre la lista, entonces se muestra en menos de 2 segundos (RNF-06).
- **CA-11** Dados los datos simulados, cuando el médico abre la lista, entonces ve al menos 8 pacientes, de los que al menos 4 tienen la alerta (RNF-04).
- **CA-12** Dado un médico que entra a la lista, cuando todavía no declaró el propósito, entonces el sistema se lo pide y no ve ningún paciente.
- **CA-13** Dado un médico que abre la lista declarando *Seguimiento de reingreso*, cuando el auditor revisa la auditoría, entonces ve un evento con la acción *Consultar*, el recurso *Pacientes con alta reciente*, sin paciente, el propósito *Seguimiento de reingreso* y el resultado *Permitido*.

## Fuera de alcance

- La explicación del riesgo, que es F-07.
- Calcular el riesgo.
- Filtrar la lista por sede o por rango de riesgo.

## Preguntas abiertas

- ¿El desempate por alta más reciente es el correcto?
- ¿La lista puede filtrarse por sede? Hoy muestra toda la red.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.2.0 · 2026-11-06 · El propósito ya no viene elegido por defecto, para ser coherente con F-16. El rechazo de la lista queda registrado con el recurso *Pacientes con alta reciente* (A2, CA-9). CA-11 pide al menos 8 pacientes, como RNF-04. Se quita "varios" de las preguntas abiertas.
- 0.3.0 · 2026-11-06 · Abrir la lista exige declarar el propósito y crea un evento (pasos 2 y 6, CA-12, CA-13), para cumplir RF-14 y O-04. Depende también de F-16 y F-20. Se cierra esa pregunta abierta.
- 0.3.1 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.3.2 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
