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
      _Fase.cargando => IndicadorCarga(texto: widget.textoCargando),
      _Fase.error => ErrorCarga(
        texto: widget.textoError,
        onReintentar: _reintentar,
        acciones: widget.accionesEnError,
      ),
    };
  }
}

/// La carga de verdad: los datos vienen de Supabase. Muestra [textoCargando]
/// mientras [cargando], [textoError] con *Reintentar* si [hayError], y si no
/// el [child]. La Screen anfitriona es quien trae los datos (P-01).
class CargaRemota extends StatelessWidget {
  const CargaRemota({
    super.key,
    required this.cargando,
    required this.hayError,
    required this.onReintentar,
    required this.textoCargando,
    required this.textoError,
    required this.child,
  });

  final bool cargando;
  final bool hayError;
  final VoidCallback onReintentar;
  final String textoCargando;
  final String textoError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (cargando) return IndicadorCarga(texto: textoCargando);
    if (hayError) {
      return ErrorCarga(texto: textoError, onReintentar: onReintentar);
    }
    return child;
  }
}

/// El "Cargando…" con su indicador.
class IndicadorCarga extends StatelessWidget {
  const IndicadorCarga({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
                texto,
                style: const TextStyle(
                  color: ColoresVitalys.textoSecundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El mensaje de error con *Reintentar* y, si hace falta, otras acciones.
class ErrorCarga extends StatelessWidget {
  const ErrorCarga({
    super.key,
    required this.texto,
    required this.onReintentar,
    this.acciones = const [],
  });

  final String texto;
  final VoidCallback onReintentar;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Aviso(tipo: TipoAviso.errores, texto: texto),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              BotonVitalys(
                texto: textoReintentar,
                icono: Icons.refresh_rounded,
                variante: VarianteBoton.secundario,
                onPressed: onReintentar,
              ),
              ...acciones,
            ],
          ),
        ],
      ),
    );
  }
}
