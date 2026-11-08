import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/widgets/formularios.dart';

/// Elige cuál de los indicadores se muestra por sede en el tablero.
class SelectorIndicador extends StatelessWidget {
  const SelectorIndicador({
    super.key,
    required this.indicadores,
    required this.seleccionado,
    required this.onElegir,
  });

  final List<Indicador> indicadores;
  final IdIndicador seleccionado;
  final ValueChanged<IdIndicador> onElegir;

  /// Nombre corto para la píldora; el nombre completo está en la tarjeta.
  static String nombreCorto(IdIndicador id) => switch (id) {
    IdIndicador.reingreso => 'Reingreso',
    IdIndicador.espera => 'Tiempo de espera',
    IdIndicador.adherencia => 'Adherencia',
    IdIndicador.eventos => 'Eventos adversos',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Indicador que se muestra por sede',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final i in indicadores)
            FiltroPildora(
              texto: nombreCorto(i.id),
              seleccionado: i.id == seleccionado,
              onTap: () => onElegir(i.id),
            ),
        ],
      ),
    );
  }
}
