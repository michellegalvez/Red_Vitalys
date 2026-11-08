import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/indicadores/estilo_marca.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Las mediciones recientes como lista: cada una con su sede, su periodo, su
/// valor y su marca. No se desplaza hacia los lados (RNF-07).
class TablaMediciones extends StatelessWidget {
  const TablaMediciones({
    super.key,
    required this.indicador,
    required this.filas,
  });

  final Indicador indicador;
  final List<FilaMedicion> filas;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return const EstadoVacio(
        titulo: 'No hay mediciones en los últimos 6 meses',
      );
    }
    return TarjetaVitalys(
      relleno: EdgeInsets.zero,
      radio: TarjetaVitalys.radioFila,
      child: Column(
        children: [
          for (final fila in filas)
            _FilaMedicionTabla(indicador: indicador, fila: fila),
        ],
      ),
    );
  }
}

class _FilaMedicionTabla extends StatelessWidget {
  const _FilaMedicionTabla({required this.indicador, required this.fila});

  final Indicador indicador;
  final FilaMedicion fila;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloMarca(fila.marca);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ColoresVitalys.borde)),
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
                    color: ColoresVitalys.tinta,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatoPeriodo(fila.periodo),
                  style: const TextStyle(
                    color: ColoresVitalys.textoSecundario,
                    fontSize: 12,
                  ),
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
                  color: ColoresVitalys.tinta,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              ChipVitalys(
                texto: estilo.texto,
                colorFondo: estilo.fondo,
                colorTexto: estilo.colorTexto,
                tamanoTexto: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
