import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

enum TipoAviso { informativo, alerta, advertencia, errores }

/// Avisos de la galería: informativo, de alerta, de advertencia y el
/// resumen de errores (con su lista de datos por revisar).
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.tipo,
    required this.texto,
    this.items = const [],
  });

  final TipoAviso tipo;
  final String texto;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, icono) = switch (tipo) {
      TipoAviso.informativo => (
        ColoresVitalys.infoFondo,
        ColoresVitalys.tinta,
        Icons.info_outline_rounded,
      ),
      TipoAviso.alerta => (
        ColoresVitalys.alertaFondo,
        ColoresVitalys.alertaTexto,
        Icons.warning_amber_rounded,
      ),
      TipoAviso.advertencia => (
        ColoresVitalys.advertenciaFondo,
        ColoresVitalys.advertenciaTexto,
        Icons.emergency_outlined,
      ),
      TipoAviso.errores => (
        ColoresVitalys.alertaFondo,
        ColoresVitalys.alertaTexto,
        Icons.error_outline_rounded,
      ),
    };
    return Semantics(
      liveRegion: tipo != TipoAviso.informativo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: TextStyle(
                      color: color,
                      fontWeight: tipo == TipoAviso.informativo
                          ? FontWeight.w500
                          : FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('•  $item', style: TextStyle(color: color)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
