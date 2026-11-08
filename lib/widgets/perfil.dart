import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Un dato del perfil: su etiqueta y su valor.
typedef DatoPerfil = ({String etiqueta, String valor});

/// Una acción de la tabla de permisos y si el rol la tiene.
typedef PermisoPerfil = ({String accion, bool permitido});

BoxDecoration _decoracionTarjeta() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: ColoresVitalys.borde),
  boxShadow: [
    BoxShadow(
      color: ColoresVitalys.tinta.withValues(alpha: 0.07),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ],
);

/// Tarjeta con los datos de la cuenta: cada etiqueta en mayúsculas y su
/// valor debajo (F-22). En celular va un dato por fila; en computador se
/// reparten en [columnas] (Figma, pantalla 9).
class TarjetaDatosPerfil extends StatelessWidget {
  const TarjetaDatosPerfil({super.key, required this.datos, this.columnas = 1});

  final List<DatoPerfil> datos;
  final int columnas;

  Widget _dato(DatoPerfil d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          d.etiqueta.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: ColoresVitalys.textoSecundario,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          d.valor,
          style: TextStyle(
            fontSize: columnas > 1 ? 16 : 15.5,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (columnas > 1) {
      return Container(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
        decoration: _decoracionTarjeta(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final d in datos)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _dato(d),
            ),
        ],
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
    final color = permitido
        ? ColoresVitalys.mentaTexto
        : ColoresVitalys.textoSecundario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: permitido ? ColoresVitalys.exitoFondo : ColoresVitalys.fondo,
        borderRadius: BorderRadius.circular(999),
        border: permitido ? null : Border.all(color: ColoresVitalys.borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            permitido ? Icons.check_rounded : Icons.lock_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            permitido ? 'Permitido' : 'No incluido',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista *Qué puede hacer con su rol*: cada acción con su marca (F-22).
class ListaPermisos extends StatelessWidget {
  const ListaPermisos({super.key, required this.permisos});

  final List<PermisoPerfil> permisos;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _decoracionTarjeta(),
      child: Column(
        children: [
          for (var i = 0; i < permisos.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      return Text(
        mensajeVacio,
        style: const TextStyle(color: ColoresVitalys.textoSecundario),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in propositos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ColoresVitalys.fondoLavanda,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              p,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ColoresVitalys.primarioOscuro,
              ),
            ),
          ),
      ],
    );
  }
}
