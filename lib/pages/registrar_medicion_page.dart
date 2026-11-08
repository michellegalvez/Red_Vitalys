import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Lo que el administrativo llenó en el formulario de una medición (F-12).
typedef NuevaMedicion = ({
  IdIndicador indicador,
  String sedeId,
  DateTime periodo,
  String valorTexto,
});

/// Una medición registrada en esta sesión, para mostrarla debajo.
typedef MedicionRegistrada = ({
  Indicador indicador,
  String sede,
  DateTime periodo,
  double valor,
  String registradaPor,
  DateTime registradaEn,
});

const mensajeMedicionRegistrada = 'Medición registrada';

/// Formulario para registrar la medición mensual de un indicador (F-12).
///
/// Solo captura: [validar] decide si el dato sirve (las reglas viven en un
/// único lugar, AD-11) y [onGuardar] avisa a la Screen anfitriona, que la
/// guarda. Lo único que recuerda es lo que se está escribiendo.
class RegistrarMedicionPage extends StatefulWidget {
  const RegistrarMedicionPage({
    super.key,
    required this.sedes,
    required this.hoy,
    required this.registradas,
    required this.validar,
    required this.onGuardar,
  });

  /// Todas las sedes de la red: puede registrar en cualquiera (F-12). Si el
  /// indicador no aplica a la sede, se rechaza (RF-30).
  final List<Sede> sedes;
  final DateTime hoy;

  /// Las mediciones que ya registró en esta sesión, la más nueva primero.
  final List<MedicionRegistrada> registradas;

  /// Devuelve el mensaje de rechazo o `null` si se puede guardar.
  final String? Function(NuevaMedicion) validar;

  /// Guarda la medición y devuelve el mensaje de error, o `null` si se
  /// guardó (F-12). Con error se conserva lo escrito.
  final String? Function(NuevaMedicion) onGuardar;

  @override
  State<RegistrarMedicionPage> createState() => _RegistrarMedicionPageState();
}

class _RegistrarMedicionPageState extends State<RegistrarMedicionPage> {
  final _valor = TextEditingController();
  IdIndicador _indicador = IdIndicador.reingreso;
  late String _sedeId = widget.sedes.first.id;
  late DateTime _periodo = ultimoPeriodo(widget.hoy);
  String? _error;
  String? _exito;
  bool _guardando = false;

  /// El mes de hoy y los 11 anteriores, para poder probar que uno sin
  /// terminar se rechaza.
  late final List<DateTime> _meses = [
    for (var i = 0; i < 12; i++)
      DateTime(widget.hoy.year, widget.hoy.month - i),
  ];

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  NuevaMedicion get _nueva => (
    indicador: _indicador,
    sedeId: _sedeId,
    periodo: _periodo,
    valorTexto: _valor.text,
  );

  Future<void> _guardar() async {
    if (_guardando) return;
    // Se toma la copia antes de esperar: lo validado es lo que se guarda.
    final nueva = _nueva;
    final error = widget.validar(nueva);
    if (error != null) {
      setState(() {
        _error = error;
        _exito = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _exito = null;
      _guardando = true;
    });
    // El guardado es simulado; se nota el estado "Guardando medición…".
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final fallo = widget.onGuardar(nueva);
    if (fallo != null) {
      setState(() {
        _guardando = false;
        _error = fallo;
      });
      return;
    }
    setState(() {
      _guardando = false;
      _exito = mensajeMedicionRegistrada;
      _valor.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final indicador = indicadorDe(_indicador);
    return ContenidoPagina(
      children: [
        const EncabezadoPagina(
          sobretitulo: 'Calidad de la red',
          titulo: 'Registrar medición mensual',
          subtitulo:
              'Digite el valor que ya calculó la sede para un mes cerrado. La '
              'app no lo calcula. Una medición registrada no se edita ni se '
              'borra.',
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _formulario(indicador),
                if (widget.registradas.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  Semantics(
                    header: true,
                    child: Text(
                      'Registradas en esta sesión',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ya forman parte del tablero y de las mediciones '
                    'recientes del indicador.',
                    style: TextStyle(color: ColoresVitalys.textoSecundario),
                  ),
                  const SizedBox(height: 12),
                  for (final r in widget.registradas)
                    _FilaRegistrada(medicion: r),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formulario(Indicador indicador) {
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectorVitalys<IdIndicador>(
            etiqueta: 'Indicador',
            ayuda: indicador.descripcion,
            valor: _indicador,
            opciones: [for (final i in indicadores) (i.id, i.nombre)],
            onChanged: _guardando
                ? null
                : (v) => setState(() {
                    _indicador = v ?? _indicador;
                    _error = null;
                    _exito = null;
                  }),
          ),
          const SizedBox(height: 18),
          SelectorVitalys<String>(
            etiqueta: 'Sede',
            ayuda: 'Puede registrar la de cualquier sede de la red.',
            valor: _sedeId,
            opciones: [for (final s in widget.sedes) (s.id, s.nombre)],
            onChanged: _guardando
                ? null
                : (v) => setState(() {
                    _sedeId = v ?? _sedeId;
                    _error = null;
                    _exito = null;
                  }),
          ),
          const SizedBox(height: 18),
          SelectorVitalys<DateTime>(
            etiqueta: 'Mes',
            ayuda: 'Un mes se puede registrar cuando termina.',
            valor: _periodo,
            opciones: [for (final m in _meses) (m, formatoPeriodo(m))],
            onChanged: _guardando
                ? null
                : (v) => setState(() {
                    _periodo = v ?? _periodo;
                    _error = null;
                    _exito = null;
                  }),
          ),
          const SizedBox(height: 18),
          CampoTexto(
            etiqueta: 'Valor (${indicador.unidad})',
            ayuda:
                '${textoRango(indicador)}, con hasta 1 decimal. Por ejemplo, '
                '8,5.',
            controller: _valor,
            habilitado: !_guardando,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _guardar(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Aviso(tipo: TipoAviso.errores, texto: _error!),
          ],
          if (_exito != null) ...[
            const SizedBox(height: 16),
            Aviso(tipo: TipoAviso.informativo, texto: _exito!),
          ],
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: BotonVitalys(
              texto: _guardando ? 'Guardando medición…' : 'Registrar medición',
              icono: Icons.check_rounded,
              onPressed: _guardando ? null : _guardar,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaRegistrada extends StatelessWidget {
  const _FilaRegistrada({required this.medicion});

  final MedicionRegistrada medicion;

  @override
  Widget build(BuildContext context) {
    final m = medicion;
    return TarjetaVitalys(
      margen: const EdgeInsets.only(bottom: 10),
      relleno: const EdgeInsets.all(14),
      radio: TarjetaVitalys.radioFila,
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: ColoresVitalys.exito),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.indicador.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.sede} · ${formatoPeriodo(m.periodo)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColoresVitalys.textoSecundario,
                  ),
                ),
                Text(
                  'Registró ${m.registradaPor} · '
                  '${formatoFechaHora(m.registradaEn)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColoresVitalys.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${formatoValor(m.valor)} ${m.indicador.unidad}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
