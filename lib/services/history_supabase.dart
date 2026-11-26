import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/services/history_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads a patient's history, identifiers and stored risk from Supabase.
class HistorySupabase implements HistoryService {
  HistorySupabase(this.client);

  final SupabaseClient client;

  @override
  bool get isRemote => true;

  @override
  Future<Patient> historyOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  }) async {
    final patientId = await _patientId(patient);
    final person = await client
        .from('paciente')
        .select(
          'fecha_nacimiento, direccion, telefono, '
          'identificador_paciente(numero_identificacion, es_principal, '
          'sistema_origen(nombre))',
        )
        .eq('id_paciente', patientId)
        .single();
    final rows = await client
        .from('atencion')
        .select(
          'id_atencion, tipo_atencion, fecha_inicio, fecha_fin, destino_alta, '
          'sede(nombre_corto), usuario(nombre_completo), '
          'prediccion_reingreso(score_riesgo, fecha_prediccion, '
          'factor_riesgo(id_factor, variable, contribucion))',
        )
        .eq('id_paciente', patientId);

    return Patient(
      id: 'pac-${patient.id}',
      fullName: patient.nombre,
      age: patient.edad,
      sex: patient.sexo == 'M' ? 'Masculino' : 'Femenino',
      documentType: patient.tipoDocumento,
      documentNumber: patient.numeroDocumento,
      birthDate: DateTime.parse(person['fecha_nacimiento'] as String),
      phone: person['telefono'] as String? ?? 'No registrado',
      address: person['direccion'] as String? ?? 'No registrada',
      systemIdentifiers: _identifiers(person['identificador_paciente'] as List),
      readmissionRisk: _latestRisk(rows),
      encounters: ordenarAtenciones([for (final row in rows) _encounter(row)]),
    );
  }

  Future<int> _patientId(PacienteEnSeguimiento patient) async {
    if (patient.id.startsWith('db')) {
      return int.parse(patient.id.substring(2));
    }
    final row = await client
        .from('identificador_paciente')
        .select('id_paciente')
        .eq('numero_identificacion', patient.numeroDocumento)
        .eq('es_principal', true)
        .single();
    return row['id_paciente'] as int;
  }

  List<SystemIdentifier> _identifiers(List<dynamic> rows) {
    final others = [
      for (final row in rows.cast<Map<String, dynamic>>())
        if (row['es_principal'] != true)
          SystemIdentifier(
            systemName: (row['sistema_origen'] as Map)['nombre'] as String,
            identifier: row['numero_identificacion'] as String,
          ),
    ];
    others.sort((a, b) => a.systemName.compareTo(b.systemName));
    return others;
  }

  Encounter _encounter(Map<String, dynamic> row) {
    final start = _day(row['fecha_inicio'] as String);
    final endText = row['fecha_fin'] as String?;
    final end = endText == null ? null : _day(endText);
    return Encounter(
      id: 'enc-${row['id_atencion']}',
      type: switch (row['tipo_atencion']) {
        'urgencias' => EncounterType.urgencias,
        'consulta_externa' => EncounterType.consultaExterna,
        _ => EncounterType.hospitalizacion,
      },
      status: end == null
          ? EncounterStatus.enCurso
          : EncounterStatus.finalizada,
      facilityName: (row['sede'] as Map?)?['nombre_corto'] as String? ?? '—',
      startDate: start,
      endDate: end,
      lengthOfStayDays: end?.difference(start).inDays,
      dischargeDestination: row['destino_alta'] as String?,
      doctorName:
          (row['usuario'] as Map?)?['nombre_completo'] as String? ?? '—',
    );
  }

  ReadmissionRisk? _latestRisk(List<Map<String, dynamic>> encounters) {
    Map<String, dynamic>? prediction;
    Map<String, dynamic>? encounter;
    for (final row in encounters) {
      for (final item in (row['prediccion_reingreso'] as List? ?? const [])) {
        final candidate = item as Map<String, dynamic>;
        final date = candidate['fecha_prediccion'] as String;
        final best = prediction?['fecha_prediccion'] as String?;
        if (best == null || date.compareTo(best) > 0) {
          prediction = candidate;
          encounter = row;
        }
      }
    }
    if (prediction == null || encounter == null) return null;
    final factors =
        (prediction['factor_riesgo'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => (a['id_factor'] as int).compareTo(b['id_factor'] as int),
          );
    final start = _day(encounter['fecha_inicio'] as String);
    final end = _day(
      (encounter['fecha_fin'] ?? encounter['fecha_inicio']) as String,
    );
    return ReadmissionRisk(
      score: num.parse(prediction['score_riesgo'].toString()).round(),
      calculatedDate: DateTime.parse(prediction['fecha_prediccion'] as String),
      periodDescription:
          'calculado del ${formatoFecha(start)} al ${formatoFecha(end)}',
      factors: [
        for (final factor in factors)
          RiskFactor(
            name: factor['variable'] as String,
            points: num.parse(factor['contribucion'].toString()).round(),
          ),
      ],
    );
  }

  DateTime _day(String timestamp) {
    final local = DateTime.parse(timestamp).toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
