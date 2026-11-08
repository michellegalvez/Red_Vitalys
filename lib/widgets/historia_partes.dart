import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/campo_dato.dart';
import 'package:red_vitalys/widgets/carga.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';
import 'package:red_vitalys/widgets/tipo_atencion.dart';

/// Contenedor blanco con título, igual para todas las secciones de la
/// historia.
class SeccionHistoria extends StatelessWidget {
  const SeccionHistoria({
    super.key,
    required this.titulo,
    this.detalle,
    required this.child,
  });

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

/// "29 sep 2026" o, con alta, "29 sep 2026 – 14 oct 2026" (F-02).
String rangoDeFechas(DateTime inicio, DateTime? alta) => alta == null
    ? formatoFecha(inicio)
    : '${formatoFecha(inicio)} – ${formatoFecha(alta)}';

/// El riesgo y sus factores, del que más pesa al que menos, con el desplegable
/// *Cómo se calcula* (F-07).
class SeccionRiesgo extends StatelessWidget {
  const SeccionRiesgo({
    super.key,
    required this.riesgo,
    required this.simularFallas,
  });

  final ReadmissionRisk riesgo;
  final bool simularFallas;

  @override
  Widget build(BuildContext context) {
    final factores = riesgo.orderedFactors;
    final maximo = factores.isEmpty
        ? 1
        : factores.map((f) => f.points.abs()).reduce((a, b) => a > b ? a : b);
    return SeccionHistoria(
      titulo: 'Riesgo de reingreso',
      detalle: riesgo.periodDescription,
      child: CargaSimulada(
        simular: simularFallas,
        textoCargando: 'Cargando riesgo…',
        textoError: 'No se pudo cargar el riesgo',
        child: _cuerpo(factores, maximo),
      ),
    );
  }

  Widget _cuerpo(List<RiskFactor> factores, int maximo) {
    return Column(
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
        Text(
          'Base del modelo: ${riesgo.basePoints} puntos',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ColoresVitalys.textoSecundario,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Los factores suman o restan a esa base hasta llegar a '
          '${riesgo.score}.',
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: ColoresVitalys.textoSecundario,
          ),
        ),
        const SizedBox(height: 12),
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
        const ComoSeCalcula(),
      ],
    );
  }
}

/// Desplegable que explica que el puntaje y los factores son simulados y que
/// la app no los calcula (F-07, AD-10).
class ComoSeCalcula extends StatefulWidget {
  const ComoSeCalcula({super.key});

  @override
  State<ComoSeCalcula> createState() => _ComoSeCalculaState();
}

class _ComoSeCalculaState extends State<ComoSeCalcula> {
  // Solo recuerda si está abierto; no es dato de la app.
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _abierto,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _abierto = !_abierto),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: ColoresVitalys.primario,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cómo se calcula',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: ColoresVitalys.primario,
                      ),
                    ),
                  ),
                  Icon(
                    _abierto
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ColoresVitalys.primario,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_abierto)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'El puntaje y los factores son simulados. La app no los '
              'calcula: los muestra tal como están guardados.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: ColoresVitalys.textoSecundario,
              ),
            ),
          ),
      ],
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
            sube ? 'Sube' : 'Baja',
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
class SeccionAtenciones extends StatelessWidget {
  const SeccionAtenciones({super.key, required this.atenciones});

  final List<Encounter> atenciones;

  @override
  Widget build(BuildContext context) {
    return SeccionHistoria(
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
                    child: TarjetaAtencion(atencion: a),
                  ),
              ],
            ),
    );
  }
}

/// Una atención: tipo con ícono, estado, sede, fechas, duración, destino al
/// alta y médico (F-02).
class TarjetaAtencion extends StatelessWidget {
  const TarjetaAtencion({super.key, required this.atencion});

  final Encounter atencion;

  @override
  Widget build(BuildContext context) {
    final a = atencion;
    final enCurso = a.status == EncounterStatus.enCurso;
    final dias = a.lengthOfStayDays;
    final destino = a.dischargeDestination;
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(14),
      radio: TarjetaVitalys.radioFila,
      color: ColoresVitalys.fondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconoTipoAtencion(a.type), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  a.typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
            a.facilityName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
          Text(
            rangoDeFechas(a.startDate, a.endDate),
            style: const TextStyle(
              fontSize: 13,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          if (dias != null)
            DatoEnLinea(etiqueta: 'Duración', valor: formatoEstancia(dias)),
          if (destino != null) DatoEnLinea(etiqueta: 'Destino', valor: destino),
          DatoEnLinea(etiqueta: 'Médico', valor: a.doctorName),
        ],
      ),
    );
  }
}
