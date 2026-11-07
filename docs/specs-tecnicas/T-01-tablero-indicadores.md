---
id: T-01
titulo: Implementación técnica del tablero de indicadores
version: 0.1.0
fecha: 2026-11-07
estado: borrador
requisitos: [RF-08, RF-09, RF-26, RF-27]
specs_funcionales: [F-08]
depende_de: []
---

# T-01 · Implementación técnica del tablero de indicadores

## Propósito y alcance

Especifica la estructura de datos, el cálculo y la composición Flutter del tablero representado en `Body.pdf`. Cubre RF-08, RF-09, RF-26 y RF-27. No cubre el registro de mediciones (RF-13), la autenticación, ni la implementación de la pantalla de detalle, que se define en T-02.

## Estructura propuesta

Organizar el código bajo `lib/features/indicators/`:

- `models/`: definiciones de indicador, medición, periodo y resultados de resumen/comparación.
- `data/`: contrato del repositorio y su implementación en memoria para la entrega 2.
- `services/`: servicio de indicadores con los cálculos compartidos.
- `screens/indicators_dashboard_screen.dart`: pantalla anfitriona y estado local.
- `widgets/`: tarjetas de resumen, lista de desempeño por sede y gráficos.

La pantalla llama al servicio; el servicio consulta el repositorio. La selección de la fuente de datos se mantiene en un solo punto de composición de la app (AD-02, AD-03). No se consulta el repositorio ni se recalculan promedios desde widgets.

## Contrato de datos

- `IndicatorDefinition`: identificador estable, nombre, categoría, unidad, dirección de mejora y tipos de sede aplicables.
- `Measurement`: identificadores de indicador y sede, periodo mensual y valor numérico.
- `IndicatorDashboardItem`: indicador, periodo actual y previo, promedios de red disponibles, diferencia, serie mensual de seis puntos y valores/marcas por sede.
- `SiteIndicatorResult`: sede, valor disponible o ausencia de medición y clasificación calculada.

La pantalla recibe una lista ordenada de cuatro `IndicatorDashboardItem`; no contiene reglas particulares para cada indicador.

## Cálculos y orden

1. Usar el último mes cerrado. Con la fecha simulada de RNF-04 (6 nov 2026), el periodo actual es octubre de 2026 y el anterior es septiembre de 2026.
2. Para cada indicador y periodo, incluir solo sedes a las que aplica y que tengan medición. Calcular el promedio aritmético simple; una sede sin medición no aporta un cero ni entra en el divisor.
3. Calcular el cambio restando el promedio del periodo anterior al promedio actual. Si falta el promedio previo, devolver el estado «Sin periodo anterior», no cero.
4. Clasificar una sede comparando su valor y el promedio de red después de redondear ambos a un decimal. Aplicar la dirección de mejora de la definición: menor es mejor para reingreso, espera y eventos adversos; mayor es mejor para adherencia. Si coinciden, clasificar como «Igual al promedio».
5. Si un indicador no tiene mediciones para el periodo, devolver un estado vacío explícito; no fabricar promedio, cambio ni clasificaciones.
6. La lista «Dónde actuar primero» corresponde al reingreso y ordena las sedes de peor a mejor. La lista y el gráfico de barras consumen la misma colección calculada.

El formateador compartido presenta decimales con coma, unidad y signo. El cambio usa diferencia en la unidad del indicador («−1,2 puntos», «+5 min», «+0,3 por 1.000»), según F-08 y AD-12.

## Composición de la pantalla

Mantener el orden de lectura de `Body.pdf`:

1. Encabezado de la app y contexto «Calidad clínica · Toda la red».
2. Título y descripción del tablero.
3. Cuatro tarjetas, una por indicador, con categoría, nombre, promedio del último periodo, tendencia compacta de los seis periodos y cambio textual frente al periodo previo.
4. Sección «Dónde actuar primero», con promedio de referencia y resultados de reingreso por sede.
5. Gráfico horizontal comparativo de reingreso por sede, con la línea del promedio y una leyenda de mejor/igual/peor.
6. Navegación inferior compartida de la app, con Indicadores como sección actual.

La tarjeta, la lista y el gráfico no guardan estado de cálculo propio. Si el usuario abre el detalle desde un indicador, pasar su identificador estable a T-02; no pasar valores de presentación como fuente de verdad.

## Gráficos y presentación adaptable

- Dibujar las tendencias compactas y las barras con `CustomPainter` de Flutter; no incorporar un paquete de gráficas. El painter recibe puntos ya calculados y no calcula métricas.
- Las líneas, barras, promedio, etiquetas y estados deben tener alternativa textual visible; el color nunca es la única señal.
- A 360 px, ordenar las tarjetas y secciones verticalmente, permitir que nombres largos de sedes ocupen más de una línea y evitar desbordamiento horizontal de la página.
- En 1280 px, usar el espacio disponible para distribuir tarjetas y secciones sin estirar las líneas de texto ni perder la relación entre etiquetas, valores y marcas.
- Implementar adaptación con restricciones de ancho (`LayoutBuilder`/`ConstrainedBox`) y scroll vertical de página. No fijar un ancho mínimo superior al viewport.
- «Igual al promedio» es la clasificación normativa. La leyenda del PDF dice «Cerca del promedio»; no crear una cuarta categoría ni cambiar la regla de RF-09.

## Estados y errores

- `loading`: mostrar «Cargando indicadores…».
- `data`: mostrar tarjetas y secciones con resultados.
- `empty` por indicador: mostrar «Sin mediciones» donde ninguna sede tenga valor; mantener las demás tarjetas disponibles.
- `error`: mostrar «No se pudo cargar el tablero» y habilitar reintento. El error no se sustituye por datos vacíos ni por ceros.

Representar estos estados explícitamente en el estado local de la pantalla anfitriona. El servicio debe propagar el error al estado; no usar capturas silenciosas.

## Verificación técnica

- Pruebas unitarias del servicio para promedio simple excluyendo sedes sin medición, promedio ausente, diferencia con/sin periodo previo, redondeo antes de clasificar y dirección distinta de adherencia.
- Pruebas de widget para cuatro indicadores, estados de carga/vacío/error, y coincidencia de las marcas entre la lista y el gráfico.
- Prueba de layout a 360 px y 1280 px, verificando ausencia de overflow horizontal de la página.
- Criterios funcionales de referencia: F-08 CA-1 a CA-11. El tiempo de RNF-06 se valida con el conjunto de datos simulado requerido por RNF-04.

## Fuera de alcance

- Registrar, editar o eliminar mediciones.
- Agregar permisos, filtros por sede o periodo, metas por sede o exportación.
- Definir el estilo final de marca, tipografía, colores y elevaciones; eso corresponde a la etapa de diseño visual.

## Preguntas abiertas

- Ninguna para esta especificación. La etiqueta de igualdad se resuelve según RF-09 aunque el PDF use «Cerca del promedio».

## Historial

- 0.1.0 · 2026-11-07 · Primera versión técnica basada en F-08, los requisitos y `Body.pdf`.
