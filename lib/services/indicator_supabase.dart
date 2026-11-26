import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and saves the indicator measurements in Supabase.
class IndicatorSupabase implements IndicatorService {
  IndicatorSupabase({required this.client, required this.sitesByName});

  final SupabaseClient client;

  final Map<String, String> sitesByName;

  @override
  bool get isRemote => true;

  @override
  Future<List<Medicion>> listMeasurements() async {
    final rows = await client
        .from('medicion_indicador')
        .select(
          'id_medicion, periodo_inicio, valor, indicador(codigo), '
          'sede(nombre)',
        )
        .order('periodo_inicio')
        .order('id_medicion');
    return [for (final row in rows) ?_toMeasurement(row)];
  }

  Medicion? _toMeasurement(Map<String, dynamic> row) {
    final code = (row['indicador'] as Map?)?['codigo'] as String?;
    final siteId = sitesByName[(row['sede'] as Map?)?['nombre']];
    if (code == null || siteId == null) return null;
    final indicator = IdIndicador.values.where((i) => i.name == code);
    if (indicator.isEmpty) return null;
    return Medicion(
      indicador: indicator.first,
      sedeId: siteId,
      periodo: DateTime.parse(row['periodo_inicio'] as String),
      valor: num.parse(row['valor'].toString()).toDouble(),
    );
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
    final indicator = await client
        .from('indicador')
        .select('id_indicador')
        .eq('codigo', measurement.indicador.name)
        .single();
    final site = await client
        .from('sede')
        .select('id_sede')
        .eq('nombre', siteName)
        .single();
    final start = measurement.periodo;
    final end = DateTime(start.year, start.month + 1, 0);
    try {
      await client.from('medicion_indicador').insert({
        'id_indicador': indicator['id_indicador'],
        'id_sede': site['id_sede'],
        'periodo_inicio': _date(start),
        'periodo_fin': _date(end),
        'valor': measurement.valor,
        'registrada_por': userId,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') throw const DuplicateMeasurement();
      rethrow;
    }
  }

  String _date(DateTime day) => day.toIso8601String().substring(0, 10);
}
