import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Un dato con su etiqueta en mayúsculas y su valor debajo. Lo usan los datos
/// básicos del paciente y los datos de la cuenta en el perfil.
class CampoDato extends StatelessWidget {
  const CampoDato(
    this.etiqueta,
    this.valor, {
    super.key,
    this.tamanoValor = 15,
    this.pesoValor = FontWeight.w400,
    this.separacion = 0,
  });

  final String etiqueta;
  final String valor;
  final double tamanoValor;
  final FontWeight pesoValor;

  /// Espacio que se deja debajo del dato.
  final double separacion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: separacion),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            style: TextStyle(
              fontSize: tamanoValor,
              fontWeight: pesoValor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

const _estiloValor = TextStyle(fontSize: 13.5, height: 1.35);

/// Un dato en una línea, "Etiqueta: valor", leído como un solo texto por los
/// lectores de pantalla.
class DatoEnLinea extends StatelessWidget {
  const DatoEnLinea({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.sinPartir = false,
  });

  final String etiqueta;
  final String valor;

  /// Para correos e IP: se achica para caber en una línea en vez de
  /// partirse.
  final bool sinPartir;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        // Si el valor no cabe junto a la etiqueta, baja entero a la línea
        // siguiente: un correo no se parte por la mitad.
        child: Wrap(
          children: [
            Text(
              '$etiqueta: ',
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: ColoresVitalys.textoSecundario,
              ),
            ),
            if (sinPartir)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor, style: _estiloValor),
              )
            else
              Text(valor, style: _estiloValor),
          ],
        ),
      ),
    );
  }
}
