import 'package:flutter/material.dart';

/// La barra de "Volver" que va arriba de una página: una flecha y un texto
/// de ruta, por ejemplo "Pacientes  /  Ana Pérez". Es la única que usa la app.
class BarraVolver extends StatelessWidget {
  const BarraVolver({super.key, required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: Text(texto, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
