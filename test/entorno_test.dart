import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/config/entorno.dart';

void main() {
  test('sin --dart-define el entorno no está configurado', () {
    expect(Entorno.supabaseUrl, isEmpty);
    expect(Entorno.supabasePublishableKey, isEmpty);
    expect(Entorno.configurado, isFalse);
  });
}
