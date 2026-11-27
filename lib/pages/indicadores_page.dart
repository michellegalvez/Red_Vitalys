import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/carga.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/indicadores/barras_por_sede.dart';
import 'package:red_vitalys/widgets/indicadores/estilo_marca.dart';
import 'package:red_vitalys/widgets/indicadores/grafica_tendencia.dart';
import 'package:red_vitalys/widgets/indicadores/resumen_sede.dart';
import 'package:red_vitalys/widgets/indicadores/tabla_mediciones.dart';
import 'package:red_vitalys/widgets/indicadores/tarjeta_indicador.dart';
import 'package:red_vitalys/widgets/indicadores/valores_mensuales.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

// Umbrales de ancho usados para reorganizar las tarjetas sin desbordar la página.
const _anchoDosColumnas = 700.0;
const _anchoCuatroColumnas = 1000.0;
// Estilo común para textos secundarios y aclaraciones de datos.
const _estiloSecundario = TextStyle(
  color: ColoresVitalys.textoSecundario,
  height: 1.4,
  fontSize: 14,
);

// Marca el texto como encabezado también para lectores de pantalla.
Widget _titulo(BuildContext context, String texto) => Semantics(
  header: true,
  child: Text(texto, style: Theme.of(context).textTheme.headlineSmall),
);

/// Tablero de indicadores de calidad (F-08): el valor de la red de cada
/// indicador, su cambio frente al mes previo y, por cada indicador, sus sedes
/// con valor y marca, de la peor a la mejor. Solo muestra y avisa: abrir el
/// detalle lo decide la Screen anfitriona.
class IndicadoresPage extends StatelessWidget {
  const IndicadoresPage({
    super.key,
    required this.resumenes,
    required this.sedesPorIndicador,
    required this.promedios,
    required this.periodo,
    required this.onAbrirDetalle,
    this.simularFallas = false,
    this.cargando = false,
    this.hayError = false,
    this.onReintentar,
  });

  final List<ResumenIndicador> resumenes;

  /// Las sedes de cada indicador, de la peor a la mejor.
  final Map<IdIndicador, List<FilaSede>> sedesPorIndicador;

  /// El valor de la red de cada indicador en [periodo].
  final Map<IdIndicador, double?> promedios;

  /// El último mes cerrado, al que corresponden los valores.
  final DateTime periodo;
  final ValueChanged<IdIndicador> onAbrirDetalle;

  /// El modo de demo *Simular fallas de red*.
  final bool simularFallas;

  /// La carga real de las mediciones desde Supabase.
  final bool cargando;
  final bool hayError;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return ContenidoPagina(
      children: [
        // Presenta el propósito y alcance del tablero antes de los datos.
        const EncabezadoPagina(
          sobretitulo: 'Calidad clínica · toda la red',
          titulo: 'Tablero de indicadores',
          subtitulo:
              'Cuatro indicadores de estructura, proceso y resultado, '
              'calculados con las mediciones de cada sede.',
        ),
        const SizedBox(height: 24),
        // Separa los estados de carga/error reales de los estados simulados de la demo.
        CargaRemota(
          cargando: cargando,
          hayError: hayError,
          onReintentar: onReintentar ?? () {},
          textoCargando: 'Cargando indicadores…',
          textoError: 'No se pudo cargar el tablero',
          child: CargaSimulada(
            simular: simularFallas,
            textoCargando: 'Cargando indicadores…',
            textoError: 'No se pudo cargar el tablero',
            child: _cuerpo(context),
          ),
        ),
      ],
    );
  }

  Widget _cuerpo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calcula cuántas tarjetas caben según el ancho disponible, no el dispositivo.
        LayoutBuilder(
          builder: (context, c) {
            final columnas = c.maxWidth >= _anchoCuatroColumnas
                ? 4
                : (c.maxWidth >= _anchoDosColumnas ? 2 : 1);
            const separacion = 16.0;
            final ancho = (c.maxWidth - separacion * (columnas - 1)) / columnas;
            // Wrap pasa las tarjetas a otra fila cuando la pantalla es angosta.
            return Wrap(
              spacing: separacion,
              runSpacing: separacion,
              children: [
                // Cada resumen reutiliza el componente compartido y abre su detalle.
                for (final r in resumenes)
                  SizedBox(
                    width: ancho,
                    child: TarjetaIndicador(
                      resumen: r,
                      periodo: periodo,
                      onTap: () => onAbrirDetalle(r.indicador.id),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Agrupa la comparación por indicador para señalar dónde priorizar acciones.
        TarjetaVitalys(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo(context, 'Dónde actuar primero'),
              const SizedBox(height: 6),
              Text(
                'Sedes de cada indicador en ${formatoPeriodo(periodo)}, '
                'de la peor a la mejor frente al promedio de la red.',
                style: _estiloSecundario,
              ),
              for (final r in resumenes)
                _BloqueIndicador(
                  indicador: r.indicador,
                  filas: sedesPorIndicador[r.indicador.id] ?? const [],
                  promedio: promedios[r.indicador.id],
                  onAbrirDetalle: onAbrirDetalle,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Las sedes de un indicador, de la peor a la mejor; las que no tienen
/// medición, al final.
class _BloqueIndicador extends StatelessWidget {
  const _BloqueIndicador({
    required this.indicador,
    required this.filas,
    required this.promedio,
    required this.onAbrirDetalle,
  });

  final Indicador indicador;
  final List<FilaSede> filas;
  final double? promedio;
  final ValueChanged<IdIndicador> onAbrirDetalle;

  @override
  Widget build(BuildContext context) {
    final media = promedio == null
        ? mensajeSinMedicion
        : '${formatoValor(promedio!)} ${indicador.unidad}';
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              indicador.nombre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          // Muestra el promedio de la red o explica que todavía no hay mediciones.
          Text(
            'Promedio de la red: $media · '
            '${textoDireccion(indicador.direccion)}',
            style: _estiloSecundario,
          ),
          // La navegación se delega a la Screen anfitriona mediante el callback.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onAbrirDetalle(indicador.id),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Ver detalle'),
              style: TextButton.styleFrom(
                foregroundColor: ColoresVitalys.primario,
                minimumSize: const Size(48, 44),
              ),
            ),
          ),
          // Evita dibujar una comparación vacía como si existieran resultados.
          if (filas.every((f) => f.valor == null))
            const Text(mensajeSinMediciones, style: _estiloSecundario)
          else
            // Adapta cada fila al ancho: dos columnas en pantallas amplias, una en móviles.
            LayoutBuilder(
              builder: (context, c) {
                final ancha = c.maxWidth >= _anchoDosColumnas;
                final ancho = ancha ? (c.maxWidth - 20) / 2 : c.maxWidth;
                return Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    for (final fila in filas)
                      SizedBox(
                        width: ancho,
                        child: ResumenSede(
                          fila: fila,
                          unidad: indicador.unidad,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Detalle de un indicador (F-09, F-10, F-11): la tendencia de la red o de
/// una sede, la comparación entre sedes y las mediciones recientes. Solo
/// muestra y avisa: elegir la sede y volver lo decide la Screen anfitriona.
class DetalleIndicadorPage extends StatelessWidget {
  const DetalleIndicadorPage({
    super.key,
    required this.indicador,
    required this.sedesDisponibles,
    required this.sedeTendencia,
    required this.tendencia,
    required this.comparacion,
    required this.promedio,
    required this.mediciones,
    required this.onElegirSede,
    required this.onVolver,
    this.simularFallas = false,
    this.cargando = false,
    this.hayError = false,
    this.onReintentar,
  });

  final Indicador indicador;

  /// Las sedes a las que aplica el indicador, para el selector.
  final List<Sede> sedesDisponibles;

  /// La sede de la tendencia. `null` es *Toda la red* (F-09).
  final String? sedeTendencia;
  final List<PuntoTendencia> tendencia;
  final List<FilaSede> comparacion;

  /// El valor de la red del último periodo.
  final double? promedio;
  final List<FilaMedicion> mediciones;
  final ValueChanged<String?> onElegirSede;
  final VoidCallback onVolver;

  /// El modo de demo *Simular fallas de red*.
  final bool simularFallas;

  /// La carga real de las mediciones desde Supabase.
  final bool cargando;
  final bool hayError;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return ContenidoPagina(
      children: [
        // Ruta de regreso al tablero; la Screen anfitriona controla la navegación.
        _MigasDePan(nombre: indicador.nombre, onVolver: onVolver),
        const SizedBox(height: 18),
        // Categoría y unidad contextualizan la cifra que se verá en el detalle.
        Text(
          '${indicador.categoria.toUpperCase()} · ${indicador.unidad}',
          style: const TextStyle(
            color: ColoresVitalys.primario,
            fontSize: 12.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(indicador.nombre, style: tema.displaySmall),
        ),
        const SizedBox(height: 12),
        Text(
          indicador.descripcion,
          style: const TextStyle(
            fontSize: 16,
            height: 1.45,
            color: ColoresVitalys.textoSecundario,
          ),
        ),
        const SizedBox(height: 6),
        Text(textoDireccion(indicador.direccion), style: _estiloSecundario),
        const SizedBox(height: 22),
        // Primera sección: evolución mensual de toda la red o de una sede seleccionada.
        TarjetaVitalys(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo(context, 'Tendencia mensual'),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                // El valor null representa "Toda la red"; las opciones provienen del anfitrión.
                child: SelectorVitalys<String?>(
                  valor: sedeTendencia,
                  hint: 'Toda la red',
                  opciones: [
                    (null, 'Toda la red'),
                    for (final s in sedesDisponibles) (s.id, s.nombreCorto),
                  ],
                  onChanged: onElegirSede,
                ),
              ),
              const SizedBox(height: 14),
              // La vista distingue carga real, error y simulación de fallas.
              CargaRemota(
                cargando: cargando,
                hayError: hayError,
                onReintentar: onReintentar ?? () {},
                textoCargando: 'Cargando tendencia…',
                textoError: 'No se pudo cargar la tendencia',
                child: CargaSimulada(
                  simular: simularFallas,
                  textoCargando: 'Cargando tendencia…',
                  textoError: 'No se pudo cargar la tendencia',
                  child: _tendencia(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Segunda sección: permite comparar las sedes con el promedio de la red.
        TarjetaVitalys(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo(context, 'Comparación entre sedes'),
              const SizedBox(height: 7),
              CargaRemota(
                cargando: cargando,
                hayError: hayError,
                onReintentar: onReintentar ?? () {},
                textoCargando: 'Cargando comparación…',
                textoError: 'No se pudo cargar la comparación',
                child: CargaSimulada(
                  simular: simularFallas,
                  textoCargando: 'Cargando comparación…',
                  textoError: 'No se pudo cargar la comparación',
                  child: _comparacion(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Tercera sección: registros recientes y su comparación con el promedio.
        _titulo(context, 'Mediciones recientes'),
        const SizedBox(height: 6),
        CargaRemota(
          cargando: cargando,
          hayError: hayError,
          onReintentar: onReintentar ?? () {},
          textoCargando: 'Cargando mediciones…',
          textoError: 'No se pudieron cargar las mediciones',
          child: CargaSimulada(
            simular: simularFallas,
            textoCargando: 'Cargando mediciones…',
            textoError: 'No se pudieron cargar las mediciones',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediciones.length == 1
                      ? '1 medición'
                      : '${mediciones.length} mediciones',
                  style: _estiloSecundario,
                ),
                const SizedBox(height: 10),
                TablaMediciones(indicador: indicador, filas: mediciones),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// El último periodo cerrado y su valor; sin medición ese mes lo dice, y no
  /// muestra el de un mes anterior (F-09).
  String get _textoUltimoPeriodo {
    // Si no hay valores en la ventana visible, no se presenta un dato antiguo como actual.
    if (tendencia.isEmpty || tendencia.every((p) => p.valor == null)) {
      return 'Sin mediciones en los últimos $mesesVisibles meses';
    }
    // Se inspecciona el último mes de la serie aunque su valor pueda ser nulo.
    final ultimo = tendencia.last;
    final valor = ultimo.valor;
    final periodoUltimo = formatoPeriodo(ultimo.periodo);
    return valor == null
        ? 'Sin medición en $periodoUltimo'
        : 'Último periodo: ${formatoValor(valor)} ${indicador.unidad} '
              '($periodoUltimo)';
  }

  Widget _tendencia() {
    // La gráfica solo aparece cuando existe al menos un punto medido.
    final hayDato = tendencia.any((p) => p.valor != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_textoUltimoPeriodo, style: _estiloSecundario),
        const SizedBox(height: 14),
        if (!hayDato)
          // Estado vacío explícito: no inventa ni interpola mediciones faltantes.
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No hay mediciones en los últimos 6 meses',
              style: _estiloSecundario,
            ),
          )
        else ...[
          // Dibuja la serie temporal y sus etiquetas; el widget reutilizable hace la gráfica.
          SizedBox(
            height: 205,
            width: double.infinity,
            child: GraficaTendencia(
              valores: [for (final p in tendencia) p.valor],
              rotulos: [for (final p in tendencia) mesCorto(p.periodo)],
              unidad: indicador.unidad,
              relleno: true,
            ),
          ),
          const SizedBox(height: 12),
          // Expone los valores mensuales como texto además de la visualización gráfica.
          ValoresMensuales(puntos: tendencia, unidad: indicador.unidad),
        ],
      ],
    );
  }

  Widget _comparacion() {
    // Solo se compara cuando hay al menos una sede con dato en el periodo.
    final hayComparables = comparacion.any((f) => f.valor != null);
    final periodoTexto = tendencia.isEmpty
        ? 'Último periodo'
        : formatoPeriodo(tendencia.last.periodo);
    final media = promedio == null
        ? mensajeSinMedicion
        : '${formatoValor(promedio!)} ${indicador.unidad}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El título muestra periodo y promedio para que la línea de referencia tenga contexto.
        Text(
          '$periodoTexto · Promedio de la red: $media',
          style: _estiloSecundario,
        ),
        const SizedBox(height: 4),
        const Text(
          'La línea punteada marca el promedio de la red.',
          style: _estiloSecundario,
        ),
        const SizedBox(height: 14),
        if (!hayComparables)
          // No presenta barras vacías como una comparación válida.
          const Text(
            'No hay mediciones en el último periodo',
            style: _estiloSecundario,
          )
        else ...[
          // Las barras y la leyenda explican la posición de cada sede frente a la red.
          BarrasPorSede(
            filas: comparacion,
            promedio: promedio,
            unidad: indicador.unidad,
            compacta: true,
          ),
          const SizedBox(height: 14),
          const LeyendaDesempeno(),
        ],
      ],
    );
  }
}

/// "Indicadores / Nombre": vuelve al tablero desde el detalle.
class _MigasDePan extends StatelessWidget {
  const _MigasDePan({required this.nombre, required this.onVolver});

  final String nombre;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onVolver,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 17,
                    color: ColoresVitalys.textoSecundario,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Indicadores',
                    style: TextStyle(
                      color: ColoresVitalys.textoSecundario,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '/',
            style: TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ),
        Expanded(
          child: Text(
            nombre,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ),
      ],
    );
  }
}
