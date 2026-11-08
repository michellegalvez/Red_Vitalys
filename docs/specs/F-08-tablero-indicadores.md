---
id: F-08
titulo: Tablero de indicadores
version: 0.1.6
fecha: 2026-11-08
estado: borrador
autores: [Gabriela Cardona Bernal, Juan Diego Valverde Fierro, Jazmin Michelle Galvez Orozco, Samuel Cardoso Martinez]
requisitos: [RF-08, RF-09, RF-26, RF-27]
depende_de: [F-13]
---

# F-08 · Tablero de indicadores

## Objetivo

Los tres roles ven los 4 indicadores de calidad con su valor del último periodo, su cambio frente al periodo anterior y cada sede marcada como mejor, peor o igual al promedio de la red (O-03).

## Flujo principal

1. El usuario entra al *Tablero de indicadores*.
2. El sistema muestra los 4 indicadores. De cada uno se ve el valor de la red en el último periodo, que es el promedio de las sedes, y su cambio frente al periodo anterior.
3. Por cada indicador el sistema muestra las sedes a las que aplica, de la peor a la mejor, con su valor del último periodo y su marca: *Mejor que el promedio*, *Peor que el promedio* o *Igual al promedio*.
4. El usuario elige un indicador y el sistema muestra su detalle (F-09, F-10, F-11).

## Flujos alternos

- **A1 · Sede sin medición:** si una sede no tiene medición en el último periodo, se ve *Sin medición* en lugar de su valor y no entra en el promedio de la red.
- **A2 · Sin periodo anterior:** si no hay un periodo anterior, el cambio dice "Sin periodo anterior".
- **A3 · Indicador sin mediciones:** si ninguna sede tiene medición, se ve "Sin mediciones" en ese indicador.

## Reglas

- Los 3 roles ven el tablero. Verlo no crea un evento de acceso.
- El último periodo es el mes cerrado más reciente. Con la fecha de hoy de los datos simulados, el 6 de noviembre de 2026 (RNF-04), es octubre de 2026.
- Cada indicador tiene unidad y dirección según la tabla de los requisitos:

| Indicador | Unidad | Es mejor un valor | Aplica en |
|---|---|---|---|
| Reingreso hospitalario a 30 días | % | más bajo | clínicas |
| Tiempo de espera promedio | min | más bajo | clínicas y centros ambulatorios |
| Adherencia a protocolos clínicos | % | más alto | clínicas y centros ambulatorios |
| Eventos adversos evitables | por cada 1.000 atenciones | más bajo | clínicas y centros ambulatorios |

- Una sede solo aparece en los indicadores que le aplican. Los laboratorios no aparecen en ninguno.
- El valor de la red es el promedio simple de las sedes con medición en ese periodo.
- La marca compara el valor de la sede con el de la red, ambos redondeados a 1 decimal. Si son iguales, la marca es *Igual al promedio*.
- Cada indicador pertenece a una categoría: *Resultado* el reingreso y los eventos adversos, *Estructura* el tiempo de espera y *Proceso* la adherencia.
- Las sedes de cada indicador van de la peor a la mejor: del valor más alto al más bajo cuando es mejor un valor bajo, y al revés cuando es mejor uno alto. Las sedes sin medición van al final. Dos sedes con el mismo valor se ordenan por nombre (F-10).
- Junto al cambio se ve *Mejora* si va hacia lo mejor según la dirección del indicador, *Empeora* si va hacia lo peor y *Sin cambio* si es cero. Con cambio cero se ve "0,0" sin signo.
- El cambio es la diferencia entre los valores de la red redondeados a 1 decimal, en la unidad del indicador: "−1,2 puntos" en porcentajes, "+5 min" en el tiempo de espera y "+0,3 por 1.000" en los eventos adversos. Con signo "+" cuando sube y "−" cuando baja.
- Las reglas de dirección y de cálculo están en un único lugar (AD-11).
- Los datos son simulados.

## Estados

- **Cargando:** se ve "Cargando indicadores…".
- **Vacío:** el mensaje de A3 en cada indicador sin mediciones.
- **Error:** si el tablero no se puede cargar, se ve "No se pudo cargar el tablero" con la opción *Reintentar*.

## Datos

- Por indicador: **nombre**, **categoría**, **unidad**, **valor de la red** del último periodo y **cambio** frente al periodo anterior, con su marca *Mejora*, *Empeora* o *Sin cambio*.
- Por sede: **nombre**, **valor** del último periodo o *Sin medición*, y **marca**.
- **Periodo** que se muestra, por ejemplo "oct 2026".

## Criterios de aceptación

- **CA-1** Dado cualquiera de los 3 roles, cuando abre el tablero, entonces ve los 4 indicadores, cada uno con el valor de la red del último periodo, su cambio y las sedes con su marca.
- **CA-2** Dado el reingreso con 8,0 % en la red y 9,5 % en una sede, cuando el usuario abre el tablero, entonces esa sede aparece como *Peor que el promedio*.
- **CA-3** Dada la adherencia con 88,0 % en la red y 92,0 % en una sede, cuando el usuario abre el tablero, entonces esa sede aparece como *Mejor que el promedio*.
- **CA-4** Dado el reingreso con 8,04 % de promedio en la red y 8,0 % en una sede, cuando el usuario abre el tablero, entonces esa sede aparece como *Igual al promedio*.
- **CA-5** Dada una sede sin medición en octubre, cuando el usuario abre el tablero, entonces ve *Sin medición* en esa sede y el promedio de la red se calcula sin ella.
- **CA-6** Dado el tiempo de espera de la red en 32 min en septiembre y 37 min en octubre, cuando el usuario abre el tablero, entonces ve el cambio "+5 min".
- **CA-7** Dado un indicador sin periodo anterior, cuando el usuario abre el tablero, entonces el cambio dice "Sin periodo anterior".
- **CA-8** Dado un centro ambulatorio y un laboratorio, cuando el usuario abre el tablero, entonces el centro no aparece en el reingreso y el laboratorio no aparece en ningún indicador.
- **CA-9** Dado que el tablero no se puede cargar, cuando el usuario lo abre, entonces ve "No se pudo cargar el tablero" y, al elegir *Reintentar*, el sistema lo carga otra vez.
- **CA-10** Dados los datos simulados, cuando el usuario abre el tablero, entonces se muestra en menos de 2 segundos (RNF-06).
- **CA-11** Dados los datos simulados, cuando el usuario abre el tablero, entonces cada indicador tiene mediciones de los últimos 6 meses en las sedes que le aplican, salvo una sede de prueba sin medición en el último periodo (RNF-04).
- **CA-12** Dado el tiempo de espera de la red en 32 min en septiembre y 37 min en octubre, cuando el usuario abre el tablero, entonces ve "+5 min" con la marca *Empeora*.
- **CA-13** Dado un indicador sin cambio frente al periodo anterior, cuando el usuario abre el tablero, entonces ve "0,0" con la marca *Sin cambio*.
- **CA-14** Dado el reingreso con sedes en 6,0 %, 8,0 % y 10,0 %, cuando el usuario abre el tablero, entonces ve primero la de 10,0 % y al final la de 6,0 %.

## Fuera de alcance

- La tendencia, la comparación y las mediciones recientes del detalle (F-09, F-10, F-11).
- Registrar mediciones, que es F-12.
- Metas o umbrales propios por sede.
- Exportar el tablero.

## Preguntas abiertas

Ninguna.

## Historial

- 0.1.0 · 2026-11-06 · Primera versión.
- 0.1.1 · 2026-11-06 · Se quita la posición "debajo" del flujo principal y el último periodo se liga a la fecha de hoy fija de RNF-04.
- 0.1.2 · 2026-11-06 · La pantalla inicial de cada rol queda en F-13, y se aprueban los textos de los estados. Se cierran 2 preguntas abiertas.
- 0.1.3 · 2026-11-06 · La red tiene una cadena de laboratorios clínicos propia: "el laboratorio" pasa a plural.
- 0.1.4 · 2026-11-08 · Se definen el orden de las sedes (de la peor a la mejor), la categoría de cada indicador, la marca Mejora/Empeora/Sin cambio, el cambio con valores redondeados y el cero (CA-12 a CA-14). CA-4 usa un valor posible: una sede tiene 1 decimal. Se cierra la pregunta abierta de la unidad.
- 0.1.5 · 2026-11-08 · La regla no nombra un rango que la tabla no tiene, y el desempate de las sedes es el de F-10.
- 0.1.6 · 2026-11-08 · CA-11 admite la sede de prueba sin medición que piden CA-5 y A1.
