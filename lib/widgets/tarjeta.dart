import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

/// La superficie blanca con borde de la galería. Todas las tarjetas de la
/// app se arman con ella, para que el radio, el borde y el relleno sean los
/// mismos en todas las pantallas.
class TarjetaVitalys extends StatelessWidget {
  const TarjetaVitalys({
    super.key,
    required this.child,
    this.relleno = const EdgeInsets.all(20),
    this.margen,
    this.radio = radioTarjeta,
    this.color = ColoresVitalys.superficie,
    this.colorBorde = ColoresVitalys.borde,
  });

  /// Radio de las tarjetas grandes; las filas y tarjetas pequeñas usan
  /// [radioFila].
  static const double radioTarjeta = 24;
  static const double radioFila = 18;

  final Widget child;
  final EdgeInsetsGeometry relleno;
  final EdgeInsetsGeometry? margen;
  final double radio;
  final Color color;
  final Color colorBorde;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margen,
      padding: relleno,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: colorBorde),
      ),
      child: child,
    );
  }
}

/// La píldora de la galería: un texto corto, con ícono opcional, sobre un
/// fondo de color. Se usa para sedes, permisos, marcas y estados.
class ChipVitalys extends StatelessWidget {
  const ChipVitalys({
    super.key,
    required this.texto,
    this.icono,
    this.colorFondo = ColoresVitalys.fondoLavanda,
    this.colorTexto = ColoresVitalys.primario,
    this.tamanoTexto = 13,
  });

  final String texto;
  final IconData? icono;
  final Color colorFondo;
  final Color colorTexto;
  final double tamanoTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 16, color: colorTexto),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: tamanoTexto,
                fontWeight: FontWeight.w700,
                color: colorTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que se ve cuando una lista no tiene nada que mostrar: un ícono, un
/// título y, si hace falta, qué puede hacer el usuario.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.titulo,
    this.detalle,
    this.icono = Icons.inbox_outlined,
  });

  final String titulo;
  final String? detalle;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: TarjetaVitalys(
        relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(icono, size: 36, color: ColoresVitalys.textoSecundario),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ColoresVitalys.tinta,
              ),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ColoresVitalys.textoSecundario),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
