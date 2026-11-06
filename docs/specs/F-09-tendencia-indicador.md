---
id: F-09
titulo: Tendencia mensual de un indicador
version: 0.1.3
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-10]
depende_de: [F-08]
---

# F-09 · Tendencia mensual de un indicador

## Objetivo

El usuario ve cómo ha cambiado un indicador en los últimos 6 meses, para toda la red o para la sede que elija (O-03).

## Flujo principal

1. El usuario abre el detalle de un indicador desde el tablero (F-08).
2. El sistema muestra la tendencia de los últimos 6 periodos de toda la red, con el valor de cada mes.
3. El usuario elige una sede.
4. El sistema muestra la tendencia de esa sede, con el valor de cada mes.

## Flujos alternos

- **A1 · Volver a la red:** el usuario elige *Toda la red* y vuelve a ver la tendencia de la red.
- **A2 · Meses sin medición:** si la sede no tiene medición en algún mes, ese mes dice *Sin medición*.
- **A3 · Sin mediciones:** si no hay ninguna medición en los 6 periodos, se ve "No hay mediciones en los últimos 6 meses".

## Reglas

- Lo ven los 3 roles. Verla no crea un evento de acceso.
- Son los 6 últimos meses cerrados, del más antiguo al más reciente.
- Al abrir el detalle está elegida *Toda la red*.
- El valor de la red en cada mes es el promedio simple de las sedes con medición ese mes.
- Las sedes que se pueden elegir son solo las que aplican al indicador (F-08).
- Los valores se muestran con la unidad del indicador.
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando tendencia…".
- **Vacío:** el mensaje de A3.
- **Error:** si no se puede cargar, se ve "No se pudo cargar la tendencia" con la opción *Reintentar*.

## Datos

- **Indicador** y su unidad.
- **Sede** elegida o *Toda la red*.
- Por cada uno de los 6 meses: **periodo**, por ejemplo "oct 2026", y **valor**.

## Criterios de aceptación

- **CA-1** Dado un usuario en el detalle del tiempo de espera, cuando lo abre, entonces ve 6 meses de toda la red, del más antiguo al más reciente, cada uno con su valor en minutos.
- **CA-2** Dado el detalle de un indicador, cuando el usuario elige una sede, entonces ve los 6 valores de esa sede.
- **CA-3** Dado el detalle con una sede elegida, cuando el usuario elige *Toda la red*, entonces vuelve a ver la tendencia de la red.
- **CA-4** Dada una sede sin medición en agosto, cuando el usuario ve su tendencia, entonces agosto dice *Sin medición*.
- **CA-5** Dado el reingreso, cuando el usuario abre la lista de sedes, entonces no ve centros ambulatorios ni laboratorios.
- **CA-6** Dado un indicador sin mediciones, cuando el usuario abre su detalle, entonces ve "No hay mediciones en los últimos 6 meses".
- **CA-7** Dado que la tendencia no se puede cargar, cuando el usuario abre el detalle, entonces ve "No se pudo cargar la tendencia" y, al elegir *Reintentar*, el sistema la carga otra vez.

## Fuera de alcance

- El tablero, la comparación entre sedes y las mediciones recientes (F-08, F-10, F-11).
- Elegir otro rango de meses.
- Comparar 2 sedes en la misma tendencia.

## Preguntas abiertas

- ¿La tendencia debe mostrar también la meta o el promedio de la red, además de la sede elegida?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.1.2 · 2026-11-06 · Redacción: una pregunta abierta ya no nombra una posición en la pantalla.
- 0.1.3 · 2026-11-06 · La red tiene una cadena de laboratorios clínicos propia: "el laboratorio" pasa a plural.
