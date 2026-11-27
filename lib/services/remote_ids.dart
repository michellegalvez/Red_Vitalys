import 'package:flutter/foundation.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/session_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns the app's patients, sites and indicators into database ids. Each id
/// is asked once and kept until the session changes (AD-02).
class RemoteIds {
  RemoteIds._(this.client) : _guard = SessionGuard.of(client);

  /// The ids of [client]: one per client, shared by all its services.
  factory RemoteIds.of(SupabaseClient client) =>
      _all[client] ??= RemoteIds._(client);

  static final _all = Expando<RemoteIds>();

  final SupabaseClient client;
  final SessionGuard _guard;

  int? _generation;
  Map<String, int>? _sites;
  Map<String, int>? _indicators;
  final _patients = <String, int>{};

  /// Forgets everything when the session changed since the last use.
  int _sync() {
    final generation = _guard.generation;
    if (generation != _generation) {
      _generation = generation;
      _sites = null;
      _indicators = null;
      _patients.clear();
    }
    return generation;
  }

  /// Keeps the database id of the patient the app calls [appId], learned
  /// when the patients were loaded.
  void rememberPatient(String appId, int dbId) {
    _sync();
    _patients[appId] = dbId;
  }

  /// The `id_paciente` of [patient]. Throws a [StateError] if the database
  /// has none or more than one with that main document.
  Future<int> patientId(PacienteEnSeguimiento patient) async {
    final id = await findPatient(
      patient.id,
      documentType: patient.tipoDocumento,
      documentNumber: patient.numeroDocumento,
    );
    if (id == null) {
      throw StateError('No se encontró un único paciente con ese documento');
    }
    return id;
  }

  /// The `id_paciente` of the patient the app calls [appId], or `null` if it
  /// cannot be told for sure. Without [documentType] the number must match a
  /// single main document.
  Future<int?> findPatient(
    String appId, {
    String? documentType,
    String? documentNumber,
  }) async {
    if (appId.startsWith('db')) return int.tryParse(appId.substring(2));
    final generation = _sync();
    final known = _patients[appId];
    if (known != null) return known;
    if (documentNumber == null || documentNumber.isEmpty) return null;
    final rows = await _guard.run(() {
      var query = client
          .from('identificador_paciente')
          .select('id_paciente')
          .eq('numero_identificacion', documentNumber)
          .eq('es_principal', true);
      if (documentType != null) {
        query = query.eq('tipo_documento', documentType);
      }
      return query.limit(2);
    });
    final ids = {for (final row in rows) row['id_paciente'] as int};
    if (ids.length != 1) {
      debugPrint(
        ids.isEmpty
            ? 'No patient has that main document'
            : 'More than one patient has that main document',
      );
      return null;
    }
    if (_sync() == generation) _patients[appId] = ids.single;
    return ids.single;
  }

  /// The `id_sede` of the site called [name], ignoring accents and case.
  Future<int> siteId(String name) async {
    final key = normalizarTexto(name);
    var id = (await siteIds())[key];
    if (id == null) {
      // The site may be new since the list was read.
      _sites = null;
      id = (await siteIds())[key];
    }
    if (id == null) throw StateError('No hay una sede llamada "$name"');
    return id;
  }

  /// Every `id_sede` by its normalized name. An empty answer is not kept.
  Future<Map<String, int>> siteIds() async {
    final generation = _sync();
    final known = _sites;
    if (known != null) return known;
    final rows = await _guard.run(
      () => client.from('sede').select('id_sede, nombre'),
    );
    final ids = {
      for (final row in rows)
        normalizarTexto(row['nombre'] as String): row['id_sede'] as int,
    };
    if (ids.isNotEmpty && _sync() == generation) _sites = ids;
    return ids;
  }

  /// The `id_indicador` of the indicator with [code].
  Future<int> indicatorId(String code) async {
    final generation = _sync();
    var ids = _indicators;
    if (ids == null) {
      final rows = await _guard.run(
        () => client.from('indicador').select('id_indicador, codigo'),
      );
      ids = {
        for (final row in rows)
          row['codigo'] as String: row['id_indicador'] as int,
      };
      if (ids.isNotEmpty && _sync() == generation) _indicators = ids;
    }
    final id = ids[code];
    if (id == null) throw StateError('No hay un indicador con el código $code');
    return id;
  }
}
