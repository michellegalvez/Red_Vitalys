import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/indicadores/grafica_tendencia.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Tarjeta de un indicador: su valor en la red, el periodo, su tendencia y su
/// cambio frente al mes previo.
class TarjetaIndicador extends StatelessWidget {
  const TarjetaIndicador({
    super.key,
    required this.resumen,
    required this.periodo,
    required this.onTap,
  });

  final ResumenIndicador resumen;

  /// El último mes cerrado, al que corresponde el valor.
  final DateTime periodo;
  final VoidCallback onTap;

  String _etiquetaSemantica(String estado) {
    final ind = resumen.indicador;
    final valor = resumen.valorRed;
    final cambio = resumen.cambio;
    final valorTexto = valor == null
        ? mensajeSinMediciones
        : '${formatoValor(valor)} ${ind.unidad}';
    final cambioTexto = cambio == null
        ? 'sin periodo anterior'
        : '${estado.toLowerCase()} $cambio frente al mes previo';
    return '${ind.nombre}, $valorTexto, ${formatoPeriodo(periodo)}, '
        '$cambioTexto. Abrir detalle';
  }

  @override
  Widget build(BuildContext context) {
    final ind = resumen.indicador;
    final estado = switch (resumen.mejoro) {
      true => 'Mejora',
      false => 'Empeora',
      null => 'Sin cambio',
    };
    return Semantics(
      button: true,
      label: _etiquetaSemantica(estado),
      excludeSemantics: true,
      child: Material(
        color: ColoresVitalys.verdeLima,
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
                    color: ColoresVitalys.mentaTexto,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  ind.nombre,
                  style: const TextStyle(
                    color: ColoresVitalys.tinta,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _Valor(valor: resumen.valorRed, unidad: ind.unidad),
                const SizedBox(height: 2),
                Text(
                  formatoPeriodo(periodo),
                  style: const TextStyle(
                    color: ColoresVitalys.tinta,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 31,
                  width: double.infinity,
                  child: resumen.tendencia.length < 2
                      ? const SizedBox.shrink()
                      : GraficaTendencia(
                          valores: resumen.tendencia,
                          unidad: ind.unidad,
                          color: ColoresVitalys.tinta,
                          mostrarCuadricula: false,
                        ),
                ),
                const SizedBox(height: 8),
                _CambioIndicador(
                  estado: estado,
                  mejoro: resumen.mejoro,
                  cambio: resumen.cambio,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor({required this.valor, required this.unidad});

  final double? valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final v = valor;
    if (v == null) {
      return const Text(
        mensajeSinMediciones,
        style: TextStyle(
          color: ColoresVitalys.tinta,
          fontSize: 20,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatoValor(v),
          style: const TextStyle(
            color: ColoresVitalys.tinta,
            fontSize: 27,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            unidad,
            style: const TextStyle(
              color: ColoresVitalys.tinta,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CambioIndicador extends StatelessWidget {
  const _CambioIndicador({
    required this.estado,
    required this.mejoro,
    required this.cambio,
  });

  final String estado;
  final bool? mejoro;
  final String? cambio;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto, icono) = switch (mejoro) {
      true => (
        ColoresVitalys.exitoFondo,
        ColoresVitalys.mentaTexto,
        Icons.check,
      ),
      false => (
        ColoresVitalys.alertaFondo,
        ColoresVitalys.alertaTexto,
        Icons.arrow_upward,
      ),
      null => (ColoresVitalys.superficie, ColoresVitalys.tinta, Icons.remove),
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        ChipVitalys(
          texto: estado,
          icono: icono,
          colorFondo: fondo,
          colorTexto: texto,
          tamanoTexto: 12,
        ),
        Text(
          cambio == null ? 'Sin periodo anterior' : '$cambio vs. mes previo',
          style: const TextStyle(color: ColoresVitalys.tinta, fontSize: 12),
        ),
      ],
    );
  }
}
