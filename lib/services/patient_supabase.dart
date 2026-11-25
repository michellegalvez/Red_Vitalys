import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the patients, their encounters and their stored risk from Supabase.
class PatientSupabase implements PatientService {
  PatientSupabase({
    required this.client,
    required this.sitesByName,
    required this.usersByEmail,
    required this.patientIdsByDocument,
  });

  final SupabaseClient client;

  final Map<String, String> sitesByName;

  final Map<String, String> usersByEmail;

  final Map<String, String> patientIdsByDocument;

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async {
    final rows = await client
        .from('atencion')
        .select(
          'id_paciente, fecha_inicio, fecha_fin, tipo_atencion, proposito, '
          'sede(nombre), usuario(correo), '
          'prediccion_reingreso(score_riesgo, fecha_prediccion), '
          'paciente(primer_nombre, segundo_nombre, primer_apellido, '
          'segundo_apellido, fecha_nacimiento, sexo, '
          'identificador_paciente(tipo_documento, numero_identificacion, '
          'es_principal))',
        )
        .not('fecha_fin', 'is', null)
        .order('fecha_fin', ascending: false);

    final latest = <int, Map<String, dynamic>>{};
    final doctors = <int, List<String>>{};
    for (final row in rows) {
      final patientId = row['id_paciente'] as int;
      latest.putIfAbsent(patientId, () => row);
      if (row['proposito'] != 'atencion_paciente') continue;
      final doctor = usersByEmail[(row['usuario'] as Map?)?['correo']];
      if (doctor == null) continue;
      final list = doctors.putIfAbsent(patientId, () => []);
      if (!list.contains(doctor)) list.add(doctor);
    }

    return [
      for (final entry in latest.entries)
        ?_toPatient(entry.key, entry.value, doctors[entry.key] ?? [], today),
    ];
  }

  PacienteEnSeguimiento? _toPatient(
    int patientId,
    Map<String, dynamic> row,
    List<String> doctors,
    DateTime today,
  ) {
    final person = row['paciente'] as Map<String, dynamic>?;
    final siteId = sitesByName[(row['sede'] as Map?)?['nombre']];
    final identifier = _mainIdentifier(person);
    final score = _latestScore(row['prediccion_reingreso']);
    if (person == null || siteId == null || identifier == null) return null;
    if (score == null) return null;

    final dischargeUtc = DateTime.parse(row['fecha_fin'] as String);
    final startUtc = DateTime.parse(row['fecha_inicio'] as String);
    final discharge = dischargeUtc.toLocal();
    final start = startUtc.toLocal();
    final number = identifier['numero_identificacion'] as String;
    final firstName = person['primer_nombre'] as String;
    final lastName = person['primer_apellido'] as String;

    return PacienteEnSeguimiento(
      id: patientIdsByDocument[number] ?? 'db$patientId',
      nombre: [
        firstName,
        person['segundo_nombre'],
        lastName,
        person['segundo_apellido'],
      ].whereType<String>().where((part) => part.isNotEmpty).join(' '),
      iniciales: '${firstName[0]}${lastName[0]}'.toUpperCase(),
      edad: _ageAt(DateTime.parse(person['fecha_nacimiento'] as String), today),
      sexo: person['sexo'] as String,
      tipoDocumento: identifier['tipo_documento'] as String,
      numeroDocumento: number,
      sedeAltaId: siteId,
      tipoAtencion: _toEncounterType(row['tipo_atencion'] as String),
      fechaAlta: DateTime(discharge.year, discharge.month, discharge.day),
      diasEstancia: DateTime(
        discharge.year,
        discharge.month,
        discharge.day,
      ).difference(DateTime(start.year, start.month, start.day)).inDays,
      riesgo: score.round(),
      medicosConAtencion: doctors,
    );
  }

  Map<String, dynamic>? _mainIdentifier(Map<String, dynamic>? person) {
    final identifiers = person?['identificador_paciente'] as List?;
    if (identifiers == null || identifiers.isEmpty) return null;
    return identifiers.cast<Map<String, dynamic>>().firstWhere(
      (item) => item['es_principal'] == true,
      orElse: () => identifiers.first as Map<String, dynamic>,
    );
  }

  double? _latestScore(dynamic predictions) {
    if (predictions is! List || predictions.isEmpty) return null;
    final sorted = predictions.cast<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => (b['fecha_prediccion'] as String).compareTo(
          a['fecha_prediccion'] as String,
        ),
      );
    return double.tryParse(sorted.first['score_riesgo'].toString());
  }

  int _ageAt(DateTime birth, DateTime today) {
    final hadBirthday =
        today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    return today.year - birth.year - (hadBirthday ? 0 : 1);
  }

  TipoAtencion _toEncounterType(String value) => switch (value) {
    'urgencias' => TipoAtencion.urgencias,
    'consulta_externa' => TipoAtencion.consultaExterna,
    _ => TipoAtencion.hospitalizacion,
  };
}
