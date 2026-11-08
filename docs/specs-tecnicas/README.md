# Specs técnicas · Red Vitalys

Actualizado: 2026-11-07

Estas specs describen cómo implementar las dos pantallas de indicadores enviadas como referencia. Complementan —no reemplazan— las specs funcionales. No se implementa ni modifica código como parte de este documento.

| ID | Pantalla | Requisitos funcionales | Specs funcionales |
|---|---|---|---|
| T-01 | Tablero de indicadores | RF-08, RF-09, RF-26, RF-27 | F-08 |
| T-02 | Detalle de un indicador | RF-10, RF-11, RF-12 | F-09, F-10, F-11 |

RF-13 (registro de mediciones) corresponde a F-12 y no aparece en las pantallas entregadas; queda fuera de estas specs.

## Decisiones técnicas compartidas

- Flutter y Dart, con componentes y navegación nativos. No agregar paquetes de estado, navegación o gráficas.
- Cada pantalla obtiene datos mediante un servicio; solo el repositorio consulta la fuente, siguiendo AD-02 y AD-03.
- Una única definición de indicadores y un único servicio aplican las reglas de cálculo de AD-11 para el tablero y el detalle.
- En la entrega 2 la fuente es el conjunto compartido de datos simulados en memoria. Las cifras de los PDF son referencias visuales y no deben convertirse en fixtures independientes ni quedar codificadas en las pantallas.
- Las specs funcionales son la autoridad para las reglas y etiquetas. Si un texto del PDF difiere de una spec o requisito, prevalecen estos últimos.
- En el detalle, la tabla puede desplazarse horizontalmente dentro de su propia región, como confirmó el equipo. La página completa no debe desbordarse horizontalmente en 360 px (RNF-07).

## Referencias

- Diseño del tablero: `Body.pdf`.
- Diseño del detalle del reingreso: `Body (1).pdf`.
- Requisitos: `docs/requisitos.md` 0.7.2.
- Arquitectura: `docs/architectural_spine.md` 0.6.5.
