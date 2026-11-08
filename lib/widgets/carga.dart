import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';

/// Cuánto dura el "Cargando…" cuando se simulan fallas de red.
const Duration duracionCargaSimulada = Duration(milliseconds: 600);

/// Texto del botón para volver a intentar una carga (specs F-01 a F-22).
const String textoReintentar = 'Reintentar';

/// Los estados de carga y de error de una pantalla o de una sección.
///
/// Los datos del prototipo son locales: sin [simular] se muestra
/// [child] de una vez. Con [simular] (el interruptor *Simular fallas de red*
/// del acceso) se ve [textoCargando], después [textoError] con *Reintentar*
/// y, al reintentar, el contenido. Solo recuerda en qué estado va la carga;
/// los datos los sigue teniendo la Screen anfitriona.
class CargaSimulada extends StatefulWidget {
  const CargaSimulada({
    super.key,
    required this.simular,
    required this.textoCargando,
    required this.textoError,
    required this.child,
    this.accionesEnError = const [],
  });

  final bool simular;
  final String textoCargando;
  final String textoError;
  final Widget child;

  /// Lo que sigue disponible cuando la carga falla, por ejemplo *Cerrar
  /// sesión* en el perfil (F-22).
  final List<Widget> accionesEnError;

  @override
  State<CargaSimulada> createState() => _CargaSimuladaState();
}

enum _Fase { cargando, error, listo }

class _CargaSimuladaState extends State<CargaSimulada> {
  late _Fase _fase = widget.simular ? _Fase.cargando : _Fase.listo;
  bool _yaFallo = false;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    if (_fase == _Fase.cargando) _cargar();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  /// La primera carga falla y la que sigue a *Reintentar* funciona.
  void _cargar() {
    _temporizador?.cancel();
    _temporizador = Timer(duracionCargaSimulada, () {
      if (!mounted) return;
      setState(() {
        _fase = _yaFallo ? _Fase.listo : _Fase.error;
        _yaFallo = true;
      });
    });
  }

  void _reintentar() {
    setState(() => _fase = _Fase.cargando);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_fase) {
      _Fase.listo => widget.child,
      _Fase.cargando => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.textoCargando,
                  style: const TextStyle(
                    color: ColoresVitalys.textoSecundario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      _Fase.error => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Aviso(tipo: TipoAviso.errores, texto: widget.textoError),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                BotonVitalys(
                  texto: textoReintentar,
                  icono: Icons.refresh_rounded,
                  variante: VarianteBoton.secundario,
                  onPressed: _reintentar,
                ),
                ...widget.accionesEnError,
              ],
            ),
          ],
        ),
      ),
    };
  }
}
