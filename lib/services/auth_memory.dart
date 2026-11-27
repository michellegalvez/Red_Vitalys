import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/account_service.dart';
import 'package:red_vitalys/services/auth_service.dart';

/// Signs in against the simulated users, for the tests and for running without Supabase.
class AuthMemory implements AuthService {
  AuthMemory(this._data, {this.accounts});

  final DatosSimulados _data;

  /// The accounts the director manages, so a new or changed one can enter
  /// (F-24).
  final AccountMemory? accounts;

  @override
  bool get isRemote => false;

  @override
  Stream<void> get sessionEnded => const Stream.empty();

  @override
  Future<SignInResult> signIn(String email, String password) async {
    final accounts = this.accounts;
    if (accounts != null) {
      final user = accounts.userFor(email, password);
      if (user == null) {
        return const SignInResult(SignInStatus.wrongCredentials);
      }
      if (user.sedesAsignadas.isEmpty) {
        return const SignInResult(SignInStatus.noSites);
      }
      return SignInResult(SignInStatus.success, user);
    }
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

  @override
  Future<Usuario> reloadProfile(Usuario current) async => current;
}
