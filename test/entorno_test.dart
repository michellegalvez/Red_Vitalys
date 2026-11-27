import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/config/entorno.dart';

// `flutter run` sin parámetros usa Supabase si existe
// assets/config/env.json; sin ese archivo, los datos simulados (AD-13).

void main() {
  const url = 'https://ejemplo.supabase.co';
  const llave = 'sb_publishable_abc';

  test('lee la URL y la publishable key del archivo', () {
    final config = Entorno.desdeJson(
      '{"SUPABASE_URL": "$url", "SUPABASE_PUBLISHABLE_KEY": "$llave"}',
    );
    expect(config?.url, url);
    expect(config?.publishableKey, llave);
  });

  test('sin valores, con JSON roto o sin https no configura Supabase', () {
    expect(
      Entorno.desdeJson(
        '{"SUPABASE_URL": "", '
        '"SUPABASE_PUBLISHABLE_KEY": ""}',
      ),
      isNull,
    );
    expect(Entorno.desdeJson('no es json'), isNull);
    expect(Entorno.desdeJson('[1, 2]'), isNull);
    expect(
      Entorno.desdeJson(
        '{"SUPABASE_URL": "http://ejemplo.supabase.co", '
        '"SUPABASE_PUBLISHABLE_KEY": "$llave"}',
      ),
      isNull,
    );
  });

  test('nunca acepta la secret key', () {
    expect(
      Entorno.desdeJson(
        '{"SUPABASE_URL": "$url", '
        '"SUPABASE_PUBLISHABLE_KEY": "sb_secret_xyz"}',
      ),
      isNull,
    );
  });

  test('las variables de --dart-define-from-file mandan sobre el archivo', () {
    final config = Entorno.elegir(
      definida: (url: url, publishableKey: llave),
      archivo: (url: 'https://otro.supabase.co', publishableKey: 'otra'),
    );
    expect(config?.url, url);
    expect(
      Entorno.elegir(
        definida: null,
        archivo: (url: url, publishableKey: llave),
      )?.publishableKey,
      llave,
    );
    expect(Entorno.elegir(definida: null, archivo: null), isNull);
  });
}
