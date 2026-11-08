import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/campo_dato.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Un dato del perfil: su etiqueta y su valor.
typedef DatoPerfil = ({String etiqueta, String valor});

/// Una acción de la tabla de permisos y si el rol la tiene.
typedef PermisoPerfil = ({String accion, bool permitido});

/// Tarjeta con los datos de la cuenta: cada etiqueta en mayúsculas y su
/// valor debajo (F-22). En celular va un dato por fila; en computador se
/// reparten en [columnas] (Figma, pantalla 9).
class TarjetaDatosPerfil extends StatelessWidget {
  const TarjetaDatosPerfil({super.key, required this.datos, this.columnas = 1});

  final List<DatoPerfil> datos;
  final int columnas;

  Widget _dato(DatoPerfil d, {double separacion = 0}) {
    return CampoDato(
      d.etiqueta,
      d.valor,
      tamanoValor: columnas > 1 ? 16 : 15.5,
      pesoValor: FontWeight.w800,
      separacion: separacion,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (columnas > 1) {
      return TarjetaVitalys(
        relleno: const EdgeInsets.fromLTRB(26, 30, 26, 30),
        child: LayoutBuilder(
          builder: (context, c) {
            const separacion = 24.0;
            final ancho = (c.maxWidth - separacion * (columnas - 1)) / columnas;
            return Wrap(
              spacing: separacion,
              runSpacing: 22,
              children: [
                for (final d in datos) SizedBox(width: ancho, child: _dato(d)),
              ],
            );
          },
        ),
      );
    }
    return TarjetaVitalys(
      relleno: const EdgeInsets.fromLTRB(22, 22, 22, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final d in datos) _dato(d, separacion: 18)],
      ),
    );
  }
}

/// Marca de un permiso: "Permitido" en verde con un visto, o "No incluido"
/// en gris con un candado.
class ChipPermiso extends StatelessWidget {
  const ChipPermiso({super.key, required this.permitido});

  final bool permitido;

  @override
  Widget build(BuildContext context) {
    return ChipVitalys(
      texto: permitido ? 'Permitido' : 'No incluido',
      icono: permitido ? Icons.check_rounded : Icons.lock_outline_rounded,
      tamanoTexto: 12,
      colorFondo: permitido ? ColoresVitalys.exitoFondo : ColoresVitalys.fondo,
      colorTexto: permitido
          ? ColoresVitalys.mentaTexto
          : ColoresVitalys.textoSecundario,
    );
  }
}

/// Lista *Qué puede hacer con su rol*: cada acción con su marca (F-22).
class ListaPermisos extends StatelessWidget {
  const ListaPermisos({super.key, required this.permisos});

  final List<PermisoPerfil> permisos;

  @override
  Widget build(BuildContext context) {
    return TarjetaVitalys(
      relleno: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TarjetaVitalys.radioTarjeta - 1),
        child: Column(
          children: [
            for (var i = 0; i < permisos.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: i == permisos.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: ColoresVitalys.borde),
                        ),
                ),
                child: MergeSemantics(
                  child: Row(
                    children: [
                      ChipPermiso(permitido: permisos[i].permitido),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          permisos[i].accion,
                          style: const TextStyle(fontSize: 14.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Los propósitos que el rol puede declarar, como chips (F-22). Sin
/// propósitos muestra [mensajeVacio].
class ChipsPropositos extends StatelessWidget {
  const ChipsPropositos({
    super.key,
    required this.propositos,
    required this.mensajeVacio,
  });

  final List<String> propositos;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    if (propositos.isEmpty) {
      return EstadoVacio(
        titulo: mensajeVacio,
        icono: Icons.do_not_disturb_alt_outlined,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in propositos)
          ChipVitalys(texto: p, colorTexto: ColoresVitalys.primarioOscuro),
      ],
    );
  }
}
