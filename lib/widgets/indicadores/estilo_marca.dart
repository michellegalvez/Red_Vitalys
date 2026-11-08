import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Cómo se ve una sede según su marca frente al promedio. Sin marca es
/// *Sin medición*.
class EstiloMarca {
  const EstiloMarca({
    required this.colorBarra,
    required this.colorTexto,
    required this.fondo,
    required this.icono,
    required this.texto,
  });

  final Color colorBarra;
  final Color colorTexto;
  final Color fondo;
  final IconData icono;
  final String texto;
}

EstiloMarca estiloMarca(MarcaSede? marca) {
  return switch (marca) {
    MarcaSede.peor => EstiloMarca(
      colorBarra: ColoresVitalys.alerta,
      colorTexto: ColoresVitalys.alertaTexto,
      fondo: ColoresVitalys.alertaFondo,
      icono: Icons.arrow_upward,
      texto: MarcaSede.peor.nombre,
    ),
    MarcaSede.mejor => EstiloMarca(
      colorBarra: ColoresVitalys.mentaTexto,
      colorTexto: ColoresVitalys.mentaTexto,
      fondo: ColoresVitalys.exitoFondo,
      icono: Icons.check,
      texto: MarcaSede.mejor.nombre,
    ),
    MarcaSede.igual => EstiloMarca(
      colorBarra: ColoresVitalys.textoSecundario,
      colorTexto: ColoresVitalys.textoSecundario,
      fondo: ColoresVitalys.fondo,
      icono: Icons.drag_handle,
      texto: MarcaSede.igual.nombre,
    ),
    null => EstiloMarca(
      colorBarra: ColoresVitalys.textoSecundario,
      colorTexto: ColoresVitalys.textoSecundario,
      fondo: ColoresVitalys.fondo,
      icono: Icons.remove,
      texto: mensajeSinMedicion,
    ),
  };
}

/// Qué valor es el mejor del indicador, para cualquier indicador.
String textoDireccion(DireccionIndicador direccion) => switch (direccion) {
  DireccionIndicador.masBajoEsMejor => 'Más bajo es mejor',
  DireccionIndicador.masAltoEsMejor => 'Más alto es mejor',
};
