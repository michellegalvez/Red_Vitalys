import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/services/remote_ids.dart';
import 'package:red_vitalys/services/session_guard.dart';
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

  late final _guard = SessionGuard.of(client);

  late final _ids = RemoteIds.of(client);

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async {
    final rows = await _guard.run(
      () => client
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
          .order('fecha_fin', ascending: false, nullsFirst: false),
    );

    final people = await _guard.run(
      () => client
          .from('paciente')
          .select(
            'id_paciente, primer_nombre, segundo_nombre, primer_apellido, '
            'segundo_apellido, fecha_nacimiento, sexo, '
            'identificador_paciente(tipo_documento, numero_identificacion, '
            'es_principal)',
          ),
    );

    final latest = <int, Map<String, dynamic>>{};
    final lastSite = <int, String>{};
    final doctors = <int, List<String>>{};
    for (final row in rows) {
      final patientId = row['id_paciente'] as int;
      final site = (row['sede'] as Map?)?['nombre'] as String?;
      if (site != null) lastSite.putIfAbsent(patientId, () => site);
      final current = latest[patientId];
      final discharged = row['fecha_fin'] != null;
      if (discharged && (current == null || _isBetterDischarge(row, current))) {
        latest[patientId] = row;
      }
      if (row['proposito'] != 'atencion_paciente') continue;
      final doctor = usersByEmail[(row['usuario'] as Map?)?['correo']];
      if (doctor == null) continue;
      final list = doctors.putIfAbsent(patientId, () => []);
      if (!list.contains(doctor)) list.add(doctor);
    }

    return [
      for (final entry in latest.entries)
        ?_toPatient(entry.key, entry.value, doctors[entry.key] ?? [], today),
      // Without any discharge the patient is still found by the search and can
      // be opened, but never enters the recent-discharge list (F-01, F-02).
      for (final person in people)
        if (!latest.containsKey(person['id_paciente']))
          ?_withoutDischarge(
            person,
            lastSite[person['id_paciente']],
            doctors[person['id_paciente']] ?? [],
            today,
          ),
    ];
  }

  /// The app id of a patient. Its database id is kept so opening it does not
  /// have to look it up again.
  String _appId(String number, int patientId) {
    final appId = patientIdsByDocument[number] ?? 'db$patientId';
    _ids.rememberPatient(appId, patientId);
    return appId;
  }

  /// A date far enough back that it never counts as a recent discharge.
  static final _noDischarge = DateTime(1900);

  PacienteEnSeguimiento? _withoutDischarge(
    Map<String, dynamic> person,
    String? siteName,
    List<String> doctors,
    DateTime today,
  ) {
    final identifier = _mainIdentifier(person);
    if (identifier == null) return null;
    final number = identifier['numero_identificacion'] as String;
    final patientId = person['id_paciente'] as int;
    return PacienteEnSeguimiento(
      id: _appId(number, patientId),
      nombre: _fullName(person),
      iniciales: _initials(person),
      edad: _ageAt(DateTime.parse(person['fecha_nacimiento'] as String), today),
      sexo: person['sexo'] as String,
      tipoDocumento: identifier['tipo_documento'] as String,
      numeroDocumento: number,
      sedeAltaId: sitesByName[siteName] ?? '',
      tipoAtencion: TipoAtencion.hospitalizacion,
      fechaAlta: _noDischarge,
      diasEstancia: 0,
      riesgo: 0,
      medicosConAtencion: doctors,
    );
  }

  String _fullName(Map<String, dynamic> person) => [
    person['primer_nombre'],
    person['segundo_nombre'],
    person['primer_apellido'],
    person['segundo_apellido'],
  ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

  String _initials(Map<String, dynamic> person) =>
      '${(person['primer_nombre'] as String)[0]}'
              '${(person['primer_apellido'] as String)[0]}'
          .toUpperCase();

  bool _isBetterDischarge(
    Map<String, dynamic> candidate,
    Map<String, dynamic> current,
  ) {
    final candidateDate = _predictionDate(candidate);
    final currentDate = _predictionDate(current);
    if (candidateDate == null) return false;
    if (currentDate == null) return true;
    return candidateDate.compareTo(currentDate) > 0;
  }

  String? _predictionDate(Map<String, dynamic> row) {
    final predictions = row['prediccion_reingreso'];
    if (predictions is! List || predictions.isEmpty) return null;
    return [
      for (final p in predictions.cast<Map<String, dynamic>>())
        p['fecha_prediccion'] as String,
    ].reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
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

    final dischargeUtc = DateTime.parse(row['fecha_fin'] as String);
    final startUtc = DateTime.parse(row['fecha_inicio'] as String);
    final discharge = dischargeUtc.toLocal();
    final start = startUtc.toLocal();
    final number = identifier['numero_identificacion'] as String;

    return PacienteEnSeguimiento(
      id: _appId(number, patientId),
      nombre: _fullName(person),
      iniciales: _initials(person),
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
      riesgo: score?.round() ?? 0,
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
