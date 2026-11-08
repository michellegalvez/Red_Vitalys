import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/enmascarado.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/barra_volver.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/campo_dato.dart';
import 'package:red_vitalys/widgets/carga.dart';
import 'package:red_vitalys/widgets/historia_partes.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Historia clínica unificada de un paciente con su riesgo de reingreso y los
/// factores que lo explican (F-02, F-03, F-07), con la opción de registrar una
/// atención (F-04). Solo muestra y avisa: abrirla, volver y registrar lo
/// decide la Screen anfitriona.
class PacientePage extends StatelessWidget {
  const PacientePage({
    super.key,
    required this.historia,
    required this.proposito,
    required this.fechaConsulta,
    required this.puedeRegistrar,
    required this.onVolver,
    required this.onRegistrarAtencion,
    this.simularFallas = false,
  });

  final Patient historia;

  /// El propósito con el que se abrió; con *Urgencia* se avisa que es una
  /// emergencia (F-17).
  final Proposito proposito;
  final String fechaConsulta;

  /// Solo el médico registra atenciones (F-04, F-18).
  final bool puedeRegistrar;
  final VoidCallback onVolver;
  final VoidCallback onRegistrarAtencion;

  /// Modo demo: la historia y el riesgo muestran su carga y su error con
  /// *Reintentar*.
  final bool simularFallas;

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    final riesgo = historia.readmissionRisk;
    final columnaRiesgo = [
      if (riesgo != null)
        SeccionRiesgo(riesgo: riesgo, simularFallas: simularFallas),
      _DatosBasicos(paciente: historia),
    ];
    final atenciones = SeccionAtenciones(atenciones: historia.encounters);

    return ContenidoPagina(
      children: [
        BarraVolver(
          texto: 'Pacientes  /  ${historia.fullName}',
          onPressed: onVolver,
        ),
        const SizedBox(height: 8),
        CargaSimulada(
          simular: simularFallas,
          textoCargando: 'Cargando historia…',
          textoError: 'No se pudo cargar la historia',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (proposito == Proposito.urgencia) ...[
                const Aviso(
                  tipo: TipoAviso.advertencia,
                  texto: avisoAccesoEmergencia,
                ),
                const SizedBox(height: 14),
              ],
              _Cabecera(
                paciente: historia,
                proposito: proposito,
                fechaConsulta: fechaConsulta,
                puedeRegistrar: puedeRegistrar,
                onRegistrarAtencion: onRegistrarAtencion,
              ),
              const SizedBox(height: 18),
              if (escritorio)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _apilar(columnaRiesgo)),
                    const SizedBox(width: 18),
                    Expanded(child: atenciones),
                  ],
                )
              else
                _apilar([
                  ...columnaRiesgo.take(1),
                  atenciones,
                  ...columnaRiesgo.skip(1),
                ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _apilar(List<Widget> hijos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < hijos.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          hijos[i],
        ],
      ],
    );
  }
}

/// Tarjeta violeta con el nombre, el riesgo y el botón de registrar.
class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.paciente,
    required this.proposito,
    required this.fechaConsulta,
    required this.puedeRegistrar,
    required this.onRegistrarAtencion,
  });

  final Patient paciente;
  final Proposito proposito;
  final String fechaConsulta;
  final bool puedeRegistrar;
  final VoidCallback onRegistrarAtencion;

  @override
  Widget build(BuildContext context) {
    final riesgo = paciente.readmissionRisk;
    final alerta = riesgo != null && conAlerta(riesgo.score);
    final etiquetas = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('${paciente.age} años · ${paciente.sex}'),
        for (final i in paciente.systemIdentifiers) _chip(i.systemName),
      ],
    );
    final anillo = riesgo == null
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnilloRiesgo(riesgo: riesgo.score, tamano: 84),
              ),
              // Con riesgo menor al umbral no hay etiqueta de alerta (F-06).
              if (alerta) ...[
                const SizedBox(height: 8),
                const Text(
                  'RIESGO ALTO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
              ],
            ],
          );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColoresVitalys.violetaHeroInicio,
            ColoresVitalys.violetaHeroFin,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORIA CLÍNICA UNIFICADA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        paciente.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    etiquetas,
                  ],
                ),
              ),
              if (anillo != null) ...[const SizedBox(width: 16), anillo],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Esta consulta queda registrada · Propósito: '
            '${proposito.nombreCorto} · $fechaConsulta',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12.5,
            ),
          ),
          if (puedeRegistrar) ...[
            const SizedBox(height: 16),
            BotonVitalys(
              texto: 'Registrar atención',
              icono: Icons.add_rounded,
              expandido: true,
              onPressed: onRegistrarAtencion,
            ),
          ],
        ],
      ),
    );
  }
}

/// Píldora translúcida sobre el degradado violeta de la cabecera.
Widget _chip(String texto) => ChipVitalys(
  texto: texto,
  colorFondo: Colors.white.withValues(alpha: 0.14),
  colorTexto: Colors.white,
  tamanoTexto: 12.5,
);

/// Datos básicos del paciente y su identificador en cada sistema (F-02,
/// F-03). El documento y los identificadores van enmascarados hasta que el
/// médico elige *Mostrar documentos*; mostrarlos no crea otro evento.
class _DatosBasicos extends StatefulWidget {
  const _DatosBasicos({required this.paciente});

  final Patient paciente;

  @override
  State<_DatosBasicos> createState() => _DatosBasicosState();
}

class _DatosBasicosState extends State<_DatosBasicos> {
  // Solo recuerda si se muestran completos; no es dato de la app.
  bool _mostrar = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.paciente;
    return SeccionHistoria(
      titulo: 'Datos básicos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampoDato('Nombre', p.fullName, separacion: 12),
          CampoDato('Edad y sexo', '${p.age} años · ${p.sex}', separacion: 12),
          CampoDato(
            'Fecha de nacimiento',
            formatoFecha(p.birthDate),
            separacion: 12,
          ),
          CampoDato('Teléfono', p.phone, separacion: 12),
          CampoDato('Dirección', p.address, separacion: 12),
          CampoDato(
            'Documento',
            _mostrar
                ? p.documentDisplay
                : documentoEnmascarado(p.documentType, p.documentNumber),
            separacion: 12,
          ),
          const SizedBox(height: 4),
          const Text(
            'IDENTIFICADORES EN CADA SISTEMA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: ColoresVitalys.textoSuave,
            ),
          ),
          const SizedBox(height: 8),
          for (final i in p.systemIdentifiers)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(i.systemName)),
                  Text(
                    _mostrar
                        ? i.identifier
                        : identificadorEnmascarado(i.identifier),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          BotonVitalys(
            texto: _mostrar ? 'Ocultar documentos' : 'Mostrar documentos',
            icono: _mostrar
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            variante: VarianteBoton.secundario,
            expandido: true,
            onPressed: () => setState(() => _mostrar = !_mostrar),
          ),
        ],
      ),
    );
  }
}
