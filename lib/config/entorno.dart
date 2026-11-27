import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// La URL y la publishable key de Supabase. La secret key nunca.
typedef ConfigSupabase = ({String url, String publishableKey});

/// Configuración de Supabase (AD-13). Sale, en este orden, de:
///
/// 1. `--dart-define-from-file=env.json` al compilar.
/// 2. `assets/config/env.json`, para que `flutter run` sin parámetros ya use
///    Supabase. El archivo está en `.gitignore`.
///
/// Sin ninguna de las dos, la app usa los datos simulados.
class Entorno {
  const Entorno._();

  /// Ruta del archivo que lee `flutter run` sin parámetros.
  static const String rutaArchivo = 'assets/config/env.json';

  static const String _urlDefinida = String.fromEnvironment('SUPABASE_URL');
  static const String _llaveDefinida = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Lee la configuración: primero la de compilación y si no, el archivo.
  static Future<ConfigSupabase?> cargar() async {
    final definida = _validar(_urlDefinida, _llaveDefinida);
    if (definida != null) return definida;
    try {
      final texto = await rootBundle.loadString(rutaArchivo);
      return elegir(definida: null, archivo: desdeJson(texto));
    } on FlutterError {
      // No hay archivo: la app sigue con los datos simulados.
      return null;
    }
  }

  /// Las variables de compilación mandan sobre el archivo.
  static ConfigSupabase? elegir({
    required ConfigSupabase? definida,
    required ConfigSupabase? archivo,
  }) => definida ?? archivo;

  /// Lee el contenido de `env.json`. Devuelve `null` si no sirve.
  static ConfigSupabase? desdeJson(String texto) {
    final Object? json;
    try {
      json = jsonDecode(texto);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    final url = json['SUPABASE_URL'];
    final llave = json['SUPABASE_PUBLISHABLE_KEY'];
    if (url is! String || llave is! String) return null;
    return _validar(url, llave);
  }

  static ConfigSupabase? _validar(String url, String llave) {
    final limpiaUrl = url.trim();
    final limpiaLlave = llave.trim();
    if (limpiaUrl.isEmpty || limpiaLlave.isEmpty) return null;
    if (!limpiaUrl.startsWith('https://')) return null;
    // La secret key da acceso total a la base: nunca va en la app.
    if (limpiaLlave.startsWith('sb_secret_')) return null;
    return (url: limpiaUrl, publishableKey: limpiaLlave);
  }
}
