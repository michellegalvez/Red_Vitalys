---
id: T-02
titulo: Implementación técnica del detalle de un indicador
version: 0.1.0
fecha: 2026-11-07
estado: borrador
requisitos: [RF-10, RF-11, RF-12]
specs_funcionales: [F-09, F-10, F-11]
depende_de: [T-01]
---

# T-02 · Implementación técnica del detalle de un indicador

## Propósito y alcance

Especifica la pantalla reutilizable de detalle de indicador representada por el caso de reingreso en el diseño de referencia `Body (1).pdf` (externo, no está en el repositorio). Cubre RF-10, RF-11 y RF-12: tendencia mensual, comparación del último periodo y mediciones recientes. El mismo componente debe funcionar para los cuatro indicadores, según su definición y tipo de sede aplicable.

## Estructura propuesta

Reutilizar los modelos, los datos simulados, las reglas y los formateadores definidos en T-01 (`lib/modelos/indicadores.dart`, `lib/datos/indicadores_simulados.dart`, `lib/reglas/indicadores.dart`, `lib/formato/formato.dart`). El detalle vive en `lib/pages/indicadores_page.dart`, con el estado de selección en `lib/screens/app_screen.dart`. Los componentes están en `lib/widgets/indicadores/`:

- sección de tendencia: selector y gráfico de tendencia.
- sección de comparación entre sedes: orden y barras de comparación.
- tabla de mediciones recientes: tabla desplazable localmente.

Al entrar desde el tablero se consulta al servicio por identificador. No duplicar reglas, mediciones de ejemplo ni cálculos dentro de la pantalla. Las sedes disponibles se obtienen de la definición del indicador; los laboratorios quedan excluidos.

## Contrato de entrada y resultados

Entrada:

- Identificador estable del indicador.
- Periodo cerrado más reciente según la fecha de datos simulados.

El mismo servicio ofrece una operación por sección para cargar su resultado:

- definición y unidad del indicador;
- serie mensual de la red y series por sede;
- promedio de referencia y comparaciones de sede para el último periodo;
- mediciones de los seis periodos cerrados con su clasificación frente al promedio de su propio periodo.

Cada operación consulta el mismo repositorio y aplica los mismos cálculos compartidos. Los valores ausentes se representan como ausencia explícita, no como `0`. La pantalla carga cada sección por separado para que un error en una no oculte las otras.

## Tendencia mensual · RF-10

- Iniciar con «Toda la red» seleccionada.
- Ofrecer «Toda la red» y solo las sedes a las que aplica el indicador.
- Mostrar los seis últimos meses cerrados en orden cronológico ascendente. Con la fecha fija del proyecto: mayo a octubre de 2026.
- En «Toda la red», calcular por mes el promedio simple de las sedes con medición; si una sede seleccionada no tiene un valor en un mes, presentar «Sin medición» y no dibujar un punto como si fuera cero.
- Al cambiar la selección, actualizar la serie desde el resultado del servicio sin cambiar indicador ni rango temporal.
- Mostrar la unidad y los nombres abreviados de los meses en español.
- Dibujar la serie con `CustomPainter`; el painter recibe los puntos de la serie y los límites/ejes que prepare la capa de presentación, no obtiene datos ni calcula promedios.
- Si no hay mediciones en los seis periodos, mostrar «No hay mediciones en los últimos 6 meses».

## Comparación entre sedes · RF-11

- Comparar el último periodo cerrado y mostrar el promedio de red como referencia con línea punteada.
- Incluir las sedes aplicables; las que no tienen medición aparecen al final como «Sin medición» y no entran en el promedio.
- Ordenar de mejor a peor según la dirección del indicador; para valores iguales, ordenar por nombre de sede. Aplicar el mismo resultado de clasificación y redondeo que T-01.
- Mostrar nombre, valor con unidad y marca textual. Color e icono son apoyos, no sustituyen «Mejor que el promedio», «Peor que el promedio» o «Igual al promedio».
- Para la adherencia, invertir el sentido de la escala visual respecto a los indicadores donde menor es mejor, sin cambiar sus valores.
- Si ninguna sede tiene medición en el periodo, mostrar «No hay mediciones en el último periodo».

## Mediciones recientes · RF-12

- Mostrar mediciones de los últimos seis meses cerrados, del periodo más reciente al más antiguo.
- Dentro de un periodo, ordenar por nombre de sede.
- Cada fila presenta sede, periodo, valor con unidad y marca frente al promedio de red de ese mismo periodo.
- Mostrar el contador; si la colección está vacía, mostrar «No hay mediciones en los últimos 6 meses» y «0 mediciones».
- En ancho móvil, conservar las columnas y permitir desplazamiento horizontal solo en el viewport de la tabla, como en el diseño de referencia y confirmado por el equipo. El scroll vertical pertenece a la página; la tabla no puede ensanchar el viewport ni provocar overflow horizontal global.
- En ancho de computador, mostrar las columnas dentro del ancho disponible sin recorte. Mantener encabezados visibles y asociar cada valor a su encabezado para lectura accesible.

## Composición y adaptación

Mantener el orden del diseño de referencia:

1. Encabezado de la app y breadcrumb desde Indicadores.
2. Categoría, unidad, nombre y descripción del indicador.
3. Panel de tendencia con último valor y selector de ámbito.
4. Panel de comparación con promedio de referencia.
5. Tabla de mediciones recientes.
6. Navegación inferior compartida, con Indicadores como sección actual.

A 360 px, apilar paneles, permitir scroll vertical y limitar el desplazamiento horizontal a la tabla. A 1280 px, aprovechar el espacio disponible manteniendo la tendencia, comparación y tabla legibles. Usar restricciones responsivas, no anchos fijos basados en la captura.

## Estados y errores

Cada sección debe representar el ciclo de su operación del servicio sin confundir error con colección vacía:

- Carga de tendencia: «Cargando tendencia…»; error: «No se pudo cargar la tendencia» y reintento; vacío: mensaje de los últimos seis meses.
- Carga de comparación: «Cargando comparación…»; error: «No se pudo cargar la comparación» y reintento; vacío: mensaje del último periodo.
- Carga de mediciones: «Cargando mediciones…»; error: «No se pudieron cargar las mediciones» y reintento; vacío: mensaje de los últimos seis meses y contador en cero.

Conservar los demás paneles si falla una sección independiente. Propagar y mostrar errores del servicio explícitamente.

## Navegación

El tablero abre el detalle enviando el identificador de indicador. El detalle conserva ese identificador durante los cambios de sede de la tendencia. La acción de volver retorna al tablero con el mismo origen; no reconstruir el indicador a partir del título visible.

## Verificación técnica

- Pruebas unitarias para rango/orden de periodos, promedio mensual, ausencia de valores, elegibilidad de sedes, marcas por dirección, orden de comparación, desempate por nombre y clasificación de mediciones frente a su propio periodo.
- Pruebas de widget para el selector inicial «Toda la red», cambio de sede, mensajes vacíos/errores, contador y desplazamiento horizontal localizado en la tabla.
- Pruebas con 360 px que confirmen que solo la tabla desplaza horizontalmente, y con 1280 px que confirmen que sus columnas caben.
- Criterios funcionales de referencia: F-09 CA-1 a CA-7, F-10 CA-1 a CA-8 y F-11 CA-1 a CA-6.

## Fuera de alcance

- Registrar, editar o borrar mediciones.
- Elegir periodos fuera de los seis últimos meses, comparar varios indicadores o sedes en una misma tendencia, ni exportar datos.
- La definición final de colores, tipografía, iconografía, radios, sombras y escalas visuales; corresponde a la etapa de diseño visual.

## Preguntas abiertas

- Ninguna para el comportamiento técnico descrito. El desplazamiento horizontal queda limitado a la tabla en móvil, según decisión del equipo y la referencia entregada.

## Historial

- 0.1.0 · 2026-11-07 · Primera versión técnica basada en F-09, F-10, F-11, los requisitos y el diseño de referencia `Body (1).pdf` (externo).
