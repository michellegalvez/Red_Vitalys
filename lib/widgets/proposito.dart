import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/pacientes.dart';

/// El paciente que se va a abrir al declarar el propósito.
class DestinoPaciente {
  const DestinoPaciente({required this.paciente, required this.sedeAlta});

  final PacienteEnSeguimiento paciente;
  final String sedeAlta;
}

/// Fondo del pop-up: desenfoca lo que hay detrás, lo tiñe de violeta y le
/// suma dos manchas de color. Aparece con un fundido suave.
class FondoDialogo extends StatelessWidget {
  const FondoDialogo({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const ModalBarrier(dismissible: false, color: Colors.transparent),
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: math.max(0.01, 14 * t),
                sigmaY: math.max(0.01, 14 * t),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColoresVitalys.violetaHeroInicio.withValues(
                        alpha: 0.62 * t,
                      ),
                      ColoresVitalys.tinta.withValues(alpha: 0.72 * t),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -140,
              left: -120,
              child: _Mancha(
                color: ColoresVitalys.turquesa.withValues(alpha: 0.38 * t),
                diametro: 460,
              ),
            ),
            Positioned(
              bottom: -170,
              right: -110,
              child: _Mancha(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.5 * t),
                diametro: 520,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Mancha extends StatelessWidget {
  const _Mancha({required this.color, required this.diametro});

  final Color color;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diametro,
        height: diametro,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Diálogo de la galería para declarar el propósito de una consulta (F-16).
/// No guarda nada: el propósito elegido y el error vienen de la Screen.
///
/// Se adapta a la pantalla: en escritorio va en dos columnas (contexto a la
/// izquierda, opciones a la derecha) y en celular es una hoja inferior con
/// los botones siempre a la vista.
class DialogoProposito extends StatelessWidget {
  const DialogoProposito({
    super.key,
    required this.destino,
    required this.propositos,
    required this.elegido,
    required this.error,
    required this.quedaraRegistrado,
    required this.onElegir,
    required this.onConfirmar,
    required this.onCancelar,
  });

  final DestinoPaciente destino;
  final List<Proposito> propositos;
  final Proposito? elegido;
  final String? error;

  /// Quién, desde dónde y cuándo, por ejemplo
  /// "Dra. Camila Martínez · Cali Norte · 30 oct 2026 · 10:42".
  final String quedaraRegistrado;
  final ValueChanged<Proposito> onElegir;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, t, hijo) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: hijo),
      ),
      // Es un diálogo modal: Esc lo cierra, el foco se queda dentro y el
      // lector de pantalla lo anuncia como una ventana propia.
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): onCancelar,
        },
        child: FocusScope(
          autofocus: true,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: 'Declare el propósito de uso',
            child: LayoutBuilder(
              builder: (context, c) {
                final dosColumnas = c.maxWidth >= anchoEscritorio;
                return dosColumnas
                    ? _enEscritorio(c.maxWidth, c.maxHeight)
                    : _enCelular(c.maxHeight);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Escritorio: dos columnas
  // ---------------------------------------------------------------------

  Widget _enEscritorio(double ancho, double alto) {
    final altoDialogo = math.min(alto - 48, 660.0);
    return Center(
      child: SizedBox(
        width: math.min(ancho - 64, 980),
        height: altoDialogo,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          clipBehavior: Clip.antiAlias,
          elevation: 24,
          shadowColor: Colors.black54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 9,
                child: ColoredBox(
                  color: ColoresVitalys.fondo,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Encabezado(),
                        const SizedBox(height: 22),
                        _Contexto(destino: destino),
                        const SizedBox(height: 14),
                        const PorQueSePide(compacto: false),
                        const SizedBox(height: 14),
                        QuedaraRegistrado(
                          texto: quedaraRegistrado,
                          proposito: elegido?.nombreCorto,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
                        child: _opciones(compacto: false),
                      ),
                    ),
                    _Pie(
                      onConfirmar: onConfirmar,
                      onCancelar: onCancelar,
                      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Celular: hoja inferior
  // ---------------------------------------------------------------------

  Widget _enCelular(double alto) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: alto * 0.96),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          elevation: 24,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: const _Encabezado(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Contexto(destino: destino),
                        const SizedBox(height: 10),
                        const PorQueSePide(compacto: true),
                        const SizedBox(height: 16),
                        _opciones(compacto: true),
                        const SizedBox(height: 4),
                        QuedaraRegistrado(
                          texto: quedaraRegistrado,
                          proposito: elegido?.nombreCorto,
                        ),
                      ],
                    ),
                  ),
                ),
                _Pie(
                  onConfirmar: onConfirmar,
                  onCancelar: onCancelar,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// La pregunta, las opciones y los avisos.
  Widget _opciones({required bool compacto}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            '¿Para qué va a abrir a este paciente?',
            style: TextStyle(
              fontSize: compacto ? 16 : 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Elija una opción. Se pregunta cada vez que se abre algo.',
          style: TextStyle(fontSize: 13, color: ColoresVitalys.textoSecundario),
        ),
        SizedBox(height: compacto ? 10 : 14),
        for (final p in propositos)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: OpcionProposito(
              proposito: p,
              elegido: p == elegido,
              compacto: compacto,
              onTap: () => onElegir(p),
            ),
          ),
        if (elegido == Proposito.urgencia) ...[
          const SizedBox(height: 2),
          const Aviso(
            tipo: TipoAviso.advertencia,
            texto: avisoDeclarandoUrgencia,
            items: [
              'Podrá abrirlo aunque no tenga relación con el paciente.',
              'El auditor lo verá marcado como emergencia.',
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (error != null) ...[
          const SizedBox(height: 2),
          Aviso(tipo: TipoAviso.errores, texto: error!),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

/// Botones del diálogo, fijos al pie.
class _Pie extends StatelessWidget {
  const _Pie({
    required this.onConfirmar,
    required this.onCancelar,
    required this.padding,
  });

  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ColoresVitalys.borde)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BotonVitalys(
            texto: 'Cancelar',
            variante: VarianteBoton.secundario,
            onPressed: onCancelar,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: BotonVitalys(
              texto: 'Abrir historia clínica',
              icono: Icons.folder_open_rounded,
              onPressed: onConfirmar,
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C4DFF), ColoresVitalys.primario],
            ),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ANTES DE ABRIR LA HISTORIA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: ColoresVitalys.primario,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Declare el propósito de uso',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El paciente que se va a abrir, con su riesgo.
class _Contexto extends StatelessWidget {
  const _Contexto({required this.destino});

  final DestinoPaciente destino;

  @override
  Widget build(BuildContext context) {
    final paciente = destino.paciente;
    final contenido = Row(
      children: [
        AvatarIniciales(
          iniciales: paciente.iniciales,
          indiceColor: indiceColorDe(paciente.id),
          tamano: 46,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paciente.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${paciente.edad} años · ${paciente.sexo} · '
                '${paciente.documentoOculto} · ${destino.sedeAlta}',
                style: const TextStyle(
                  fontSize: 13,
                  color: ColoresVitalys.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnilloRiesgo(riesgo: paciente.riesgo, tamano: 50),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColoresVitalys.borde),
      ),
      child: contenido,
    );
  }
}

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
    final cabecera = Row(
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
    );
    return Material(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresVitalys.borde),
      ),
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
      label: proposito.nombre,
      child: Material(
        color: elegido ? fondoIcono : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: elegido ? colorActivo : ColoresVitalys.borde,
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
    );
  }
}
