---
id: F-07
titulo: Factores que explican el riesgo de reingreso
version: 0.2.8
fecha: 2026-11-08
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-07]
depende_de: [F-05, F-06, F-16, F-18]
---

# F-07 · Factores que explican el riesgo de reingreso

## Objetivo

El médico abre a un paciente con riesgo de reingreso y ve por qué su riesgo es el que es: qué factores lo suben, cuáles lo bajan y cuántos puntos aporta cada uno (O-02).

## Flujo principal

1. El médico abre la historia de un paciente (F-02), desde la lista de pacientes con alta reciente (F-06) o desde la búsqueda (F-01). El propósito, la relación y los eventos son los de F-02.
2. La historia muestra el riesgo del paciente de 0 a 100 y la alerta *Riesgo alto* si es 70 o más.
3. El sistema muestra los factores: los que suben el riesgo con puntos positivos, por ejemplo "+15", y los que lo bajan con puntos negativos, por ejemplo "−8".
4. El sistema ofrece *Cómo se calcula*, que explica que el puntaje y los factores son simulados y que la app no los calcula.

## Flujos alternos

- **A1 · Sin factores:** si el paciente no tiene factores guardados, se ve el riesgo y "No hay factores registrados para este paciente".
- **A2 · Sin relación y sin *Urgencia*:** el acceso se rechaza y quedan los eventos *Denegado* de la historia y del riesgo (F-05).
- **A3 · Otro rol:** si un administrativo o un auditor intenta ver el riesgo, se rechaza y queda un evento *Denegado* (F-18).

## Reglas

- Solo el médico ve el riesgo y sus factores.
- Cada factor muestra su nombre, si sube o baja el riesgo y sus puntos.
- Los factores van ordenados por la magnitud de sus puntos, del que más pesa al que menos, sin importar si suben o bajan. Con la misma magnitud va primero el que sube.
- La pantalla muestra la base del modelo, que es el puntaje guardado menos la suma de los puntos de los factores: "Base del modelo: N puntos". La app no calcula el riesgo (AD-10).
- El riesgo y los factores se muestran tal como están guardados. La app no los calcula (AD-10).
- El evento de *Riesgo de reingreso* se crea junto con el de *Historia clínica*, con el mismo propósito, resultado y sede de la sesión (F-02). Si no puede crearlo, no muestra el riesgo (F-20).
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando riesgo…".
- **Vacío:** el mensaje de A1.
- **Error:** si no se puede cargar, se ve "No se pudo cargar el riesgo" con la opción *Reintentar*.

## Datos

- **Riesgo de reingreso:** de 0 a 100.
- **Alerta** *Riesgo alto* si es 70 o más.
- **Base del modelo:** el puntaje menos la suma de los puntos de los factores.
- Por cada factor: **nombre**, **efecto** (*Sube* o *Baja*) y **puntos**.

## Criterios de aceptación

- **CA-1** Dado un médico con relación con un paciente con riesgo 82, cuando lo abre desde la lista, entonces ve el riesgo 82, la alerta *Riesgo alto* y la lista de factores.
- **CA-2** Dado un paciente con el factor "Hospitalizaciones en el último año" que suma 15 puntos y el factor "Seguimiento ambulatorio programado" que resta 8, cuando el médico lo abre, entonces ve el primero con "+15" y el segundo con "−8".
- **CA-3** Dado un paciente con factores de 3, −12 y 10 puntos, cuando el médico lo abre, entonces los ve en este orden: −12, 10, 3.
- **CA-4** Dado un paciente sin factores guardados, cuando el médico lo abre, entonces ve su riesgo y "No hay factores registrados para este paciente".
- **CA-5** Dado un médico, cuando abre el riesgo de un paciente declarando *Seguimiento de reingreso*, entonces en la auditoría queda un evento con la acción *Consultar*, el recurso *Riesgo de reingreso*, ese paciente, ese propósito y el resultado *Permitido*.
- **CA-6** Dado un administrativo, cuando intenta ver el riesgo de un paciente, entonces no lo ve y queda un evento con el recurso *Riesgo de reingreso* y el resultado *Denegado*.
- **CA-7** Dado un médico sin relación con el paciente, cuando intenta abrir su riesgo sin declarar *Urgencia*, entonces no lo ve y quedan los eventos *Denegado* de la historia y del riesgo.
- **CA-8** Dado que el riesgo no se puede cargar, cuando el médico lo abre, entonces ve "No se pudo cargar el riesgo" y, al elegir *Reintentar*, el sistema lo carga otra vez.
- **CA-9** Dado un paciente con riesgo 91 y factores que suman 54 puntos, cuando el médico lo abre, entonces ve "Base del modelo: 37 puntos".
- **CA-10** Dado un médico que ve el riesgo de un paciente, cuando elige *Cómo se calcula*, entonces ve que el puntaje y los factores son simulados y que la app no los calcula.

## Fuera de alcance

- Calcular el riesgo o entrenar un modelo.
- La lista de pacientes con alta reciente, que es F-06.
- Cambiar o corregir el riesgo.

## Preguntas abiertas

- ¿Los factores tienen una explicación más larga que su nombre?
- ¿Se puede ver el riesgo de un paciente con el alta de hace más de 30 días? Hoy se llega desde la lista y desde la búsqueda.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.2.0 · 2026-11-06 · El propósito ya no viene elegido por defecto, para ser coherente con F-16.
- 0.2.1 · 2026-11-06 · Los mensajes de rechazo quedan definidos en F-18. Se cierra esa pregunta abierta.
- 0.2.2 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.2.3 · 2026-11-06 · El evento se crea antes de ejecutar la acción, y si no se puede crear la acción no se hace, como RF-14 0.6.1 y AD-07 0.6.1.
- 0.2.4 · 2026-11-06 · Formato: línea en blanco antes de los encabezados y lista de criterios sin cortes.
- 0.2.5 · 2026-11-06 · Nueva pregunta abierta: qué pasa con un paciente que ya no está en la lista, que hoy es la única entrada al riesgo.
- 0.2.6 · 2026-11-08 · El riesgo se ve dentro de la historia y se abre con el mismo propósito. Los factores se ordenan por magnitud (CA-3). El puntaje es la base del modelo más los factores (CA-9). Nuevo desplegable Cómo se calcula (CA-10). Se cierra la pregunta abierta sobre el puntaje base.
- 0.2.7 · 2026-11-08 · La historia lleva el riesgo: el flujo remite a F-02 para el propósito, la relación y los eventos, y los rechazos dejan los dos eventos. La base del modelo es el puntaje menos la suma de los factores. Se reescribe la pregunta abierta de la lista.
- 0.2.8 · 2026-11-08 · Redacción: el paso 4 no nombra un componente de pantalla.
