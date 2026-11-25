import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/services/auth_service.dart';

/// Signs in against the simulated users, for the tests and for running without Supabase.
class AuthMemory implements AuthService {
  AuthMemory(this._data);

  final DatosSimulados _data;

  @override
  bool get isRemote => false;

  @override
  Future<SignInResult> signIn(String email, String password) async {
    final user = _data.usuarioPorCorreo(email.trim());
    if (user == null || password != _data.contrasenaPrototipo) {
      return const SignInResult(SignInStatus.wrongCredentials);
    }
    if (user.sedesAsignadas.isEmpty) {
      return const SignInResult(SignInStatus.noSites);
    }
    return SignInResult(SignInStatus.success, user);
  }

  @override
  Future<void> signOut() async {}
}
