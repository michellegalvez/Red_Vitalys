import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Un servidor de Supabase de mentira para probar los servicios reales: Auth
// responde el inicio, la renovación y el cierre de la sesión, y el resto de
// los pedidos los contesta [responder].

/// Una respuesta JSON como las de PostgREST.
http.Response respuestaJson(
  Object? cuerpo,
  http.Request pedido, {
  int estado = 200,
}) => http.Response(
  jsonEncode(cuerpo),
  estado,
  request: pedido,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// La respuesta de PostgREST cuando el token venció.
http.Response tokenVencido(http.Request pedido) => respuestaJson(
  {'code': 'PGRST303', 'message': 'JWT expired', 'details': null},
  pedido,
  estado: 401,
);

String _jwt() {
  String parte(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(const Duration(hours: 1));
  return '${parte({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${parte({'sub': 'u1', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.firma';
}

/// El servidor falso y el cliente que le habla.
class ServidorFalso {
  ServidorFalso(this.responder);

  /// Contesta los pedidos que no son de Auth.
  Future<http.Response> Function(http.Request pedido) responder;

  /// Si la renovación del token falla (la sesión ya no sirve).
  var renovacionFalla = false;
  var renovaciones = 0;
  var cierres = 0;

  /// Los pedidos que no son de Auth, en orden.
  final pedidos = <http.Request>[];

  late final SupabaseClient cliente = SupabaseClient(
    'https://ejemplo.supabase.co',
    'clave-publica',
    httpClient: MockClient(_atender),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  Future<ServidorFalso> conSesion() async {
    await cliente.auth.signInWithPassword(
      email: 'camila.martinez@vitalys.co',
      password: 'vitalys2026',
    );
    return this;
  }

  Future<http.Response> _atender(http.Request pedido) async {
    final ruta = pedido.url.path;
    if (ruta.endsWith('/auth/v1/logout')) {
      cierres++;
      return http.Response('', 204, request: pedido);
    }
    if (ruta.endsWith('/auth/v1/token')) {
      final renovar =
          pedido.url.queryParameters['grant_type'] == 'refresh_token';
      if (renovar) {
        renovaciones++;
        if (renovacionFalla) {
          return respuestaJson(
            {'error': 'invalid_grant', 'error_description': 'Invalid token'},
            pedido,
            estado: 400,
          );
        }
      }
      return respuestaJson(_sesion(), pedido);
    }
    pedidos.add(pedido);
    return responder(pedido);
  }

  Map<String, Object> _sesion() => {
    'access_token': _jwt(),
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
  };
}
