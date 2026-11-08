import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

enum TonoBloque { alerta, naranja, menta }

/// Bloque de color del inicio: un número grande con su título y detalle.
class BloqueInicio extends StatelessWidget {
  const BloqueInicio({
    super.key,
    required this.valor,
    required this.titulo,
    required this.detalle,
    required this.tono,
    this.onTap,
  });

  final String valor;
  final String titulo;
  final String detalle;
  final TonoBloque tono;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (fondo, color) = switch (tono) {
      TonoBloque.alerta => (
        ColoresVitalys.alertaFondo,
        ColoresVitalys.alertaTexto,
      ),
      TonoBloque.naranja => (
        ColoresVitalys.naranjaFondo,
        ColoresVitalys.naranjaTexto,
      ),
      TonoBloque.menta => (
        ColoresVitalys.mentaFondo,
        ColoresVitalys.mentaTexto,
      ),
    };
    return Semantics(
      button: onTap != null,
      label: '$valor $titulo. $detalle',
      excludeSemantics: true,
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -28,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valor,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalle,
                      style: TextStyle(fontSize: 13.5, color: color),
                    ),
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
