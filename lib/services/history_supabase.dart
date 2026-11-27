import 'package:flutter/foundation.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/formato/hora_colombia.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/repositorios/auditoria_traduccion.dart';
import 'package:red_vitalys/services/audit_event_not_saved.dart';
import 'package:red_vitalys/services/history_service.dart';
import 'package:red_vitalys/services/remote_ids.dart';
import 'package:red_vitalys/services/session_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads a patient's history, identifiers and stored risk from Supabase.
class HistorySupabase implements HistoryService {
  HistorySupabase(this.client);

  final SupabaseClient client;

  late final _guard = SessionGuard.of(client);

  late final _ids = RemoteIds.of(client);

  @override
  bool get isRemote => true;

  @override
  Future<Patient> historyOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  }) async {
    final patientId = await _ids.patientId(patient);
    // The person and the encounters do not depend on each other.
    final results = await Future.wait<Object>([
      _person(patientId),
      _encounters(patientId),
    ]);
    final person = results[0] as Map<String, dynamic>;
    final rows = results[1] as List<Map<String, dynamic>>;

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
      systemIdentifiers: _identifiers(
        person['identificador_paciente'] as List?,
      ),
      readmissionRisk: null,
      encounters: ordenarAtenciones([
        for (final row in rows) ?_safeEncounter(row),
      ]),
    );
  }

  Future<Map<String, dynamic>> _person(int patientId) async {
    final row = await _guard.run(
      () => client
          .from('paciente')
          .select(
            'fecha_nacimiento, direccion, telefono, '
            'identificador_paciente(numero_identificacion, es_principal, '
            'sistema_origen(nombre))',
          )
          .eq('id_paciente', patientId)
          .maybeSingle(),
    );
    if (row == null) {
      throw StateError('No se encontraron los datos del paciente');
    }
    return row;
  }

  Future<List<Map<String, dynamic>>> _encounters(int patientId) => _guard.run(
    () => client
        .from('atencion')
        .select(
          'id_atencion, tipo_atencion, fecha_inicio, fecha_fin, '
          'destino_alta, sede(nombre_corto), usuario(nombre_completo)',
        )
        .eq('id_paciente', patientId)
        // Ties on the start date keep this order: the latest saved goes
        // first.
        .order('id_atencion', ascending: false),
  );

  @override
  Future<ReadmissionRisk?> riskOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  }) async {
    final patientId = await _ids.patientId(patient);
    final rows = await _guard.run(
      () => client
          .from('atencion')
          .select(
            'fecha_inicio, fecha_fin, '
            'prediccion_reingreso(score_riesgo, fecha_prediccion, '
            'factor_riesgo(id_factor, variable, contribucion))',
          )
          .eq('id_paciente', patientId),
    );
    return _latestRisk(rows);
  }

  @override
  Future<String?> addEncounter(
    PacienteEnSeguimiento patient,
    NuevaAtencion encounter, {
    required String siteName,
    required Proposito purpose,
    required String? sessionSiteName,
  }) async {
    final [siteId, patientId] = await Future.wait([
      _ids.siteId(siteName),
      _ids.patientId(patient),
    ]);
    final sessionSiteId = sessionSiteName == null
        ? null
        : await _ids.siteId(sessionSiteName);
    final end = encounter.alta;
    final Object? id;
    try {
      // The encounter and its audit event, in one transaction (014).
      id = await _guard.run(
        () => client.rpc<dynamic>(
          'registrar_atencion',
          params: {
            'p_id_paciente': patientId,
            'p_id_sede': siteId,
            'p_tipo_atencion': switch (encounter.tipo) {
              EncounterType.hospitalizacion => 'hospitalizacion',
              EncounterType.urgencias => 'urgencias',
              EncounterType.consultaExterna => 'consulta_externa',
            },
            'p_fecha_inicio': textoColombia(encounter.inicio),
            'p_fecha_fin': end == null ? null : textoColombia(end),
            'p_destino_alta': end == null ? null : encounter.destino,
            'p_proposito': propositoATexto(purpose),
            'p_id_sede_sesion': sessionSiteId,
          },
        ),
      );
    } on PostgrestException catch (error) {
      if (error.code == auditEventErrorCode) throw const AuditEventNotSaved();
      rethrow;
    }
    return id == null ? null : 'enc-$id';
  }

  List<SystemIdentifier> _identifiers(List<dynamic>? rows) {
    final others = <SystemIdentifier>[];
    for (final row in (rows ?? const []).cast<Map<String, dynamic>>()) {
      if (row['es_principal'] == true) continue;
      final system = (row['sistema_origen'] as Map?)?['nombre'];
      final number = row['numero_identificacion'];
      if (system is! String || number is! String) {
        debugPrint('Skipped an identifier without its system or number');
        continue;
      }
      others.add(SystemIdentifier(systemName: system, identifier: number));
    }
    others.sort((a, b) => a.systemName.compareTo(b.systemName));
    return others;
  }

  /// An encounter that cannot be read is skipped and logged instead of
  /// leaving the whole history without any (F-02).
  Encounter? _safeEncounter(Map<String, dynamic> row) {
    try {
      return _encounter(row);
    } on Object catch (error) {
      debugPrint('Skipped encounter ${row['id_atencion']}: $error');
      return null;
    }
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
      // Without a discharge date the destination is still to be defined (F-04).
      dischargeDestination: end == null
          ? destinoSinDefinir
          : row['destino_alta'] as String?,
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

  /// The day in Colombia, as the database counts it (America/Bogota).
  DateTime _day(String timestamp) => diaColombia(timestamp);
}
