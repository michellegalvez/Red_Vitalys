import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/indicadores/estilo_marca.dart';

/// Barras por sede con la línea punteada del promedio de la red. Las sedes
/// sin medición van al final con *Sin medición* (F-10).
class BarrasPorSede extends StatelessWidget {
  const BarrasPorSede({
    super.key,
    required this.filas,
    required this.promedio,
    required this.unidad,
    this.compacta = false,
  });

  final List<FilaSede> filas;
  final double? promedio;
  final String unidad;
  final bool compacta;

  String _resumen() {
    final partes = [
      for (final f in filas)
        if (f.valor == null)
          '${f.nombre}: ${mensajeSinMedicion.toLowerCase()}'
        else
          '${f.nombre}: ${formatoValor(f.valor!)} $unidad, '
              '${estiloMarca(f.marca).texto.toLowerCase()}',
    ];
    final media = promedio == null
        ? ''
        : ' Promedio de la red: ${formatoValor(promedio!)} $unidad.';
    return 'Gráfica de barras por sede. ${partes.join('. ')}.$media';
  }

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
    return Semantics(
      label: _resumen(),
      excludeSemantics: true,
      child: Column(
        children: [
          for (final fila in filas)
            Padding(
              padding: EdgeInsets.symmetric(vertical: compacta ? 4 : 6),
              child: _FilaBarra(
                fila: fila,
                promedio: promedio,
                tope: tope,
                compacta: compacta,
                unidad: unidad,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaBarra extends StatelessWidget {
  const _FilaBarra({
    required this.fila,
    required this.promedio,
    required this.tope,
    required this.compacta,
    required this.unidad,
  });

  final String unidad;
  final FilaSede fila;
  final double? promedio;
  final double tope;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloMarca(fila.marca);
    final valor = fila.valor;
    final texto = valor == null
        ? mensajeSinMedicion
        : '${formatoValor(valor)} $unidad · ${estilo.texto}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                fila.nombre,
                style: const TextStyle(
                  color: ColoresVitalys.textoSecundario,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                texto,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: fila.marca == MarcaSede.mejor
                      ? ColoresVitalys.mentaTexto
                      : ColoresVitalys.tinta,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: compacta ? 14 : 16,
          width: double.infinity,
          child: valor == null
              ? const SizedBox.shrink()
              : CustomPaint(
                  painter: _PintorBarra(
                    valor: valor,
                    color: estilo.colorBarra,
                    promedio: promedio,
                    maximo: tope,
                  ),
                ),
        ),
      ],
    );
  }
}

/// La leyenda de los colores de las barras.
class LeyendaDesempeno extends StatelessWidget {
  const LeyendaDesempeno({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final (marca, simbolo) in const [
          (MarcaSede.mejor, '✓'),
          (MarcaSede.igual, '='),
          (MarcaSede.peor, '▲'),
        ])
          _ItemLeyenda(
            color: estiloMarca(marca).colorBarra,
            texto: '${estiloMarca(marca).texto} $simbolo',
          ),
      ],
    );
  }
}

class _ItemLeyenda extends StatelessWidget {
  const _ItemLeyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

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
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(
              color: ColoresVitalys.textoSecundario,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _PintorBarra extends CustomPainter {
  const _PintorBarra({
    required this.valor,
    required this.color,
    required this.promedio,
    required this.maximo,
  });

  final double valor;
  final Color color;
  final double? promedio;
  final double maximo;

  @override
  void paint(Canvas canvas, Size size) {
    final alto = size.height * .68;
    final arriba = (size.height - alto) / 2;
    final ancho = size.width * (valor / maximo).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, arriba, ancho, alto),
        Radius.circular(alto),
      ),
      Paint()..color = color,
    );
    final media = promedio;
    if (media == null) return;
    final mediaX = size.width * (media / maximo).clamp(0.0, 1.0);
    final lineaPaint = Paint()
      ..color = ColoresVitalys.tinta
      ..strokeWidth = 1.2;
    const largoTrazo = 3.0;
    const hueco = 2.5;
    for (double y = 0; y < size.height; y += largoTrazo + hueco) {
      canvas.drawLine(
        Offset(mediaX, y),
        Offset(mediaX, (y + largoTrazo).clamp(0, size.height).toDouble()),
        lineaPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorBarra anterior) =>
      anterior.valor != valor ||
      anterior.color != color ||
      anterior.promedio != promedio ||
      anterior.maximo != maximo;
}
