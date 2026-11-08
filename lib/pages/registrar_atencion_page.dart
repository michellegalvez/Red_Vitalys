import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Lo que el médico llenó en el formulario de una atención (F-04).
typedef NuevaAtencion = ({
  EncounterType tipo,
  String sedeId,
  DateTime fecha,
  String motivo,
  String diagnostico,
});

const mensajeCompleteAtencion = 'Complete el motivo y el diagnóstico';
const mensajeFechaFutura = 'La fecha no puede ser futura';
const mensajeFechaInvalida = 'Escriba la fecha como 30/10/2026 10:42';

/// Formulario para registrar una atención (F-04). Solo captura: valida lo que
/// el médico escribió y lo reporta con [onGuardar]; la Screen anfitriona
/// guarda la atención. Lo único que recuerda es lo que se está escribiendo.
class RegistrarAtencionPage extends StatefulWidget {
  const RegistrarAtencionPage({
    super.key,
    required this.nombrePaciente,
    required this.proposito,
    required this.medico,
    required this.sedes,
    required this.sedeInicialId,
    required this.ahora,
    required this.onGuardar,
    required this.onCancelar,
  });

  final String nombrePaciente;
  final Proposito proposito;

  /// Quién registra, que es el usuario con sesión iniciada.
  final String medico;

  /// Las sedes de la red donde se puede registrar.
  final List<Sede> sedes;

  /// La sede de la sesión, propuesta por defecto.
  final String sedeInicialId;

  /// La fecha y hora de hoy, propuestas por defecto.
  final DateTime ahora;
  final ValueChanged<NuevaAtencion> onGuardar;
  final VoidCallback onCancelar;

  @override
  State<RegistrarAtencionPage> createState() => _RegistrarAtencionPageState();
}

class _RegistrarAtencionPageState extends State<RegistrarAtencionPage> {
  late final _fecha = TextEditingController(
    text: formatoFechaHoraCampo(widget.ahora),
  );
  final _motivo = TextEditingController();
  final _diagnostico = TextEditingController();
  late String _sedeId = widget.sedeInicialId;
  EncounterType _tipo = EncounterType.consultaExterna;
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _fecha.dispose();
    _motivo.dispose();
    _diagnostico.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (_motivo.text.trim().isEmpty || _diagnostico.text.trim().isEmpty) {
      setState(() => _error = mensajeCompleteAtencion);
      return;
    }
    final fecha = leerFechaHoraCampo(_fecha.text);
    if (fecha == null) {
      setState(() => _error = mensajeFechaInvalida);
      return;
    }
    if (fecha.isAfter(widget.ahora)) {
      setState(() => _error = mensajeFechaFutura);
      return;
    }
    setState(() {
      _error = null;
      _guardando = true;
    });
    // El guardado es simulado; se nota el estado "Guardando atención…".
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    widget.onGuardar((
      tipo: _tipo,
      sedeId: _sedeId,
      fecha: fecha,
      motivo: _motivo.text.trim(),
      diagnostico: _diagnostico.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ContenidoPagina(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onCancelar,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text('${widget.nombrePaciente}  /  Nueva atención'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoPagina(
                  sobretitulo: 'Nueva atención',
                  titulo: 'Registrar atención',
                  subtitulo:
                      'De ${widget.nombrePaciente}. Propósito: '
                      '${widget.proposito.nombreCorto}. Queda en su historia '
                      'unificada.',
                ),
                const SizedBox(height: 22),
                _formulario(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formulario() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColoresVitalys.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tipo de atención',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (tipo, texto) in const [
                (EncounterType.consultaExterna, 'Consulta externa'),
                (EncounterType.urgencias, 'Urgencias'),
                (EncounterType.hospitalizacion, 'Hospitalización'),
              ])
                FiltroPildora(
                  texto: texto,
                  seleccionado: _tipo == tipo,
                  onTap: () => setState(() => _tipo = tipo),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SelectorVitalys<String>(
            etiqueta: 'Sede de la atención',
            ayuda: 'Por defecto, la sede de su sesión.',
            valor: _sedeId,
            opciones: [for (final s in widget.sedes) (s.id, s.nombre)],
            onChanged: (id) => setState(() => _sedeId = id ?? _sedeId),
          ),
          const SizedBox(height: 18),
          CampoTexto(
            etiqueta: 'Fecha y hora',
            ayuda: 'Por defecto, la actual. Formato 30/10/2026 10:42.',
            controller: _fecha,
          ),
          const SizedBox(height: 18),
          CampoTexto(
            etiqueta: 'Motivo de consulta',
            controller: _motivo,
            hint: 'Por qué consulta el paciente',
            lineas: 2,
          ),
          const SizedBox(height: 18),
          CampoTexto(
            etiqueta: 'Diagnóstico',
            controller: _diagnostico,
            hint: 'Por ejemplo, I10 Hipertensión esencial',
            lineas: 2,
          ),
          const SizedBox(height: 18),
          Text(
            'Médico: ${widget.medico}',
            style: const TextStyle(
              fontSize: 13.5,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Aviso(tipo: TipoAviso.errores, texto: _error!),
          ],
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 10,
            children: [
              BotonVitalys(
                texto: 'Cancelar',
                variante: VarianteBoton.secundario,
                onPressed: _guardando ? null : widget.onCancelar,
              ),
              BotonVitalys(
                texto: _guardando
                    ? 'Guardando atención…'
                    : 'Registrar atención',
                icono: Icons.check_rounded,
                onPressed: _guardando ? null : _guardar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
