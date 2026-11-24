import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/carga.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Tarjeta con la foto de perfil y sus botones (F-22): *Subir foto* o
/// *Cambiar foto*, y *Quitar foto*. Sin foto muestra las iniciales.
///
/// Solo muestra lo que le pasa la Screen y avisa con callbacks.
class TarjetaFotoPerfil extends StatelessWidget {
  const TarjetaFotoPerfil({
    super.key,
    required this.iniciales,
    required this.foto,
    required this.onCambiar,
    required this.onQuitar,
    required this.onReintentar,
    this.cargando = false,
    this.hayError = false,
    this.guardando = false,
    this.aviso,
  });

  final String iniciales;

  /// Los bytes de la foto, o `null` si el usuario no tiene.
  final Uint8List? foto;
  final VoidCallback onCambiar;
  final VoidCallback onQuitar;
  final VoidCallback onReintentar;
  final bool cargando;
  final bool hayError;
  final bool guardando;

  /// Por qué no se pudo cambiar la foto, si falló o se rechazó.
  final String? aviso;

  static const double _tamano = 96;

  Widget _imagen() {
    final bytes = foto;
    if (bytes == null) {
      return AvatarIniciales(iniciales: iniciales, tamano: _tamano);
    }
    return ClipOval(
      child: Image.memory(
        bytes,
        width: _tamano,
        height: _tamano,
        fit: BoxFit.cover,
        semanticLabel: 'Su foto de perfil',
        errorBuilder: (_, _, _) =>
            AvatarIniciales(iniciales: iniciales, tamano: _tamano),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = cargando || guardando;
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _imagen(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Foto de perfil',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JPG o PNG, de hasta 2 MB.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ColoresVitalys.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      BotonVitalys(
                        texto: guardando
                            ? 'Guardando…'
                            : foto == null
                            ? 'Subir foto'
                            : 'Cambiar foto',
                        icono: Icons.photo_camera_outlined,
                        variante: VarianteBoton.pequeno,
                        onPressed: ocupado ? null : onCambiar,
                      ),
                      if (foto != null)
                        BotonVitalys(
                          texto: 'Quitar foto',
                          icono: Icons.delete_outline_rounded,
                          variante: VarianteBoton.pequeno,
                          onPressed: ocupado ? null : onQuitar,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (cargando) const IndicadorCarga(texto: 'Cargando foto…'),
          if (hayError) ...[
            const SizedBox(height: 14),
            ErrorCarga(
              texto: 'No se pudo cargar su foto',
              onReintentar: onReintentar,
            ),
          ],
          if (aviso != null) ...[
            const SizedBox(height: 14),
            Aviso(tipo: TipoAviso.errores, texto: aviso!, anunciar: true),
          ],
        ],
      ),
    );
  }
}
