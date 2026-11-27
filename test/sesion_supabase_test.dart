import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_supabase.dart';
import 'package:red_vitalys/services/auth_supabase.dart';
import 'package:red_vitalys/services/indicator_supabase.dart';
import 'package:red_vitalys/services/session_guard.dart';

import 'supabase_ayudas.dart';

// Con Supabase, una sesión vencida o ausente no deja listas vacías: se
// renueva una vez y, si no se puede, la app vuelve al acceso con el aviso de
// sesión terminada (F-15, F-23).

IndicatorSupabase _indicadores(ServidorFalso servidor) =>
    IndicatorSupabase(client: servidor.cliente, sitesByName: const {});

AuthSupabase _auth(ServidorFalso servidor) => AuthSupabase(
  client: servidor.cliente,
  sitesByName: const {},
  knownUsers: const {},
);

void main() {
  test('con el token vencido renueva la sesión una vez y repite la '
      'consulta', () async {
    var intentos = 0;
    final servidor = await ServidorFalso((pedido) async {
      intentos++;
      return intentos == 1 ? tokenVencido(pedido) : respuestaJson([], pedido);
    }).conSesion();

    final mediciones = await _indicadores(servidor).listMeasurements();

    expect(mediciones, isEmpty);
    expect(servidor.renovaciones, 1);
    expect(intentos, 2);
    expect(servidor.cliente.auth.currentSession, isNotNull);
  });

  test('si la sesión no se puede renovar, termina por sessionEnded en vez de '
      'mostrar la lista vacía', () async {
    final servidor = await ServidorFalso((pedido) async => tokenVencido(pedido))
        .conSesion();
    servidor.renovacionFalla = true;
    final terminada = _auth(servidor).sessionEnded.first;

    await expectLater(
      _indicadores(servidor).listMeasurements(),
      throwsA(isA<SessionExpired>()),
    );

    await terminada.timeout(const Duration(seconds: 1));
    expect(servidor.cliente.auth.currentSession, isNull);
  });

  test('sin sesión no consulta como anónimo: termina la sesión', () async {
    final servidor = ServidorFalso((pedido) async => respuestaJson([], pedido));
    final terminada = _auth(servidor).sessionEnded.first;

    await expectLater(
      _indicadores(servidor).listMeasurements(),
      throwsA(isA<SessionExpired>()),
    );

    await terminada.timeout(const Duration(seconds: 1));
    expect(servidor.pedidos, isEmpty);
  });

  test('un error que no es de la sesión llega igual, sin renovar', () async {
    final servidor = await ServidorFalso(
      (pedido) async => respuestaJson(
        {'code': '42P01', 'message': 'relation does not exist'},
        pedido,
        estado: 404,
      ),
    ).conSesion();

    await expectLater(
      _indicadores(servidor).listMeasurements(),
      throwsA(isNot(isA<SessionExpired>())),
    );
    expect(servidor.renovaciones, 0);
    expect(servidor.cliente.auth.currentSession, isNotNull);
  });

  test('el inicio de sesión fallido se registra aunque no haya sesión '
      '(F-20 A4)', () async {
    final servidor = ServidorFalso(
      (pedido) async => respuestaJson(null, pedido, estado: 201),
    );
    final auditoria = AuditoriaSupabase(
      cliente: servidor.cliente,
      sedesPorNombre: const {},
      usuariosPorCorreo: const {},
      pacientesPorDocumento: const {},
    );

    await auditoria.agregar(
      EventoAuditoria(
        id: 'e1',
        fechaHora: DateTime(2026, 11, 6, 10, 42),
        accion: AccionAuditoria.ingresar,
        recurso: RecursoAuditoria.sesion,
        resultado: ResultadoAuditoria.denegado,
        correoIntento: 'nadie@vitalys.co',
      ),
    );

    expect(servidor.pedidos.single.url.path, endsWith('/evento_auditoria'));
  });

  test('una consulta que no responde falla al vencer el tiempo y muestra su '
      'error en vez de quedarse cargando', () async {
    final servidor = await ServidorFalso((pedido) => Completer<Never>().future)
        .conSesion();
    SessionGuard.of(servidor.cliente).timeout = const Duration(
      milliseconds: 50,
    );

    await expectLater(
      _indicadores(servidor).listMeasurements(),
      throwsA(isA<TimeoutException>()),
    );
    expect(servidor.cliente.auth.currentSession, isNotNull);
  });
}
