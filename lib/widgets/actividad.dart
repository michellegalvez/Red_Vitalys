import 'package:flutter/widgets.dart';

/// Avisa a la Screen anfitriona que el usuario escribió en un campo. El
/// teclado en pantalla del celular no manda teclas ni toques, así que sin esto
/// escribir no contaría como uso para el cierre por inactividad (F-15 CA-2).
class AvisoActividad extends InheritedWidget {
  const AvisoActividad({
    super.key,
    required this.onActividad,
    required super.child,
  });

  final VoidCallback onActividad;

  /// Avisa, si hay una Screen que escuche, que hubo actividad.
  static void avisar(BuildContext context) {
    context.getInheritedWidgetOfExactType<AvisoActividad>()?.onActividad();
  }

  @override
  bool updateShouldNotify(AvisoActividad oldWidget) => false;
}
