---
id: F-10
titulo: Comparación entre sedes de un indicador
version: 0.1.3
fecha: 2026-11-08
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-11]
depende_de: [F-08]
---

# F-10 · Comparación entre sedes de un indicador

## Objetivo

El usuario compara las sedes en un indicador, en el último periodo, con el promedio de la red como referencia (O-03).

## Flujo principal

1. El usuario abre el detalle de un indicador desde el tablero (F-08).
2. El sistema muestra el promedio de la red del último periodo como referencia.
3. El sistema muestra todas las sedes a las que aplica el indicador, con su valor del último periodo y su marca: *Mejor que el promedio*, *Peor que el promedio* o *Igual al promedio*.
4. Las sedes van de la peor a la mejor según la dirección del indicador.

## Flujos alternos

- **A1 · Sede sin medición:** va al final con *Sin medición* y no entra en el promedio.
- **A2 · Sin mediciones:** si ninguna sede tiene medición en el último periodo, se ve "No hay mediciones en el último periodo".

## Reglas

- Lo ven los 3 roles. Verla no crea un evento de acceso.
- Las sedes se ordenan de la peor a la mejor según la dirección del indicador: del valor más alto al más bajo cuando es mejor un valor bajo, y al revés cuando es mejor uno alto. Dos sedes con el mismo valor se ordenan por nombre.
- El promedio, la marca y los redondeos son los de F-08 y se calculan en un único lugar (AD-11).
- Solo aparecen las sedes a las que el indicador aplica.
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando comparación…".
- **Vacío:** el mensaje de A2.
- **Error:** si no se puede cargar, se ve "No se pudo cargar la comparación" con la opción *Reintentar*.

## Datos

- **Indicador**, su unidad y el **periodo**.
- **Promedio de la red.**
- Por sede: **nombre**, **valor** o *Sin medición*, y **marca**.

## Criterios de aceptación

- **CA-1** Dado el detalle del tiempo de espera, cuando el usuario lo abre, entonces ve el promedio de la red del último periodo y todas las clínicas y centros ambulatorios con su valor y su marca.
- **CA-2** Dado el reingreso con sedes en 6,0 %, 8,0 % y 10,0 %, cuando el usuario abre la comparación, entonces ve primero la de 10,0 % y al final la de 6,0 %.
- **CA-3** Dada la adherencia con sedes en 85 %, 90 % y 95 %, cuando el usuario abre la comparación, entonces ve primero la de 85 % y al final la de 95 %.
- **CA-4** Dada una sede sin medición en el último periodo, cuando el usuario abre la comparación, entonces esa sede aparece al final con *Sin medición*.
- **CA-5** Dado el reingreso, cuando el usuario abre la comparación, entonces no ve centros ambulatorios ni laboratorios.
- **CA-6** Dado un indicador sin mediciones, cuando el usuario abre la comparación, entonces ve "No hay mediciones en el último periodo".
- **CA-7** Dado que la comparación no se puede cargar, cuando el usuario abre el detalle, entonces ve "No se pudo cargar la comparación" y, al elegir *Reintentar*, el sistema la carga otra vez.
- **CA-8** Dada una sede marcada como *Peor que el promedio* en el tablero, cuando el usuario ve la comparación del mismo indicador, entonces la ve también como *Peor que el promedio*.

## Fuera de alcance

- La tendencia y las mediciones recientes (F-09, F-11).
- Comparar periodos distintos.
- Exportar la comparación.

## Preguntas abiertas

- ¿La comparación se puede hacer de un periodo anterior o solo del último?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
- 0.1.2 · 2026-11-06 · La red tiene una cadena de laboratorios clínicos propia: "el laboratorio" pasa a plural.
- 0.1.3 · 2026-11-08 · Las sedes van de la peor a la mejor, como en el Figma y en el tablero (F-08); cambian el flujo, la regla de orden, CA-2 y CA-3.
