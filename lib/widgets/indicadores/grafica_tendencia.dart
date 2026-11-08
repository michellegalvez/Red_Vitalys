import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Línea de tendencia mensual. Un mes sin valor es *Sin medición* y deja un
/// hueco. Tiene un resumen en texto para lectores de pantalla.
class GraficaTendencia extends StatelessWidget {
  const GraficaTendencia({
    super.key,
    required this.valores,
    required this.unidad,
    this.rotulos = const [],
    this.color = ColoresVitalys.primario,
    this.relleno = false,
    this.mostrarCuadricula = true,
  });

  /// Un valor por mes.
  final List<double?> valores;
  final String unidad;
  final List<String> rotulos;
  final Color color;
  final bool relleno;
  final bool mostrarCuadricula;

  String _resumen() {
    final partes = [
      for (var i = 0; i < valores.length; i++)
        if (valores[i] != null)
          rotulos.length > i
              ? '${rotulos[i]} ${formatoValor(valores[i]!)} $unidad'
              : '${formatoValor(valores[i]!)} $unidad',
    ];
    return 'Gráfica de tendencia. ${partes.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final presentes = [for (final v in valores) ?v];
    if (presentes.isEmpty) return const SizedBox.shrink();
    final minimo = presentes.reduce((a, b) => a < b ? a : b);
    final maximo = presentes.reduce((a, b) => a > b ? a : b);
    return Semantics(
      label: _resumen(),
      image: true,
      excludeSemantics: true,
      child: CustomPaint(
        painter: _PintorTendencia(
          valores: valores,
          minimoEje: mostrarCuadricula
              ? (minimo - 1).floorToDouble().clamp(0, double.infinity)
              : minimo - 1,
          maximoEje: mostrarCuadricula
              ? (maximo + 1).ceilToDouble()
              : maximo + 1,
          rotulos: rotulos,
          color: color,
          relleno: relleno,
          mostrarCuadricula: mostrarCuadricula,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PintorTendencia extends CustomPainter {
  const _PintorTendencia({
    required this.valores,
    required this.minimoEje,
    required this.maximoEje,
    required this.rotulos,
    required this.color,
    required this.relleno,
    required this.mostrarCuadricula,
  });

  static const double _tamanoTexto = 12;

  final List<double?> valores;
  final double minimoEje;
  final double maximoEje;
  final List<String> rotulos;
  final Color color;
  final bool relleno;
  final bool mostrarCuadricula;

  void _texto(Canvas canvas, String texto, Offset Function(Size) posicion) {
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(
          color: ColoresVitalys.textoSecundario,
          fontSize: _tamanoTexto,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pintor.paint(canvas, posicion(pintor.size));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) return;
    final alturaRotulos = rotulos.isEmpty ? 0.0 : 22.0;
    final izquierda = rotulos.isEmpty ? 1.0 : 32.0;
    final derecha = rotulos.isEmpty ? 1.0 : 6.0;
    final arriba = rotulos.isEmpty ? 2.0 : 10.0;
    final abajo = size.height - alturaRotulos;
    final anchoGrafica = size.width - izquierda - derecha;
    final altoGrafica = abajo - arriba;
    final rango = maximoEje - minimoEje == 0 ? 1.0 : maximoEje - minimoEje;
    final pasos = valores.length < 2 ? 1 : valores.length - 1;

    double x(int i) => izquierda + anchoGrafica * i / pasos;
    double y(double v) => abajo - (v - minimoEje) / rango * altoGrafica;

    if (mostrarCuadricula) {
      final lineaPaint = Paint()
        ..color = ColoresVitalys.borde
        ..strokeWidth = 1;
      for (final fraccion in [0.0, .5, 1.0]) {
        final lineaY = arriba + altoGrafica * fraccion;
        canvas.drawLine(
          Offset(izquierda, lineaY),
          Offset(size.width - derecha, lineaY),
          lineaPaint,
        );
      }
      for (final item in [
        (0.0, maximoEje.toStringAsFixed(0)),
        (.5, ((maximoEje + minimoEje) / 2).toStringAsFixed(0)),
        (1.0, minimoEje.toStringAsFixed(0)),
      ]) {
        _texto(
          canvas,
          item.$2,
          (t) => Offset(0, arriba + altoGrafica * item.$1 - t.height / 2),
        );
      }
    }

    // La línea se corta donde falta un mes (*Sin medición*).
    final tramos = <List<Offset>>[];
    var actual = <Offset>[];
    for (var i = 0; i < valores.length; i++) {
      final v = valores[i];
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
      final trazo = Path()..moveTo(tramo.first.dx, tramo.first.dy);
      for (final punto in tramo.skip(1)) {
        trazo.lineTo(punto.dx, punto.dy);
      }
      if (relleno) {
        final area = Path.from(trazo)
          ..lineTo(tramo.last.dx, abajo)
          ..lineTo(tramo.first.dx, abajo)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader =
                LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: .24),
                    color.withValues(alpha: .015),
                  ],
                ).createShader(
                  Rect.fromLTWH(izquierda, arriba, anchoGrafica, altoGrafica),
                ),
        );
      }
      canvas.drawPath(
        trazo,
        Paint()
          ..color = color
          ..strokeWidth = rotulos.isEmpty ? 2 : 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (relleno) {
      final puntoPaint = Paint()..color = color;
      final centroPaint = Paint()..color = ColoresVitalys.superficie;
      for (final tramo in tramos) {
        for (final punto in tramo) {
          canvas.drawCircle(punto, 4.2, puntoPaint);
          canvas.drawCircle(punto, 2.3, centroPaint);
        }
      }
    }

    for (var i = 0; i < rotulos.length && i < valores.length; i++) {
      _texto(canvas, rotulos[i], (t) => Offset(x(i) - t.width / 2, abajo + 7));
    }
  }

  @override
  bool shouldRepaint(covariant _PintorTendencia anterior) =>
      anterior.valores != valores ||
      anterior.minimoEje != minimoEje ||
      anterior.maximoEje != maximoEje ||
      anterior.color != color ||
      anterior.relleno != relleno;
}
