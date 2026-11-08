import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

const _ink = ColoresVitalys.tinta;
const _muted = ColoresVitalys.textoSecundario;
const _purple = ColoresVitalys.primario;
const _mint = ColoresVitalys.verdeLima;
const _green = ColoresVitalys.mentaTexto;
const _greenPale = ColoresVitalys.exitoFondo;
const _red = ColoresVitalys.alerta;
const _redPale = ColoresVitalys.alertaFondo;
const _line = ColoresVitalys.borde;

const _sites = <_SiteValue>[
  _SiteValue('Cali Norte', 9.8, _Performance.worse),
  _SiteValue('Amb. Cali Sur', 9.8, _Performance.worse),
  _SiteValue('Bucaramanga Cabecera', 9.2, _Performance.worse),
  _SiteValue('Barranquilla Prado', 8.6, _Performance.worse),
  _SiteValue('Medellín El Poblado', 8.0, _Performance.better),
  _SiteValue('Amb. Envigado', 7.7, _Performance.better),
  _SiteValue('Bogotá Chapinero', 7.4, _Performance.better),
  _SiteValue('Bogotá Usaquén', 6.8, _Performance.better),
];

const _trendValues = <double>[9.9, 9.5, 9.3, 8.9, 8.6, 8.4];

/// Tablero de indicadores de calidad (F-08). Solo muestra y avisa: abrir el
/// detalle de un indicador lo decide la Screen anfitriona.
class IndicadoresPage extends StatelessWidget {
  const IndicadoresPage({super.key, required this.onAbrirDetalle});

  final VoidCallback onAbrirDetalle;

  @override
  Widget build(BuildContext context) {
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
              Text('Tablero de indicadores', style: _headingStyle(32)),
              const SizedBox(height: 8),
              const Text(
                'Cuatro indicadores de estructura, proceso y resultado, '
                'calculados con las mediciones de cada sede.',
                style: TextStyle(color: _muted, height: 1.5, fontSize: 15),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _MetricCard(
                        width: cardWidth,
                        category: 'RESULTADO',
                        title: 'Reingreso hospitalario a 30 días',
                        value: '8,4',
                        unit: '%',
                        change: '−0,3 vs. mes previo',
                        trend: const [10.1, 9.7, 9.5, 9.1, 8.7, 8.4],
                        onTap: onAbrirDetalle,
                      ),
                      _MetricCard(
                        width: cardWidth,
                        category: 'ESTRUCTURA',
                        title: 'Tiempo de espera promedio',
                        value: '25,8',
                        unit: 'min',
                        change: '−1,5 vs. mes previo',
                        trend: const [32, 31, 30, 28, 27, 25.8],
                        onTap: onAbrirDetalle,
                      ),
                      _MetricCard(
                        width: cardWidth,
                        category: 'PROCESO',
                        title: 'Adherencia a protocolos clínicos',
                        value: '86,9',
                        unit: '%',
                        change: '+1,1 vs. mes previo',
                        trend: const [82, 83, 83.8, 84.9, 85.8, 86.9],
                        onTap: onAbrirDetalle,
                      ),
                      _MetricCard(
                        width: cardWidth,
                        category: 'RESULTADO',
                        title: 'Eventos adversos evitables',
                        value: '1,8',
                        unit: 'por 1.000',
                        change: '−0,1 vs. mes previo',
                        trend: const [2.4, 2.2, 2.1, 1.9, 1.9, 1.8],
                        onTap: onAbrirDetalle,
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
                    Text('Dónde actuar primero', style: _headingStyle(22)),
                    const SizedBox(height: 5),
                    const Text(
                      'Reingreso a 30 días por sede en el último periodo, '
                      'frente al promedio de la red (8,4 %).',
                      style: TextStyle(
                        color: _muted,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onAbrirDetalle,
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
                        final isWide = constraints.maxWidth >= 700;
                        final width = isWide
                            ? (constraints.maxWidth - 20) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          children: [
                            for (final site in _sites)
                              SizedBox(
                                width: width,
                                child: _SiteSummaryTile(site: site),
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
                    Text(
                      'Reingreso por sede, de peor a mejor',
                      style: _headingStyle(20),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'La línea punteada marca el promedio de la red.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    const _SiteBarChart(),
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

/// Detalle de un indicador (F-09, F-10, F-11): tendencia, comparación entre
/// sedes y mediciones recientes. Volver lo decide la Screen anfitriona.
class DetalleIndicadorPage extends StatelessWidget {
  const DetalleIndicadorPage({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'Reingreso hospitalario a 30 días',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _Eyebrow('RESULTADO · %'),
              const SizedBox(height: 8),
              Text(
                'Reingreso hospitalario a 30 días',
                style: _headingStyle(32),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pacientes que vuelven a hospitalizarse en los 30 días '
                'siguientes al alta, sobre el total de egresos.',
                style: TextStyle(color: _muted, height: 1.5, fontSize: 15),
              ),
              const SizedBox(height: 22),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tendencia mensual', style: _headingStyle(22)),
                    const SizedBox(height: 4),
                    const Text(
                      'Último periodo: 8,4 %',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const _StaticSelector(label: 'Toda la red'),
                    const SizedBox(height: 18),
                    const SizedBox(
                      height: 205,
                      width: double.infinity,
                      child: _TrendChart(
                        values: _trendValues,
                        minY: 0,
                        maxY: 12,
                        labels: ['May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct'],
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comparación entre sedes', style: _headingStyle(22)),
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
                    const _SiteBarChart(compact: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Mediciones recientes', style: _headingStyle(22)),
              const SizedBox(height: 12),
              const Text(
                'Desliza la tabla para ver el valor y la comparación.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const _RecentMeasurements(),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.category,
    required this.title,
    required this.value,
    required this.unit,
    required this.change,
    required this.trend,
    required this.onTap,
  });

  final double width;
  final String category;
  final String title;
  final String value;
  final String unit;
  final String change;
  final List<double> trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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
                  category,
                  style: const TextStyle(
                    color: Color(0xFF26584B),
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
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
                        unit,
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
                  child: _TrendChart(
                    values: trend,
                    minY: trend.reduce((a, b) => a < b ? a : b) - 1,
                    maxY: trend.reduce((a, b) => a > b ? a : b) + 1,
                    labels: const [],
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
                        color: const Color(0xFFC9F7E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 12, color: _green),
                          SizedBox(width: 4),
                          Text(
                            'Mejora',
                            style: TextStyle(
                              color: _green,
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
                        change,
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

class _SiteSummaryTile extends StatelessWidget {
  const _SiteSummaryTile({required this.site});

  final _SiteValue site;

  @override
  Widget build(BuildContext context) {
    final isWorse = site.performance == _Performance.worse;
    final color = isWorse ? _red : _green;
    final background = isWorse ? _redPale : _greenPale;
    final description = isWorse
        ? 'Peor que el promedio'
        : 'Mejor que el promedio';
    final icon = isWorse ? Icons.arrow_upward : Icons.check;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(site.name, style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            site.value.toStringAsFixed(1).replaceAll('.', ','),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(color: color, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SiteBarChart extends StatelessWidget {
  const _SiteBarChart({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final site in _sites)
          Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
            child: Row(
              children: [
                SizedBox(
                  width: compact ? 106 : 118,
                  child: Text(
                    site.name,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _muted,
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: compact ? 16 : 18,
                    child: CustomPaint(
                      painter: _BarPainter(
                        value: site.value,
                        color: site.performance == _Performance.worse
                            ? _red
                            : _green,
                        average: 8.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${site.value.toStringAsFixed(1).replaceAll('.', ',')} '
                    '${site.performance == _Performance.worse ? '▲' : '✓'}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: site.performance == _Performance.worse
                          ? _ink
                          : _green,
                      fontSize: compact ? 10 : 11,
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
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendItem(color: _green, label: 'Mejor que el promedio ✓'),
        _LegendItem(color: Color(0xFFB8B8CF), label: 'Igual al promedio ='),
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

class _StaticSelector extends StatelessWidget {
  const _StaticSelector({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 178),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5D5E4)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: _ink, fontSize: 13)),
          const SizedBox(width: 22),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: _muted),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.values,
    required this.minY,
    required this.maxY,
    required this.labels,
    this.color = _purple,
    this.filled = false,
    this.showGrid = true,
  });

  final List<double> values;
  final double minY;
  final double maxY;
  final List<String> labels;
  final Color color;
  final bool filled;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(
        values: values,
        minY: minY,
        maxY: maxY,
        labels: labels,
        color: color,
        filled: filled,
        showGrid: showGrid,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RecentMeasurements extends StatelessWidget {
  const _RecentMeasurements();

  static const _rows = <(String, String, String, String)>[
    ('Cali Norte', '1 oct 2026 – 29 oct 2026', '9,8 %', 'Peor que el promedio'),
    (
      'Bogotá Usaquén',
      '1 oct 2026 – 29 oct 2026',
      '6,8 %',
      'Mejor que el promedio',
    ),
    (
      'Bogotá Chapinero',
      '1 oct 2026 – 29 oct 2026',
      '7,4 %',
      'Mejor que el promedio',
    ),
    (
      'Medellín El Poblado',
      '1 oct 2026 – 29 oct 2026',
      '8,0 %',
      'Mejor que el promedio',
    ),
    (
      'Barranquilla Prado',
      '1 oct 2026 – 29 oct 2026',
      '8,6 %',
      'Peor que el promedio',
    ),
    (
      'Bucaramanga Cabecera',
      '1 oct 2026 – 29 oct 2026',
      '9,2 %',
      'Peor que el promedio',
    ),
    (
      'Amb. Cali Sur',
      '1 oct 2026 – 29 oct 2026',
      '9,8 %',
      'Peor que el promedio',
    ),
    (
      'Amb. Envigado',
      '1 oct 2026 – 29 oct 2026',
      '7,7 %',
      'Mejor que el promedio',
    ),
    ('Cali Norte', '1 sep 2026 – 30 sep 2026', '9,5 %', 'Peor que el promedio'),
    (
      'Bogotá Usaquén',
      '1 sep 2026 – 30 sep 2026',
      '7,4 %',
      'Mejor que el promedio',
    ),
    (
      'Bogotá Chapinero',
      '1 sep 2026 – 30 sep 2026',
      '8,0 %',
      'Mejor que el promedio',
    ),
    (
      'Medellín El Poblado',
      '1 sep 2026 – 30 sep 2026',
      '8,6 %',
      'Cerca del promedio',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 760,
          child: Column(
            children: [
              const _MeasurementRow(
                isHeader: true,
                site: 'SEDE',
                period: 'PERIODO',
                value: 'VALOR (%)',
                comparison: 'FRENTE AL PROMEDIO DE LA RED',
              ),
              for (final row in _rows)
                _MeasurementRow(
                  site: row.$1,
                  period: row.$2,
                  value: row.$3,
                  comparison: row.$4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.site,
    required this.period,
    required this.value,
    required this.comparison,
    this.isHeader = false,
  });

  final String site;
  final String period;
  final String value;
  final String comparison;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFF2F2FA) : Colors.white,
        border: const Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              site,
              style: TextStyle(
                color: isHeader ? _muted : _ink,
                fontSize: isHeader ? 10 : 12,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: isHeader ? .5 : 0,
              ),
            ),
          ),
          SizedBox(
            width: 225,
            child: Text(
              period,
              style: TextStyle(
                color: isHeader ? _muted : _ink,
                fontSize: isHeader ? 10 : 12,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w400,
                letterSpacing: isHeader ? .5 : 0,
              ),
            ),
          ),
          SizedBox(
            width: 95,
            child: Text(
              value,
              style: TextStyle(
                color: isHeader ? _muted : _ink,
                fontSize: isHeader ? 10 : 12,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: isHeader ? .5 : 0,
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: Text(
              comparison,
              style: TextStyle(
                color: isHeader ? _muted : _ink,
                fontSize: isHeader ? 10 : 12,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w400,
                letterSpacing: isHeader ? .5 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Performance { better, worse }

class _SiteValue {
  const _SiteValue(this.name, this.value, this.performance);

  final String name;
  final double value;
  final _Performance performance;
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
  });

  final double value;
  final Color color;
  final double average;

  @override
  void paint(Canvas canvas, Size size) {
    const maxValue = 12.0;
    final barHeight = size.height * .68;
    final top = (size.height - barHeight) / 2;
    final barWidth = size.width * (value / maxValue);
    final averageX = size.width * (average / maxValue);
    final barPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, barWidth, barHeight),
        Radius.circular(barHeight),
      ),
      barPaint,
    );
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
      oldDelegate.average != average;
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

  final List<double> values;
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
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          left + chartWidth * i / (values.length - 1),
          bottom - (values[i] - minY) / denominator * chartHeight,
        ),
    ];

    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFFE4E4F0)
        ..strokeWidth = 1;
      for (final fraction in [0.0, .5, 1.0]) {
        final y = top + chartHeight * fraction;
        canvas.drawLine(
          Offset(left, y),
          Offset(size.width - right, y),
          gridPaint,
        );
      }
      final labelStyle = const TextStyle(
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

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (filled) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, bottom)
        ..lineTo(points.first.dx, bottom)
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

    if (filled) {
      final dotPaint = Paint()..color = color;
      final innerPaint = Paint()..color = Colors.white;
      for (final point in points) {
        canvas.drawCircle(point, 4.2, dotPaint);
        canvas.drawCircle(point, 2.3, innerPaint);
      }
    }

    for (var i = 0; i < labels.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(points[i].dx - painter.width / 2, bottom + 7),
      );
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
