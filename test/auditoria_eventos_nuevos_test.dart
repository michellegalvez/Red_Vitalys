import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// La auditoría de la demo sigue funcionando aunque la base tenga eventos que
// crea una versión más nueva de la app (F-21, F-24).

Map<String, Object?> _row(int id, String resource) => {
  'id_evento': id,
  'fecha_hora_evento': '2026-11-27T15:00:00Z',
  'accion': 'registrar',
  'tipo_recurso': resource,
  'resultado': 'permitido',
  'proposito_uso': null,
  'correo_intento': null,
  'ip': null,
  'id_paciente': null,
  'usuario': {'correo': 'direccion@vitalys.co'},
  'sede': {'nombre': 'Clínica Vitalys Cali Norte'},
};

void main() {
  test('lee los cambios de una cuenta y salta lo que no conoce', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode([
          _row(3, 'usuario'),
          _row(2, 'algo_que_aun_no_existe'),
          _row(1, 'medicion_indicador'),
        ]),
        200,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    final audit = AuditoriaSupabase(
      cliente: SupabaseClient(
        'https://ejemplo.supabase.co',
        'clave-publica',
        httpClient: client,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
      sedesPorNombre: const {'Clínica Vitalys Cali Norte': 's1'},
      usuariosPorCorreo: const {},
      pacientesPorDocumento: const {},
    );

    final events = await audit.listar();

    expect(events.map((e) => e.id), ['e3', 'e1']);
    expect(events.first.recurso, RecursoAuditoria.usuario);
    expect(events.first.recurso.nombre, 'Usuario');
  });
}
