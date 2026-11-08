import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Lugar de una sección que construye otro integrante del equipo (por
/// ejemplo el tablero o la auditoría). Deja la navegación completa mientras
/// se integra su pantalla.
class PendientePage extends StatelessWidget {
  const PendientePage({
    super.key,
    required this.sobretitulo,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });

  final String sobretitulo;
  final String titulo;
  final String descripcion;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return ContenidoPagina(
      children: [
        EncabezadoPagina(
          sobretitulo: sobretitulo,
          titulo: titulo,
          subtitulo: descripcion,
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ColoresVitalys.borde),
          ),
          child: Row(
            children: [
              Icon(icono, size: 36, color: ColoresVitalys.primario),
              const SizedBox(width: 18),
              const Expanded(
                child: Text(
                  'Esta pantalla la construye otro integrante del equipo y '
                  'se conecta aquí.',
                  style: TextStyle(color: ColoresVitalys.textoSecundario),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
