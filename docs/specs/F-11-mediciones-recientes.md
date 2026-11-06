---
id: F-11
titulo: Mediciones recientes de un indicador
version: 0.1.1
fecha: 2026-11-06
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-12]
depende_de: [F-08]
---

# F-11 · Mediciones recientes de un indicador

## Objetivo

El usuario revisa las mediciones registradas de un indicador, con la sede, el periodo y el valor, y ve si cada una estuvo mejor, peor o igual que el promedio de la red en su periodo (O-03).

## Flujo principal

1. El usuario abre el detalle de un indicador desde el tablero (F-08).
2. El sistema muestra las mediciones de los últimos 6 periodos, de la más reciente a la más antigua.
3. Cada medición muestra la sede, el periodo, el valor y su marca: *Mejor que el promedio*, *Peor que el promedio* o *Igual al promedio*.
4. El sistema muestra el contador de mediciones, por ejemplo "42 mediciones".

## Flujos alternos

- **A1 · Sin mediciones:** se ve "No hay mediciones en los últimos 6 meses" y el contador dice "0 mediciones".
- **A2 · Medición nueva:** cuando un administrativo registra una medición (F-12), aparece en esta lista.

## Reglas

- Lo ven los 3 roles. Verlas no crea un evento de acceso.
- Son las mediciones de los últimos 6 meses cerrados. Dentro de un mismo periodo, las sedes van ordenadas por nombre.
- La marca de cada medición compara su valor con el promedio de la red de ese mismo periodo, con las reglas de F-08.
- Solo aparecen las sedes a las que el indicador aplica.
- No hay paginación: se muestran todas.
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando mediciones…".
- **Vacío:** el mensaje de A1.
- **Error:** si no se pueden cargar, se ve "No se pudieron cargar las mediciones" con la opción *Reintentar*.

## Datos

- Por medición: **sede**, **periodo**, por ejemplo "oct 2026", **valor** con su unidad y **marca**.
- **Contador** de mediciones.

## Criterios de aceptación

- **CA-1** Dado un usuario en el detalle del reingreso, cuando lo abre, entonces ve las mediciones de las clínicas de los últimos 6 meses, de la más reciente a la más antigua, y el contador.
- **CA-2** Dada una medición de una sede de 9,5 % en un periodo en que la red tuvo 8,0 %, cuando el usuario la ve, entonces aparece como *Peor que el promedio*.
- **CA-3** Dadas 2 mediciones del mismo periodo, cuando el usuario ve la lista, entonces van ordenadas por el nombre de la sede.
- **CA-4** Dado un administrativo que registró una medición de octubre, cuando abre las mediciones recientes de ese indicador, entonces la ve en la lista.
- **CA-5** Dado un indicador sin mediciones en los últimos 6 meses, cuando el usuario lo abre, entonces ve "No hay mediciones en los últimos 6 meses" y el contador dice "0 mediciones".
- **CA-6** Dado que las mediciones no se pueden cargar, cuando el usuario abre el detalle, entonces ve "No se pudieron cargar las mediciones" y, al elegir *Reintentar*, el sistema las carga otra vez.

## Fuera de alcance

- Registrar mediciones, que es F-12.
- Corregir o borrar una medición ya registrada.
- Filtrar por sede o por periodo.

## Preguntas abiertas

- ¿"Recientes" son los últimos 6 meses? Es una propuesta para ir con la tendencia (F-09).
- ¿Cada medición debe mostrar quién la registró y cuándo?

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Se aprueban los textos de los estados como definitivos. Se cierra esa pregunta abierta.
