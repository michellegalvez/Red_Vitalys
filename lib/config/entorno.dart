/// Configuración que llega al compilar con `--dart-define-from-file=env.json`
/// (AD-13). Solo van la URL y la publishable key; la secret key nunca.
class Entorno {
  const Entorno._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Verdadero solo si las dos variables tienen valor.
  static bool get configurado =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
