import 'package:flutter/foundation.dart';
import 'package:red_vitalys/formato/formato.dart';
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

  // The names and emails as the database may write them: without accents
  // and in any case.
  late final _sites = {
    for (final e in sitesByName.entries) normalizarTexto(e.key): e.value,
  };
  late final _users = {
    for (final e in usersByEmail.entries) normalizarTexto(e.key): e.value,
  };

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async {
    // Independent queries: they go together, not one after the other.
    final [rows, people] = await Future.wait([_encounters(), _people()]);
    final latest = <int, Map<String, dynamic>>{};
    final lastSite = <int, String>{};
    final doctors = <int, List<String>>{};
    for (final row in rows) {
      final patientId = row['id_paciente'];
      if (patientId is! int) {
        debugPrint('Skipped an encounter without a patient');
        continue;
      }
      final site = (row['sede'] as Map?)?['nombre'] as String?;
      if (site != null) lastSite.putIfAbsent(patientId, () => site);
      final current = latest[patientId];
      final discharged = row['fecha_fin'] != null;
      if (discharged && (current == null || _isBetterDischarge(row, current))) {
        latest[patientId] = row;
      }
      if (row['proposito'] != 'atencion_paciente') continue;
      final doctor = _user((row['usuario'] as Map?)?['correo'] as String?);
      if (doctor == null) continue;
      final list = doctors.putIfAbsent(patientId, () => []);
      if (!list.contains(doctor)) list.add(doctor);
    }

    final peopleById = {
      for (final person in people)
        if (person['id_paciente'] case final int id) id: person,
    };
    for (final id in latest.keys) {
      if (!peopleById.containsKey(id)) {
        debugPrint('Patient $id has encounters but could not be read');
      }
    }
    // The discharged patients first, as the list orders them; without any
    // discharge the patient is still found by the search and can be opened,
    // but never enters the recent-discharge list (F-01, F-02).
    final order = [
      ...latest.keys.where(peopleById.containsKey),
      ...peopleById.keys.where((id) => !latest.containsKey(id)),
    ];
    return [
      for (final id in order)
        ?_safely(
          id,
          () => _toPatient(
            id,
            peopleById[id]!,
            latest[id],
            lastSite[id],
            doctors[id] ?? const [],
            today,
          ),
        ),
    ];
  }

  // Every page: the search covers the whole network (F-01).
  Future<List<Map<String, dynamic>>> _encounters() => _guard.fetchAll(
    () => client
        .from('atencion')
        .select(
          'id_paciente, fecha_inicio, fecha_fin, tipo_atencion, proposito, '
          'sede(nombre), usuario(correo), '
          'prediccion_reingreso(score_riesgo, fecha_prediccion)',
        )
        .order('fecha_fin', ascending: false, nullsFirst: false)
        .order('id_atencion'),
  );

  Future<List<Map<String, dynamic>>> _people() => _guard.fetchAll(
    () => client
        .from('paciente')
        .select(
          'id_paciente, primer_nombre, segundo_nombre, primer_apellido, '
          'segundo_apellido, fecha_nacimiento, sexo, '
          'identificador_paciente(tipo_documento, numero_identificacion, '
          'es_principal)',
        )
        .order('id_paciente'),
  );

  /// A row that cannot be read is skipped and logged instead of leaving the
  /// whole list without anyone.
  PacienteEnSeguimiento? _safely(
    int patientId,
    PacienteEnSeguimiento Function() build,
  ) {
    try {
      return build();
    } on Object catch (error) {
      debugPrint('Skipped patient $patientId, its data is incomplete: $error');
      return null;
    }
  }

  String? _user(String? email) =>
      email == null ? null : _users[normalizarTexto(email)];

  /// The app id of a site, or `''` when the app does not know it: the
  /// patient is still listed and found (F-01).
  String _site(String? name, int patientId) {
    if (name == null) return '';
    final id = _sites[normalizarTexto(name)];
    if (id == null) debugPrint('Patient $patientId is at an unknown site');
    return id ?? '';
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

  PacienteEnSeguimiento _toPatient(
    int patientId,
    Map<String, dynamic> person,
    Map<String, dynamic>? discharge,
    String? lastSiteName,
    List<String> doctors,
    DateTime today,
  ) {
    final identifier = _mainIdentifier(person);
    if (identifier == null) {
      debugPrint('Patient $patientId has no document');
    }
    final number = identifier?['numero_identificacion'] as String? ?? '';
    final common = (
      id: _appId(number, patientId),
      name: _fullName(person),
      age: _ageAt(DateTime.parse(person['fecha_nacimiento'] as String), today),
      sex: person['sexo'] as String,
      type: identifier?['tipo_documento'] as String? ?? '',
    );

    if (discharge == null) {
      return PacienteEnSeguimiento(
        id: common.id,
        nombre: common.name,
        iniciales: _initials(person),
        edad: common.age,
        sexo: common.sex,
        tipoDocumento: common.type,
        numeroDocumento: number,
        sedeAltaId: _site(lastSiteName, patientId),
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: _noDischarge,
        diasEstancia: 0,
        riesgo: 0,
        medicosConAtencion: doctors,
      );
    }
    final end = _day(discharge['fecha_fin'] as String);
    final start = _day(discharge['fecha_inicio'] as String);
    final score = _latestScore(discharge['prediccion_reingreso']);
    return PacienteEnSeguimiento(
      id: common.id,
      nombre: common.name,
      iniciales: _initials(person),
      edad: common.age,
      sexo: common.sex,
      tipoDocumento: common.type,
      numeroDocumento: number,
      sedeAltaId: _site(
        (discharge['sede'] as Map?)?['nombre'] as String?,
        patientId,
      ),
      tipoAtencion: _toEncounterType(discharge['tipo_atencion'] as String?),
      fechaAlta: end,
      diasEstancia: end.difference(start).inDays,
      riesgo: score?.round() ?? 0,
      medicosConAtencion: doctors,
    );
  }

  DateTime _day(String timestamp) {
    final local = DateTime.parse(timestamp).toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _fullName(Map<String, dynamic> person) => [
    person['primer_nombre'],
    person['segundo_nombre'],
    person['primer_apellido'],
    person['segundo_apellido'],
  ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

  /// The first letters of the first name and the first surname; with
  /// neither, the first letter of whatever name there is, or `?`.
  String _initials(Map<String, dynamic> person) {
    String first(Object? text) =>
        text is String && text.trim().isNotEmpty ? text.trim()[0] : '';
    final initials =
        '${first(person['primer_nombre'])}${first(person['primer_apellido'])}';
    if (initials.isNotEmpty) return initials.toUpperCase();
    final name = _fullName(person);
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

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

  Map<String, dynamic>? _mainIdentifier(Map<String, dynamic> person) {
    final identifiers = person['identificador_paciente'] as List?;
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

  TipoAtencion _toEncounterType(String? value) => switch (value) {
    'urgencias' => TipoAtencion.urgencias,
    'consulta_externa' => TipoAtencion.consultaExterna,
    _ => TipoAtencion.hospitalizacion,
  };
}
