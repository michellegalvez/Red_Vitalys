import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:red_vitalys/services/auth_supabase.dart';
import 'package:red_vitalys/services/lock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Las dos piezas reales que las pruebas de pantalla reemplazan por dobles: el
// cierre de sesión contra Supabase Auth (F-23 CA-5) y el bloqueo guardado en
// el equipo (F-14).

final _lockedSince = DateTime(2026, 11, 6, 10, 42);

String _jwt() {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(const Duration(hours: 1));
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${part({'sub': 'u1', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.firma';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cerrar sesión con Supabase Auth (F-23 CA-5)', () {
    late bool offline;
    late List<String> calls;
    late List<String?> scopes;
    late SupabaseClient client;

    setUp(() async {
      offline = false;
      calls = [];
      scopes = [];
      final http.Client mock = MockClient((request) async {
        calls.add(request.url.path);
        if (request.url.path.endsWith('/logout')) {
          scopes.add(request.url.queryParameters['scope']);
        }
        if (request.url.path.endsWith('/logout')) {
          if (offline) throw http.ClientException('sin red', request.url);
          return http.Response('', 204, request: request);
        }
        final token = _jwt();
        return http.Response(
          jsonEncode({
            'access_token': token,
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'refresco',
            'user': {
              'id': 'u1',
              'aud': 'authenticated',
              'email': 'camila.martinez@vitalys.co',
              'app_metadata': <String, Object>{},
              'user_metadata': <String, Object>{},
              'created_at': '2026-11-01T00:00:00Z',
            },
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });
      client = SupabaseClient(
        'https://ejemplo.supabase.co',
        'clave-publica',
        httpClient: mock,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      await client.auth.signInWithPassword(
        email: 'camila.martinez@vitalys.co',
        password: 'vitalys2026',
      );
      expect(client.auth.currentSession, isNotNull);
    });

    test(
      'sin red, falla y la sesión sigue entera para seguir usando la app',
      () async {
        final auth = AuthSupabase(
          client: client,
          sitesByName: const {},
          knownUsers: const {},
        );
        offline = true;
        await expectLater(auth.signOut(), throwsA(anything));
        expect(client.auth.currentSession, isNotNull);

        offline = false;
        await auth.signOut();
        expect(client.auth.currentSession, isNull);
        expect(calls.where((p) => p.endsWith('/logout')), isNotEmpty);
        // Solo cierra esta sesión: las de otros equipos con la misma cuenta
        // siguen abiertas.
        expect(scopes, everyElement('local'));
      },
    );
  });

  group('El bloqueo guardado en el equipo (F-14)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('otro arranque de la app lee el mismo bloqueo', () async {
      await LockDevice().write((failures: 5, lockedSince: _lockedSince));
      final read = await LockDevice().read();
      expect(read?.failures, 5);
      expect(read?.lockedSince, _lockedSince);
    });

    test('al terminar el bloqueo no queda nada guardado', () async {
      final store = LockDevice();
      await store.write((failures: 5, lockedSince: _lockedSince));
      await store.write((failures: 0, lockedSince: null));
      expect(await LockDevice().read(), isNull);
    });
  });
}
