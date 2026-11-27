import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/services/history_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _row(
  int id,
  String start, {
  String? end,
  String? destination,
}) => {
  'id_atencion': id,
  'tipo_atencion': 'urgencias',
  'fecha_inicio': start,
  'fecha_fin': end,
  'destino_alta': destination,
  'sede': {'nombre_corto': 'Cali Norte'},
  'usuario': {'nombre_completo': 'Dra. Camila Martínez'},
  'prediccion_reingreso': <Object>[],
};

/// Answers like the database: without an `order`, the rows come as inserted.
HistorySupabase _serviceAnswering(List<Map<String, Object?>> rows) {
  final client = MockClient((request) async {
    final Object body;
    if (request.url.path.endsWith('/identificador_paciente')) {
      body = {'id_paciente': 7};
    } else if (request.url.path.endsWith('/paciente')) {
      body = {
        'fecha_nacimiento': '1948-06-02',
        'direccion': null,
        'telefono': null,
        'identificador_paciente': <Object>[],
      };
    } else if (request.url.queryParameters['order'] ==
        'id_atencion.desc.'
            'nullslast') {
      body = [...rows]
        ..sort(
          (a, b) =>
              (b['id_atencion'] as int).compareTo(a['id_atencion'] as int),
        );
    } else {
      body = rows;
    }
    return http.Response(
      jsonEncode(body),
      200,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  return HistorySupabase(
    SupabaseClient(
      'https://ejemplo.supabase.co',
      'clave-publica',
      httpClient: client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
  );
}

void main() {
  test('F-04 CA-2: con la misma fecha, la atención registrada después va '
      'primero', () async {
    final data = DatosSimulados.porDefecto;
    final patient = data.pacientes.first;
    final service = _serviceAnswering([
      _row(40, '2026-11-01T15:00:00Z'),
      _row(41, '2026-11-06T15:00:00Z'),
      _row(42, '2026-11-06T15:00:00Z'),
    ]);
    final history = await service.historyOf(
      patient,
      siteName: data.sede(patient.sedeAltaId).nombre,
      today: data.hoy,
    );
    expect(history.encounters.map((e) => e.id), ['enc-42', 'enc-41', 'enc-40']);
  });

  test('F-04: una atención en curso muestra el destino Sin definir y una '
      'con alta muestra el suyo', () async {
    final data = DatosSimulados.porDefecto;
    final patient = data.pacientes.first;
    final service = _serviceAnswering([
      _row(
        41,
        '2026-11-01T15:00:00Z',
        end: '2026-11-03T15:00:00Z',
        destination: 'Domicilio',
      ),
      _row(42, '2026-11-06T15:00:00Z'),
    ]);
    final history = await service.historyOf(
      patient,
      siteName: data.sede(patient.sedeAltaId).nombre,
      today: data.hoy,
    );
    expect(
      {for (final e in history.encounters) e.id: e.dischargeDestination},
      {'enc-42': 'Sin definir', 'enc-41': 'Domicilio'},
    );
  });
}
