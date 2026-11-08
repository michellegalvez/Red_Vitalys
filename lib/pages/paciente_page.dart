import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/barra_volver.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/campo_dato.dart';
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

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    final riesgo = historia.readmissionRisk;
    final columnaRiesgo = [
      if (riesgo != null) _SeccionRiesgo(riesgo: riesgo),
      _DatosBasicos(paciente: historia),
    ];
    final atenciones = _SeccionAtenciones(atenciones: historia.encounters);

    return ContenidoPagina(
      children: [
        BarraVolver(
          texto: 'Pacientes  /  ${historia.fullName}',
          onPressed: onVolver,
        ),
        const SizedBox(height: 8),
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
        _chip(paciente.documentDisplay),
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
              const SizedBox(height: 8),
              Text(
                alerta ? 'RIESGO ALTO' : 'SIN ALERTA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: alerta
                      ? const Color(0xFFFCA5A5)
                      : ColoresVitalys.verdeLima,
                ),
              ),
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

/// Contenedor blanco con título, igual para todas las secciones.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, this.detalle, required this.child});

  final String titulo;
  final String? detalle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TarjetaVitalys(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 2),
            Text(
              detalle!,
              style: const TextStyle(
                fontSize: 12.5,
                color: ColoresVitalys.textoSuave,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// El riesgo y sus factores, del que más aporta al que menos (F-07).
class _SeccionRiesgo extends StatelessWidget {
  const _SeccionRiesgo({required this.riesgo});

  final ReadmissionRisk riesgo;

  @override
  Widget build(BuildContext context) {
    final factores = [...riesgo.factors]
      ..sort((a, b) => b.points.abs().compareTo(a.points.abs()));
    final maximo = factores.isEmpty
        ? 1
        : factores.map((f) => f.points.abs()).reduce((a, b) => a > b ? a : b);
    return _Seccion(
      titulo: 'Riesgo de reingreso',
      detalle: riesgo.periodDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (conAlerta(riesgo.score)) ...[
            Aviso(
              tipo: TipoAviso.alerta,
              texto:
                  'Riesgo alto: ${riesgo.score} (la alerta empieza en '
                  '$umbralAlerta).',
            ),
            const SizedBox(height: 14),
          ],
          const Text(
            'Qué factores lo subieron o bajaron',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ColoresVitalys.textoSecundario,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          if (factores.isEmpty)
            const EstadoVacio(
              titulo: 'No hay factores registrados para este paciente',
              icono: Icons.insights_outlined,
            )
          else
            for (final f in factores)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FilaFactor(factor: f, maximo: maximo),
              ),
        ],
      ),
    );
  }
}

class _FilaFactor extends StatelessWidget {
  const _FilaFactor({required this.factor, required this.maximo});

  final RiskFactor factor;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final sube = factor.impact == RiskFactorImpact.sube;
    final color = sube ? ColoresVitalys.alerta : ColoresVitalys.exito;
    final colorTexto = sube ? ColoresVitalys.alerta : ColoresVitalys.mentaTexto;
    final signo = sube ? '+' : '−';
    return Semantics(
      label:
          '${factor.name}, ${sube ? 'sube' : 'baja'} el riesgo '
          '$signo${factor.points.abs()} puntos',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  factor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$signo${factor.points.abs()}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: colorTexto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: factor.points.abs() / maximo,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sube ? 'Aumenta el riesgo' : 'Disminuye el riesgo',
            style: const TextStyle(
              fontSize: 12,
              color: ColoresVitalys.textoSuave,
            ),
          ),
        ],
      ),
    );
  }
}

/// Las atenciones de todas las sedes, de la más reciente a la más antigua
/// (F-02).
class _SeccionAtenciones extends StatelessWidget {
  const _SeccionAtenciones({required this.atenciones});

  final List<Encounter> atenciones;

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Atenciones',
      detalle: atenciones.length == 1
          ? '1 registro'
          : '${atenciones.length} registros',
      child: atenciones.isEmpty
          ? const EstadoVacio(
              titulo: 'Este paciente no tiene atenciones registradas',
              icono: Icons.event_busy_outlined,
            )
          : Column(
              children: [
                for (final a in atenciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TarjetaAtencion(atencion: a),
                  ),
              ],
            ),
    );
  }
}

class _TarjetaAtencion extends StatelessWidget {
  const _TarjetaAtencion({required this.atencion});

  final Encounter atencion;

  @override
  Widget build(BuildContext context) {
    final a = atencion;
    final enCurso = a.status == EncounterStatus.enCurso;
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(14),
      radio: TarjetaVitalys.radioFila,
      color: ColoresVitalys.fondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              ChipVitalys(
                texto: a.statusLabel,
                tamanoTexto: 12,
                colorFondo: enCurso
                    ? ColoresVitalys.advertenciaFondo
                    : ColoresVitalys.exitoFondo,
                colorTexto: enCurso
                    ? ColoresVitalys.advertenciaTexto
                    : ColoresVitalys.mentaTexto,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${a.facilityName} · ${formatoFechaHora(a.startDate)}'
            '${a.lengthOfStayDays != null && a.lengthOfStayDays! > 0 ? ' · ${formatoEstancia(a.lengthOfStayDays!)}' : ''}',
            style: const TextStyle(
              fontSize: 13,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          DatoEnLinea(etiqueta: 'Médico', valor: a.doctorName),
          if (a.reason != null)
            DatoEnLinea(etiqueta: 'Motivo', valor: a.reason!),
          if (a.diagnosis != null)
            DatoEnLinea(etiqueta: 'Diagnóstico', valor: a.diagnosis!),
        ],
      ),
    );
  }
}

/// Datos básicos del paciente y su identificador en cada sistema (F-03).
class _DatosBasicos extends StatelessWidget {
  const _DatosBasicos({required this.paciente});

  final Patient paciente;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    return _Seccion(
      titulo: 'Datos básicos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampoDato('Edad y sexo', '${p.age} años · ${p.sex}', separacion: 12),
          CampoDato('Documento', p.documentDisplay, separacion: 12),
          CampoDato(
            'Fecha de nacimiento',
            formatoFecha(p.birthDate),
            separacion: 12,
          ),
          CampoDato('Teléfono', p.phone, separacion: 12),
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
                    i.identifier,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
