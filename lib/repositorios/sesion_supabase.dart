import 'package:supabase_flutter/supabase_flutter.dart';

/// TEMPORAL (P-01): abre y cierra una sesión en Supabase junto con el inicio
/// de sesión simulado, con el mismo correo y contraseña. La base solo deja
/// escribir y leer la auditoría a quien tiene sesión.
///
/// Se borra cuando el inicio de sesión (F-13) use Supabase Auth de verdad:
/// basta quitar este archivo y las dos llamadas de `AppScreen`.
class SesionSupabase {
  SesionSupabase(this.cliente);

  final SupabaseClient cliente;

  Future<void> iniciar(String correo, String contrasena) async {
    await cliente.auth.signInWithPassword(email: correo, password: contrasena);
  }

  Future<void> cerrar() => cliente.auth.signOut();
}
