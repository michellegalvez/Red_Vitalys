import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/services/audit_event_not_saved.dart';
import 'package:red_vitalys/services/history_supabase.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:red_vitalys/services/indicator_supabase.dart';
import 'package:red_vitalys/services/remote_ids.dart';

import 'supabase_ayudas.dart';

// Con Supabase, la atención y la medición se guardan con su evento en una
// sola operación de la base: sin evento no se guardan (F-04 paso 4, F-12,
// F-20) y si el dato falla no queda un evento huérfano.

final _datos = DatosSimulados.porDefecto;
final _cali = _datos.sede('s1').nombre;

final NuevaAtencion _atencion = (
  sedeId: 's1',
  tipo: EncounterType.urgencias,
  inicio: DateTime(2026, 11, 5),
  alta: DateTime(2026, 11, 6),
  destino: 'Domicilio',
);

final _medicion = Medicion(
  indicador: IdIndicador.espera,
  sedeId: 's1',
  periodo: DateTime(2026, 10),
  valor: 31.5,
);

http.Response _error(http.Request pedido, String codigo, int estado) =>
    respuestaJson(
      {'code': codigo, 'message': 'falló', 'details': null},
      pedido,
      estado: estado,
    );

/// Contesta las sedes y los indicadores; la función RPC la contesta [rpc].
Future<ServidorFalso> _servidor(
  http.Response Function(http.Request pedido) rpc,
) async {
  final servidor = await ServidorFalso((pedido) async {
    final ruta = pedido.url.path;
    if (ruta.endsWith('/sede')) {
      return respuestaJson([
        {'id_sede': 3, 'nombre': _cali},
        {'id_sede': 4, 'nombre': _datos.sede('s2').nombre},
      ], pedido);
    }
    if (ruta.endsWith('/indicador')) {
      return respuestaJson([
        {'id_indicador': 2, 'codigo': 'espera'},
      ], pedido);
    }
    return rpc(pedido);
  }).conSesion();
  RemoteIds.of(servidor.cliente).rememberPatient(_datos.pacientes.first.id, 7);
  return servidor;
}

Future<String?> _registrar(ServidorFalso servidor) =>
    HistorySupabase(servidor.cliente).addEncounter(
      _datos.pacientes.first,
      _atencion,
      siteName: _cali,
      purpose: Proposito.atencionPaciente,
      sessionSiteName: _datos.sede('s2').nombre,
    );

Future<void> _medir(ServidorFalso servidor) => IndicatorSupabase(
  client: servidor.cliente,
  sitesByName: {for (final s in _datos.sedes) s.nombre: s.id},
).addMeasurement(_medicion, siteName: _cali, sessionSiteName: _cali);

Iterable<String> _rutas(ServidorFalso s) => s.pedidos.map((p) => p.url.path);

void main() {
  test('la atención y su evento van en una sola llamada con la sede de la '
      'sesión', () async {
    final servidor = await _servidor((pedido) => respuestaJson(51, pedido));

    final id = await _registrar(servidor);

    expect(id, 'enc-51');
    final llamada = servidor.pedidos.last;
    expect(llamada.url.path, endsWith('/rpc/registrar_atencion'));
    final params = jsonDecode(llamada.body) as Map<String, dynamic>;
    expect(params['p_id_paciente'], 7);
    expect(params['p_id_sede'], 3);
    expect(params['p_id_sede_sesion'], 4);
    expect(params['p_proposito'], 'atencion_paciente');
    expect(params['p_tipo_atencion'], 'urgencias');
    expect(_rutas(servidor), isNot(contains(endsWith('/evento_auditoria'))));
    expect(_rutas(servidor), isNot(contains(endsWith('/atencion'))));
  });

  test(
    'si la base no crea el evento, avisa que la acción no se hizo',
    () async {
      final servidor = await _servidor((p) => _error(p, 'RVE01', 400));

      await expectLater(
        _registrar(servidor),
        throwsA(isA<AuditEventNotSaved>()),
      );
    },
  );

  test('si falla el guardado, el error es el de guardar', () async {
    final servidor = await _servidor((p) => _error(p, '23514', 400));

    await expectLater(
      _registrar(servidor),
      throwsA(isNot(isA<AuditEventNotSaved>())),
    );
  });

  test('la medición y su evento van en una sola llamada', () async {
    final servidor = await _servidor((pedido) => respuestaJson(9, pedido));

    await _medir(servidor);

    final llamada = servidor.pedidos.last;
    expect(llamada.url.path, endsWith('/rpc/registrar_medicion'));
    final params = jsonDecode(llamada.body) as Map<String, dynamic>;
    expect(params['p_id_indicador'], 2);
    expect(params['p_id_sede'], 3);
    expect(params['p_id_sede_sesion'], 3);
    expect(params['p_periodo_inicio'], '2026-10-01');
    expect(params['p_valor'], 31.5);
    expect(_rutas(servidor), isNot(contains(endsWith('/medicion_indicador'))));
  });

  test('la medición repetida y la que no deja evento se reconocen', () async {
    final repetida = await _servidor((p) => _error(p, '23505', 409));
    await expectLater(_medir(repetida), throwsA(isA<DuplicateMeasurement>()));

    final sinEvento = await _servidor((p) => _error(p, 'RVE01', 400));
    await expectLater(_medir(sinEvento), throwsA(isA<AuditEventNotSaved>()));
  });
}
