import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

enum VarianteBoton { principal, secundario, pequeno }

/// Botón de la galería: principal, secundario y pequeño. Sin `onPressed`
/// queda deshabilitado.
class BotonVitalys extends StatelessWidget {
  const BotonVitalys({
    super.key,
    required this.texto,
    required this.onPressed,
    this.variante = VarianteBoton.principal,
    this.icono,
    this.expandido = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final VarianteBoton variante;
  final IconData? icono;

  /// Ocupa todo el ancho disponible.
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null;
    final pequeno = variante == VarianteBoton.pequeno;
    final principal = variante == VarianteBoton.principal;

    final fondo = !habilitado
        ? ColoresVitalys.borde
        : principal
        ? ColoresVitalys.primario
        : Colors.white;
    final colorTexto = !habilitado
        ? ColoresVitalys.textoSuave
        : principal
        ? Colors.white
        : ColoresVitalys.tinta;

    final contenido = Row(
      mainAxisSize: expandido ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icono != null) ...[
          Icon(icono, size: pequeno ? 16 : 20, color: colorTexto),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: pequeno ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: colorTexto,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: habilitado,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: principal && habilitado
              ? [
                  BoxShadow(
                    color: ColoresVitalys.primario.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: fondo,
          shape: StadiumBorder(
            side: principal || !habilitado
                ? BorderSide.none
                : const BorderSide(color: ColoresVitalys.borde, width: 1.2),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: pequeno ? 16 : 26,
                vertical: pequeno ? 9 : 15,
              ),
              child: contenido,
            ),
          ),
        ),
      ),
    );
  }
}
