import 'package:red_vitalys/modelos/modelos.dart';

/// Resultado de una operación de autenticación con credenciales.
sealed class AuthResultado {
  const AuthResultado();
}

class AuthExito extends AuthResultado {
  const AuthExito({required this.usuario, required this.sedes});
  final Usuario usuario;
  final List<Sede> sedes;
}

class AuthErrorCredenciales extends AuthResultado {
  const AuthErrorCredenciales([this.mensaje]);
  final String? mensaje;
}

class AuthErrorRed extends AuthResultado {
  const AuthErrorRed([this.mensaje]);
  final String? mensaje;
}

class AuthErrorDesconocido extends AuthResultado {
  const AuthErrorDesconocido([this.mensaje]);
  final String? mensaje;
}

/// Contrato del repositorio de autenticación (AD-02, AD-03, AD-04).
abstract interface class AuthRepositorio {
  /// `true` si la autenticación se realiza contra Supabase Auth.
  bool get esRemoto;

  /// Inicia sesión con correo y contraseña.
  Future<AuthResultado> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  /// Cierra la sesión activa.
  Future<void> cerrarSesion();

  /// Usuario autenticado actualmente en la sesión, si existe.
  Usuario? get usuarioActual;
}
