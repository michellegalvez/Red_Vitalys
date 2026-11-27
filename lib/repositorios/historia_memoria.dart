import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/repositorios/historia_repositorio.dart';

/// Implementación en memoria del repositorio de historia clínica (P-04).
///
/// Trabaja sobre los datos simulados en memoria y permite pruebas unitarias
/// rápidas y aisladas sin requerir conexión de red.
class HistoriaMemoria implements HistoriaRepositorio {
  HistoriaMemoria({
    required this.datos,
    Map<String, List<Encounter>>? atencionesIniciales,
  }) : _atenciones = atencionesIniciales ?? {};

  final DatosSimulados datos;
  final Map<String, List<Encounter>> _atenciones;

  @override
  Future<Patient> obtenerHistoria(String pacienteId) async {
    final paciente = datos.pacientes.firstWhere(
      (p) => p.id == pacienteId,
      orElse: () => throw StateError('Paciente no encontrado: $pacienteId'),
    );
    final sedeAlta =
        datos.sedes
            .where((s) => s.id == paciente.sedeAltaId)
            .map((s) => s.nombreCorto)
            .firstOrNull ??
        '';

    final historia = historiaDe(
      paciente,
      sedeAlta: sedeAlta,
      hoy: datos.hoy,
      nuevas: _atenciones[pacienteId] ?? const [],
    );
    return historia;
  }

  @override
  Future<Encounter> registrarAtencion({
    required String pacienteId,
    required NuevaAtencion nueva,
    required String medicoId,
    required String medicoNombre,
    required Proposito proposito,
  }) async {
    final total = _atenciones.values.fold<int>(0, (a, l) => a + l.length);
    final sede =
        datos.sedes
            .where((s) => s.id == nueva.sedeId)
            .map((s) => s.nombreCorto)
            .firstOrNull ??
        nueva.sedeId;

    final atencion = atencionDeFormulario(
      id: 'enc-n${total + 1}',
      nueva: nueva,
      sede: sede,
      medico: medicoNombre,
    );

    _atenciones[pacienteId] = ordenarAtenciones([
      atencion,
      ...?_atenciones[pacienteId],
    ]);

    return atencion;
  }
}
