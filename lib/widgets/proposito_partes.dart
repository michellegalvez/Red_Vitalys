import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/foco.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Explica por qué se pide el propósito. En celular va plegado y se abre
/// con un toque, para que el diálogo quepa en la pantalla.
class PorQueSePide extends StatefulWidget {
  const PorQueSePide({super.key, required this.compacto, this.oscuro = false});

  final bool compacto;

  /// Para ponerlo sobre un fondo violeta.
  final bool oscuro;

  @override
  State<PorQueSePide> createState() => _PorQueSePideState();
}

class _PorQueSePideState extends State<PorQueSePide> {
  // Solo recuerda si el recuadro está abierto; no es dato de la app.
  bool _abierto = false;

  static const _texto =
      'La historia clínica es información sensible. Para protegerla, cada '
      'consulta guarda quién la hizo, desde qué sede, cuándo y para qué, y el '
      'auditor puede revisarlo después. Sin propósito no se muestra ningún '
      'dato del paciente.';

  @override
  Widget build(BuildContext context) {
    final visible = !widget.compacto || _abierto;
    final colorTitulo = widget.oscuro
        ? ColoresVitalys.verdeLima
        : ColoresVitalys.primarioOscuro;
    final colorTexto = widget.oscuro ? Colors.white : ColoresVitalys.tinta;
    // En celular la cabecera es el botón que pliega: mide 48 dp con el relleno.
    final cabecera = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.compacto ? 26 : 0),
      child: Row(
        children: [
          Icon(Icons.help_outline_rounded, size: 20, color: colorTitulo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '¿Por qué se lo pedimos?',
              style: TextStyle(fontWeight: FontWeight.w800, color: colorTitulo),
            ),
          ),
          if (widget.compacto)
            Icon(
              _abierto
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: colorTitulo,
            ),
        ],
      ),
    );
    final recuadro = Material(
      color: widget.oscuro
          ? Colors.white.withValues(alpha: 0.13)
          : ColoresVitalys.infoFondo,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.compacto
            ? () => setState(() => _abierto = !_abierto)
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: widget.compacto ? 11 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cabecera,
              if (visible) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    _texto,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: colorTexto,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!widget.compacto) return recuadro;
    return Semantics(
      button: true,
      expanded: _abierto,
      child: AnilloFoco(radio: BorderRadius.circular(18), child: recuadro),
    );
  }
}

/// Resumen de lo que quedará en el registro de accesos.
class QuedaraRegistrado extends StatelessWidget {
  const QuedaraRegistrado({
    super.key,
    required this.texto,
    required this.proposito,
  });

  final String texto;
  final String? proposito;

  @override
  Widget build(BuildContext context) {
    return TarjetaVitalys(
      relleno: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radio: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: ColoresVitalys.textoSecundario,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quedará registrado como',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: ColoresVitalys.textoSecundario,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  proposito == null ? texto : '$texto · $proposito',
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un ícono por propósito, para reconocerlos de un vistazo.
IconData iconoDe(Proposito p) => switch (p) {
  Proposito.seguimientoReingreso => Icons.trending_up_rounded,
  Proposito.consultaHistoria => Icons.menu_book_outlined,
  Proposito.atencionPaciente => Icons.medical_services_outlined,
  Proposito.revisionCalidad => Icons.fact_check_outlined,
  Proposito.urgencia => Icons.emergency_outlined,
};

/// Una opción del propósito: ícono, nombre, descripción y radio.
class OpcionProposito extends StatelessWidget {
  const OpcionProposito({
    super.key,
    required this.proposito,
    required this.elegido,
    required this.onTap,
    this.compacto = false,
  });

  final Proposito proposito;
  final bool elegido;
  final VoidCallback onTap;

  /// Más bajita, para pantallas chicas.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final urgencia = proposito == Proposito.urgencia;
    final colorActivo = urgencia
        ? ColoresVitalys.advertenciaTexto
        : ColoresVitalys.primario;
    final fondoIcono = urgencia
        ? ColoresVitalys.advertenciaFondo
        : ColoresVitalys.fondoLavanda;
    final lado = compacto ? 36.0 : 40.0;
    return Semantics(
      checked: elegido,
      inMutuallyExclusiveGroup: true,
      label: '${proposito.nombre}. ${proposito.descripcion}',
      excludeSemantics: true,
      child: AnilloFoco(
        radio: BorderRadius.circular(18),
        child: Material(
          color: elegido ? fondoIcono : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: elegido ? colorActivo : ColoresVitalys.bordeControl,
              width: elegido ? 1.8 : 1.2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(compacto ? 10 : 12),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Container(
                      width: lado,
                      height: lado,
                      decoration: BoxDecoration(
                        color: elegido ? Colors.white : fondoIcono,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconoDe(proposito),
                        size: 20,
                        color: colorActivo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proposito.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: compacto ? 14 : 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proposito.descripcion,
                            maxLines: compacto ? 1 : null,
                            overflow: compacto ? TextOverflow.ellipsis : null,
                            style: TextStyle(
                              fontSize: compacto ? 12 : 12.5,
                              color: ColoresVitalys.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      elegido
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: elegido ? colorActivo : ColoresVitalys.textoSuave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
