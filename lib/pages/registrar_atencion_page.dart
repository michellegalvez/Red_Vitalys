import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/barra_volver.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';
import 'package:red_vitalys/widgets/tipo_atencion.dart';

export 'package:red_vitalys/reglas/atencion.dart'
    show
        NuevaAtencion,
        atencionDeFormulario,
        ordenarAtenciones,
        mensajeAltaAnterior,
        mensajeElijaTipoAtencion,
        mensajeFechaFutura,
        mensajeFechaInvalida,
        mensajeIndiqueFechaInicio;

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

  /// La fecha y hora de hoy: de ahí sale qué fecha ya es futura.
  final DateTime ahora;

  /// Guarda la atención y devuelve el mensaje de error, o `null` si se
  /// guardó (F-04, F-20). Con error se conserva lo escrito.
  final String? Function(NuevaAtencion) onGuardar;
  final VoidCallback onCancelar;

  @override
  State<RegistrarAtencionPage> createState() => _RegistrarAtencionPageState();
}

class _RegistrarAtencionPageState extends State<RegistrarAtencionPage> {
  final _inicio = TextEditingController();
  final _alta = TextEditingController();
  late String _sedeId = widget.sedeInicialId;
  EncounterType? _tipo;
  String _destino = destinoSinDefinir;
  ValidacionAtencion? _validacion;
  String? _errorGuardado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _alta.addListener(_altaCambio);
  }

  /// El destino solo se elige con fecha de alta; sin ella vuelve a *Sin
  /// definir* (F-04).
  void _altaCambio() {
    setState(() {
      if (_alta.text.trim().isEmpty) _destino = destinoSinDefinir;
    });
  }

  @override
  void dispose() {
    _alta.removeListener(_altaCambio);
    _inicio.dispose();
    _alta.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final validacion = validarAtencion(
      tipo: _tipo,
      inicioTexto: _inicio.text,
      altaTexto: _alta.text,
      ahora: widget.ahora,
    );
    final tipo = _tipo;
    final inicio = validacion.inicio;
    if (!validacion.sirve || tipo == null || inicio == null) {
      setState(() {
        _validacion = validacion;
        _errorGuardado = null;
      });
      return;
    }
    // Se toma la copia antes de esperar: lo validado es lo que se guarda.
    final nueva = (
      tipo: tipo,
      sedeId: _sedeId,
      inicio: inicio,
      alta: validacion.alta,
      destino: _destino,
    );
    setState(() {
      _validacion = null;
      _errorGuardado = null;
      _guardando = true;
    });
    // El guardado es simulado; se nota el estado "Guardando atención…".
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final error = widget.onGuardar(nueva);
    if (error != null) {
      setState(() {
        _errorGuardado = error;
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContenidoPagina(
      children: [
        BarraVolver(
          texto: '${widget.nombrePaciente}  /  Nueva atención',
          onPressed: widget.onCancelar,
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
    final v = _validacion;
    final faltantes = v?.faltantes ?? const <String>[];
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (faltantes.isNotEmpty) ...[
            Aviso(
              tipo: TipoAviso.errores,
              texto: 'Revise estos ${faltantes.length} datos para continuar',
              items: faltantes,
            ),
            const SizedBox(height: 18),
          ],
          const Text(
            'Tipo de atención',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SelectorTipoAtencion(
            valor: _tipo,
            onChanged: _guardando ? null : (t) => setState(() => _tipo = t),
          ),
          const SizedBox(height: 18),
          SelectorVitalys<String>(
            etiqueta: 'Sede de la atención',
            ayuda: 'Por defecto, la sede de su sesión.',
            valor: _sedeId,
            opciones: [for (final s in widget.sedes) (s.id, s.nombre)],
            onChanged: _guardando
                ? null
                : (id) => setState(() => _sedeId = id ?? _sedeId),
          ),
          const SizedBox(height: 18),
          CampoTexto(
            etiqueta: 'Fecha de inicio',
            ayuda: 'Obligatoria. Por ejemplo, 30 oct 2026.',
            hint: '30 oct 2026',
            controller: _inicio,
            maxLength: 12,
            teclado: TextInputType.datetime,
            error: v?.errorInicio,
            habilitado: !_guardando,
          ),
          const SizedBox(height: 18),
          CampoTexto(
            etiqueta: 'Fecha de alta',
            ayuda: 'Opcional, si el paciente ya salió.',
            hint: '30 oct 2026',
            controller: _alta,
            maxLength: 12,
            teclado: TextInputType.datetime,
            error: v?.errorAlta,
            habilitado: !_guardando,
          ),
          const SizedBox(height: 18),
          SelectorVitalys<String>(
            etiqueta: 'Destino al alta',
            valor: _destino,
            opciones: [for (final d in destinosAlta) (d, d)],
            ayuda: 'Se elige cuando hay fecha de alta.',
            onChanged: _guardando || _alta.text.trim().isEmpty
                ? null
                : (d) => setState(() => _destino = d ?? _destino),
          ),
          const SizedBox(height: 18),
          Text(
            'Médico: ${widget.medico}',
            style: const TextStyle(
              fontSize: 13.5,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
          if (_errorGuardado != null) ...[
            const SizedBox(height: 16),
            Aviso(tipo: TipoAviso.errores, texto: _errorGuardado!),
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
                texto: _guardando ? 'Guardando atención…' : 'Guardar atención',
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
