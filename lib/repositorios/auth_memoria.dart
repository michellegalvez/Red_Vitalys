import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auth_repositorio.dart';

/// Implementación en memoria del repositorio de autenticación para pruebas
/// y modo local sin conexión (AD-02, AD-03).
class AuthMemoria implements AuthRepositorio {
  AuthMemoria(this.datos);

  final DatosSimulados datos;
  Usuario? _usuarioActual;

  @override
  bool get esRemoto => false;

  @override
  Usuario? get usuarioActual => _usuarioActual;

  @override
  Future<AuthResultado> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final normalizado = correo.trim().toLowerCase();
    final usuario = datos.usuarios.cast<Usuario?>().firstWhere(
      (u) => u?.correo.toLowerCase() == normalizado,
      orElse: () => null,
    );

    if (usuario == null || contrasena != datos.contrasenaPrototipo) {
      return const AuthErrorCredenciales();
    }

    _usuarioActual = usuario;
    final sedes = datos.sedes
        .where((s) => usuario.sedesAsignadas.contains(s.id))
        .toList();
    return AuthExito(usuario: usuario, sedes: sedes);
  }

  @override
  Future<void> cerrarSesion() async {
    _usuarioActual = null;
  }
}
