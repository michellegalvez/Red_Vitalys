import 'package:flutter/foundation.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:red_vitalys/services/remote_ids.dart';
import 'package:red_vitalys/services/session_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and saves the indicator measurements in Supabase.
class IndicatorSupabase implements IndicatorService {
  IndicatorSupabase({required this.client, required this.sitesByName});

  final SupabaseClient client;

  final Map<String, String> sitesByName;

  late final _guard = SessionGuard.of(client);

  late final _ids = RemoteIds.of(client);

  late final _sites = {
    for (final e in sitesByName.entries) normalizarTexto(e.key): e.value,
  };

  @override
  bool get isRemote => true;

  @override
  Future<List<Medicion>> listMeasurements() async {
    final rows = await _guard.run(
      () => client
          .from('medicion_indicador')
          .select(
            'id_medicion, periodo_inicio, valor, indicador(codigo), '
            'sede(nombre)',
          )
          .order('periodo_inicio')
          .order('id_medicion'),
    );
    return [for (final row in rows) ?_toMeasurement(row)];
  }

  /// A row that cannot be placed is skipped and logged: counting it in the
  /// wrong site would change the network average, and failing would leave
  /// the whole board empty (F-08).
  Medicion? _toMeasurement(Map<String, dynamic> row) {
    try {
      final code = (row['indicador'] as Map?)?['codigo'] as String?;
      final siteName = (row['sede'] as Map?)?['nombre'] as String?;
      final siteId = siteName == null
          ? null
          : _sites[normalizarTexto(siteName)];
      final indicator = IdIndicador.values.where((i) => i.name == code);
      if (indicator.isEmpty || siteId == null) {
        debugPrint(
          'Skipped measurement ${row['id_medicion']}: unknown indicator or site',
        );
        return null;
      }
      return Medicion(
        indicador: indicator.first,
        sedeId: siteId,
        periodo: DateTime.parse(row['periodo_inicio'] as String),
        valor: num.parse(row['valor'].toString()).toDouble(),
      );
    } on Object catch (error) {
      debugPrint('Skipped measurement ${row['id_medicion']}: $error');
      return null;
    }
  }

  @override
  Future<void> addMeasurement(
    Medicion measurement, {
    required String siteName,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No hay sesión de Supabase para guardar la medición');
    }
    final indicatorId = await _ids.indicatorId(measurement.indicador.name);
    final siteId = await _ids.siteId(siteName);
    final start = measurement.periodo;
    final end = DateTime(start.year, start.month + 1, 0);
    try {
      await _guard.run(
        () => client.from('medicion_indicador').insert({
          'id_indicador': indicatorId,
          'id_sede': siteId,
          'periodo_inicio': _date(start),
          'periodo_fin': _date(end),
          'valor': measurement.valor,
          'registrada_por': userId,
        }),
      );
    } on PostgrestException catch (error) {
      if (error.code == '23505') throw const DuplicateMeasurement();
      rethrow;
    }
  }

  String _date(DateTime day) => day.toIso8601String().substring(0, 10);
}
