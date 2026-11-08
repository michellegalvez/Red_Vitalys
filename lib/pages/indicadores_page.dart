import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/formularios.dart';

const _ink = ColoresVitalys.tinta;
const _muted = ColoresVitalys.textoSecundario;
const _purple = ColoresVitalys.primario;
const _mint = ColoresVitalys.verdeLima;
const _green = ColoresVitalys.mentaTexto;
const _greenPale = ColoresVitalys.exitoFondo;
const _red = ColoresVitalys.alerta;
const _redPale = ColoresVitalys.alertaFondo;
const _line = ColoresVitalys.borde;
const _gray = Color(0xFFB8B8CF);
const _grayPale = Color(0xFFF2F2FA);

/// Tablero de indicadores de calidad (F-08): el valor de la red de cada
/// indicador, su cambio frente al mes previo y las sedes donde actuar primero.
/// Solo muestra y avisa: abrir el detalle lo decide la Screen anfitriona.
class IndicadoresPage extends StatelessWidget {
  const IndicadoresPage({
    super.key,
    required this.resumenes,
    required this.destacado,
    required this.comparacionDestacada,
    required this.promedioDestacado,
    required this.onAbrirDetalle,
  });

  final List<ResumenIndicador> resumenes;

  /// El indicador que se explica abajo, con las sedes frente al promedio.
  final Indicador destacado;

  /// Las sedes del indicador destacado, de la mejor a la peor.
  final List<FilaSede> comparacionDestacada;
  final double? promedioDestacado;
  final ValueChanged<IdIndicador> onAbrirDetalle;

  @override
  Widget build(BuildContext context) {
    final dePeorAMejor = comparacionDestacada.reversed.toList();
    final conDato = dePeorAMejor.where((f) => f.valor != null).toList();
    final sinDato = dePeorAMejor.where((f) => f.valor == null).toList();
    final ordenadas = [...conDato, ...sinDato];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('CALIDAD CLÍNICA · TODA LA RED'),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text('Tablero de indicadores', style: _headingStyle(32)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuatro indicadores de estructura, proceso y resultado, '
                'calculados con las mediciones de cada sede.',
                style: TextStyle(color: _muted, height: 1.5, fontSize: 15),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final ancha = constraints.maxWidth >= 700;
                  final ancho = ancha
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final r in resumenes)
                        _MetricCard(
                          width: ancho,
                          resumen: r,
                          onTap: () => onAbrirDetalle(r.indicador.id),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Dónde actuar primero',
                        style: _headingStyle(22),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      promedioDestacado == null
                          ? '${destacado.nombre} por sede en el último '
                                'periodo.'
                          : '${destacado.nombre} por sede en el último '
                                'periodo, frente al promedio de la red '
                                '(${formatoValor(promedioDestacado!)} '
                                '${destacado.unidad}).',
                      style: const TextStyle(
                        color: _muted,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => onAbrirDetalle(destacado.id),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Ver detalle'),
                        style: TextButton.styleFrom(
                          foregroundColor: _purple,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final ancha = constraints.maxWidth >= 700;
                        final ancho = ancha
                            ? (constraints.maxWidth - 20) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          children: [
                            for (final fila in ordenadas)
                              SizedBox(
                                width: ancho,
                                child: _SiteSummaryTile(fila: fila),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '${destacado.nombre} por sede, de peor a mejor',
                        style: _headingStyle(20),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'La línea punteada marca el promedio de la red.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    _SiteBarChart(
                      filas: ordenadas,
                      promedio: promedioDestacado,
                    ),
                    const SizedBox(height: 16),
                    const _PerformanceLegend(),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final conDato = tendencia.where((p) => p.valor != null).toList();
    final ultimo = conDato.isEmpty ? null : conDato.last.valor;
    final sinMedicion = [
      for (final p in tendencia)
        if (p.valor == null) mesCorto(p.periodo),
    ];
    final comparables = comparacion.where((f) => f.valor != null).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onVolver,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 17, color: _muted),
                          SizedBox(width: 7),
                          Text(
                            'Indicadores',
                            style: TextStyle(
                              color: _muted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('/', style: TextStyle(color: _muted)),
                  ),
                  Expanded(
                    child: Text(
                      indicador.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Eyebrow('${indicador.categoria} · ${indicador.unidad}'),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text(indicador.nombre, style: _headingStyle(32)),
              ),
              const SizedBox(height: 8),
              Text(
                indicador.descripcion,
                style: const TextStyle(
                  color: _muted,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Tendencia mensual',
                        style: _headingStyle(22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ultimo == null
                          ? 'Sin mediciones en los últimos $mesesVisibles meses'
                          : 'Último periodo: ${formatoValor(ultimo)} '
                                '${indicador.unidad}',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 260,
                      child: SelectorVitalys<String?>(
                        valor: sedeTendencia,
                        hint: 'Toda la red',
                        opciones: [
                          (null, 'Toda la red'),
                          for (final s in sedesDisponibles)
                            (s.id, s.nombreCorto),
                        ],
                        onChanged: onElegirSede,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (conDato.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No hay mediciones en los últimos 6 meses',
                          style: TextStyle(color: _muted),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 205,
                        width: double.infinity,
                        child: _TrendChart(
                          values: [for (final p in tendencia) p.valor],
                          labels: [
                            for (final p in tendencia) mesCorto(p.periodo),
                          ],
                          filled: true,
                        ),
                      ),
                      if (sinMedicion.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Sin medición: ${sinMedicion.join(', ')}',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Comparación entre sedes',
                        style: _headingStyle(22),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Último periodo · línea punteada: promedio de la red',
                      style: TextStyle(
                        color: _muted,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (comparables.isEmpty)
                      const Text(
                        'No hay mediciones en el último periodo',
                        style: TextStyle(color: _muted),
                      )
                    else ...[
                      _SiteBarChart(
                        filas: comparacion,
                        promedio: promedio,
                        compacta: true,
                      ),
                      const SizedBox(height: 14),
                      const _PerformanceLegend(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text('Mediciones recientes', style: _headingStyle(22)),
              ),
              const SizedBox(height: 6),
              Text(
                mediciones.length == 1
                    ? '1 medición'
                    : '${mediciones.length} mediciones',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              _RecentMeasurements(indicador: indicador, filas: mediciones),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _purple,
        fontSize: 10,
        letterSpacing: 1.15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Tarjeta de un indicador: su valor en la red, su tendencia y su cambio.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.resumen,
    required this.onTap,
  });

  final double width;
  final ResumenIndicador resumen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ind = resumen.indicador;
    final valor = resumen.valorRed;
    final tendencia = resumen.tendencia;
    final empeora = resumen.mejoro == false;
    final etiqueta = switch (resumen.mejoro) {
      true => 'Mejora',
      false => 'Empeora',
      null => 'Sin cambio',
    };
    final colorEtiqueta = empeora ? _red : _green;
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label:
            '${ind.nombre}, '
            '${valor == null ? mensajeSinMediciones : '${formatoValor(valor)} ${ind.unidad}'}. '
            'Abrir detalle',
        excludeSemantics: true,
        child: Material(
          color: _mint,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ind.categoria,
                    style: const TextStyle(
                      color: Color(0xFF26584B),
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    ind.nombre,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (valor == null)
                    const Text(
                      mensajeSinMediciones,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatoValor(valor),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 27,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            ind.unidad,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 31,
                    width: double.infinity,
                    child: tendencia.length < 2
                        ? const SizedBox.shrink()
                        : _TrendChart(
                            values: tendencia,
                            color: _ink,
                            showGrid: false,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: empeora ? _redPale : const Color(0xFFC9F7E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              empeora ? Icons.arrow_upward : Icons.check,
                              size: 12,
                              color: colorEtiqueta,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              etiqueta,
                              style: TextStyle(
                                color: colorEtiqueta,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          resumen.cambio == null
                              ? 'Sin periodo anterior'
                              : '${resumen.cambio} vs. mes previo',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _ink, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E9F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14181740),
            blurRadius: 13,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Colores de una sede según su marca. Sin marca es *Sin medición*.
({Color color, Color fondo, IconData icono, String texto}) _estilo(
  MarcaSede? marca,
) {
  return switch (marca) {
    MarcaSede.peor => (
      color: _red,
      fondo: _redPale,
      icono: Icons.arrow_upward,
      texto: MarcaSede.peor.nombre,
    ),
    MarcaSede.mejor => (
      color: _green,
      fondo: _greenPale,
      icono: Icons.check,
      texto: MarcaSede.mejor.nombre,
    ),
    MarcaSede.igual => (
      color: _muted,
      fondo: _grayPale,
      icono: Icons.drag_handle,
      texto: MarcaSede.igual.nombre,
    ),
    null => (
      color: _muted,
      fondo: _grayPale,
      icono: Icons.remove,
      texto: mensajeSinMedicion,
    ),
  };
}

class _SiteSummaryTile extends StatelessWidget {
  const _SiteSummaryTile({required this.fila});

  final FilaSede fila;

  @override
  Widget build(BuildContext context) {
    final e = _estilo(fila.marca);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: e.fondo,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fila.nombre, style: TextStyle(color: e.color, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            fila.valor == null ? mensajeSinMedicion : formatoValor(fila.valor!),
            style: TextStyle(
              color: e.color,
              fontSize: fila.valor == null ? 14 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(e.icono, size: 13, color: e.color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  e.texto,
                  style: TextStyle(color: e.color, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barras por sede con la línea punteada del promedio de la red. Las sedes
/// sin medición van al final con *Sin medición* (F-10).
class _SiteBarChart extends StatelessWidget {
  const _SiteBarChart({
    required this.filas,
    required this.promedio,
    this.compacta = false,
  });

  final List<FilaSede> filas;
  final double? promedio;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final valores = [
      for (final f in filas)
        if (f.valor != null) f.valor!,
      ?promedio,
    ];
    final tope = valores.isEmpty
        ? 1.0
        : valores.reduce((a, b) => a > b ? a : b) * 1.18;
    return Column(
      children: [
        for (final fila in filas)
          Padding(
            padding: EdgeInsets.symmetric(vertical: compacta ? 4 : 6),
            child: Row(
              children: [
                SizedBox(
                  width: compacta ? 106 : 118,
                  child: Text(
                    fila.nombre,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _muted,
                      fontSize: compacta ? 10 : 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: compacta ? 16 : 18,
                    child: fila.valor == null
                        ? const SizedBox.shrink()
                        : CustomPaint(
                            painter: _BarPainter(
                              value: fila.valor!,
                              color: _estilo(fila.marca).color,
                              average: promedio,
                              maxValue: tope,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: fila.valor == null ? 86 : 48,
                  child: Text(
                    fila.valor == null
                        ? mensajeSinMedicion
                        : '${formatoValor(fila.valor!)} '
                              '${switch (fila.marca) {
                                MarcaSede.peor => '▲',
                                MarcaSede.mejor => '✓',
                                _ => '=',
                              }}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: fila.marca == MarcaSede.mejor ? _green : _ink,
                      fontSize: compacta ? 10 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PerformanceLegend extends StatelessWidget {
  const _PerformanceLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _LegendItem(color: _green, label: 'Mejor que el promedio ✓'),
        _LegendItem(color: _gray, label: 'Igual al promedio ='),
        _LegendItem(color: _red, label: 'Peor que el promedio ▲'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.values,
    this.labels = const [],
    this.color = _purple,
    this.filled = false,
    this.showGrid = true,
  });

  /// Un valor por mes. Un mes sin valor es *Sin medición* y deja un hueco.
  final List<double?> values;
  final List<String> labels;
  final Color color;
  final bool filled;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final presentes = [for (final v in values) ?v];
    if (presentes.isEmpty) return const SizedBox.shrink();
    final minimo = presentes.reduce((a, b) => a < b ? a : b);
    final maximo = presentes.reduce((a, b) => a > b ? a : b);
    return CustomPaint(
      painter: _TrendPainter(
        values: values,
        minY: showGrid
            ? (minimo - 1).floorToDouble().clamp(0, double.infinity)
            : minimo - 1,
        maxY: showGrid ? (maximo + 1).ceilToDouble() : maximo + 1,
        labels: labels,
        color: color,
        filled: filled,
        showGrid: showGrid,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Las mediciones recientes como lista: cada una con su sede, su periodo, su
/// valor y su marca. No se desplaza hacia los lados (RNF-07).
class _RecentMeasurements extends StatelessWidget {
  const _RecentMeasurements({required this.indicador, required this.filas});

  final Indicador indicador;
  final List<FilaMedicion> filas;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return const _SectionCard(
        child: Text(
          'No hay mediciones en los últimos 6 meses',
          style: TextStyle(color: _muted),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10181740),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final fila in filas)
            _MeasurementRow(indicador: indicador, fila: fila),
        ],
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.indicador, required this.fila});

  final Indicador indicador;
  final FilaMedicion fila;

  @override
  Widget build(BuildContext context) {
    final e = _estilo(fila.marca);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fila.sedeNombre,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatoPeriodo(fila.periodo),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatoValor(fila.valor)} ${indicador.unidad}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: e.fondo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.texto,
                  style: TextStyle(
                    color: e.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

TextStyle _headingStyle(double size) => TextStyle(
  color: _ink,
  fontSize: size,
  height: 1.12,
  letterSpacing: -size * .035,
  fontWeight: FontWeight.w800,
);

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.value,
    required this.color,
    required this.average,
    required this.maxValue,
  });

  final double value;
  final Color color;
  final double? average;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = size.height * .68;
    final top = (size.height - barHeight) / 2;
    final barWidth = size.width * (value / maxValue).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, barWidth, barHeight),
        Radius.circular(barHeight),
      ),
      Paint()..color = color,
    );
    final media = average;
    if (media == null) return;
    final averageX = size.width * (media / maxValue).clamp(0.0, 1.0);
    final linePaint = Paint()
      ..color = _ink
      ..strokeWidth = 1.2;
    const dashLength = 3.0;
    const gap = 2.5;
    for (double y = 0; y < size.height; y += dashLength + gap) {
      canvas.drawLine(
        Offset(averageX, y),
        Offset(averageX, (y + dashLength).clamp(0, size.height).toDouble()),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.average != average ||
      oldDelegate.maxValue != maxValue;
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.labels,
    required this.color,
    required this.filled,
    required this.showGrid,
  });

  final List<double?> values;
  final double minY;
  final double maxY;
  final List<String> labels;
  final Color color;
  final bool filled;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final labelHeight = labels.isEmpty ? 0.0 : 20.0;
    final left = labels.isEmpty ? 1.0 : 28.0;
    final right = labels.isEmpty ? 1.0 : 2.0;
    final top = labels.isEmpty ? 2.0 : 10.0;
    final bottom = size.height - labelHeight;
    final chartWidth = size.width - left - right;
    final chartHeight = bottom - top;
    final denominator = maxY - minY == 0 ? 1.0 : maxY - minY;
    final pasos = values.length < 2 ? 1 : values.length - 1;

    double x(int i) => left + chartWidth * i / pasos;
    double y(double v) => bottom - (v - minY) / denominator * chartHeight;

    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFFE4E4F0)
        ..strokeWidth = 1;
      for (final fraction in [0.0, .5, 1.0]) {
        final lineY = top + chartHeight * fraction;
        canvas.drawLine(
          Offset(left, lineY),
          Offset(size.width - right, lineY),
          gridPaint,
        );
      }
      const labelStyle = TextStyle(
        color: _muted,
        fontSize: 10,
        fontWeight: FontWeight.w400,
      );
      for (final item in [
        (0.0, maxY.toStringAsFixed(0)),
        (.5, ((maxY + minY) / 2).toStringAsFixed(0)),
        (1.0, minY.toStringAsFixed(0)),
      ]) {
        final painter = TextPainter(
          text: TextSpan(text: item.$2, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          Offset(0, top + chartHeight * item.$1 - painter.height / 2),
        );
      }
    }

    // La línea se corta donde falta un mes (*Sin medición*).
    final tramos = <List<Offset>>[];
    var actual = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        if (actual.isNotEmpty) tramos.add(actual);
        actual = <Offset>[];
      } else {
        actual.add(Offset(x(i), y(v)));
      }
    }
    if (actual.isNotEmpty) tramos.add(actual);

    for (final tramo in tramos) {
      if (tramo.length < 2) continue;
      final path = Path()..moveTo(tramo.first.dx, tramo.first.dy);
      for (final punto in tramo.skip(1)) {
        path.lineTo(punto.dx, punto.dy);
      }
      if (filled) {
        final fillPath = Path.from(path)
          ..lineTo(tramo.last.dx, bottom)
          ..lineTo(tramo.first.dx, bottom)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: .24),
                color.withValues(alpha: .015),
              ],
            ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight)),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = labels.isEmpty ? 2 : 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (filled) {
      final dotPaint = Paint()..color = color;
      final innerPaint = Paint()..color = Colors.white;
      for (final tramo in tramos) {
        for (final punto in tramo) {
          canvas.drawCircle(punto, 4.2, dotPaint);
          canvas.drawCircle(punto, 2.3, innerPaint);
        }
      }
    }

    for (var i = 0; i < labels.length && i < values.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x(i) - painter.width / 2, bottom + 7));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.minY != minY ||
      oldDelegate.maxY != maxY ||
      oldDelegate.color != color ||
      oldDelegate.filled != filled;
}
