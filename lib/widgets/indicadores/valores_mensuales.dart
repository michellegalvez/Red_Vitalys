import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';

/// El valor de cada mes de la tendencia, a la vista bajo la gráfica (F-09):
/// "sep 2026 · 9,1 %" o "ago 2026 · Sin medición".
class ValoresMensuales extends StatelessWidget {
  const ValoresMensuales({
    super.key,
    required this.puntos,
    required this.unidad,
  });

  final List<PuntoTendencia> puntos;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = c.maxWidth >= 560 ? 3 : 2;
        const separacion = 8.0;
        final ancho = (c.maxWidth - separacion * (columnas - 1)) / columnas;
        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final p in puntos)
              SizedBox(
                width: ancho,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ColoresVitalys.fondo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatoPeriodo(p.periodo),
                        style: const TextStyle(
                          color: ColoresVitalys.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        p.valor == null
                            ? mensajeSinMedicion
                            : '${formatoValor(p.valor!)} $unidad',
                        style: TextStyle(
                          color: p.valor == null
                              ? ColoresVitalys.textoSecundario
                              : ColoresVitalys.tinta,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
