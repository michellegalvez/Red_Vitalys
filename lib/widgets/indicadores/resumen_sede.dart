import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/widgets/indicadores/estilo_marca.dart';

/// El valor de una sede con su marca frente al promedio de la red.
class ResumenSede extends StatelessWidget {
  const ResumenSede({super.key, required this.fila, required this.unidad});

  final FilaSede fila;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloMarca(fila.marca);
    final valor = fila.valor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: estilo.fondo,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fila.nombre,
            style: TextStyle(color: estilo.colorTexto, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            valor == null
                ? mensajeSinMedicion
                : '${formatoValor(valor)} $unidad',
            style: TextStyle(
              color: estilo.colorTexto,
              fontSize: valor == null ? 14 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(estilo.icono, size: 14, color: estilo.colorTexto),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  estilo.texto,
                  style: TextStyle(color: estilo.colorTexto, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
