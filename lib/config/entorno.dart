/// Configuración proporcionada en tiempo de compilación con
/// `--dart-define-from-file=env.json`.
class Entorno {
  const Entorno._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get configurado =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
