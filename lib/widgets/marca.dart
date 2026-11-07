import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Logo de Red Vitalys: el cuadro con el pulso y el nombre.
class MarcaRedVitalys extends StatelessWidget {
  const MarcaRedVitalys({
    super.key,
    this.sobreOscuro = false,
    this.tamano = 34,
  });

  /// Cambia el color del nombre cuando va sobre un fondo oscuro.
  final bool sobreOscuro;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Red Vitalys',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tamano,
            height: tamano,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tamano * 0.28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), ColoresVitalys.primario],
              ),
            ),
            child: CustomPaint(painter: _PulsoPainter()),
          ),
          const SizedBox(width: 10),
          Text(
            'Red Vitalys',
            style: TextStyle(
              fontSize: tamano * 0.56,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: sobreOscuro ? Colors.white : ColoresVitalys.tinta,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.18, h * 0.52)
      ..lineTo(w * 0.36, h * 0.52)
      ..lineTo(w * 0.45, h * 0.30)
      ..lineTo(w * 0.56, h * 0.72)
      ..lineTo(w * 0.65, h * 0.52)
      ..lineTo(w * 0.82, h * 0.52);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.075
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
