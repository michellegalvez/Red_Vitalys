import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Anillo de foco visible (WCAG 2.4.7): dibuja un borde de 3 px alrededor
/// de su hijo cuando él o alguno de sus descendientes tiene el foco con el
/// teclado. Un solo widget para todos los controles que se pueden enfocar.
class AnilloFoco extends StatefulWidget {
  const AnilloFoco({
    super.key,
    required this.child,
    this.radio = const BorderRadius.all(Radius.circular(999)),
    this.color = ColoresVitalys.tinta,
  });

  final Widget child;
  final BorderRadius radio;
  final Color color;

  @override
  State<AnilloFoco> createState() => _AnilloFocoState();
}

class _AnilloFocoState extends State<AnilloFoco> {
  // Solo recuerda si hay foco dentro; no es dato de la app.
  bool _enfocado = false;

  @override
  Widget build(BuildContext context) {
    final porTeclado =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) => setState(() => _enfocado = v),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.radio,
          border: _enfocado && porTeclado
              ? Border.all(color: widget.color, width: 3)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
