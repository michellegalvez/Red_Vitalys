import 'package:red_vitalys/modelos/modelos.dart';

enum AuthSignInStatus { success, wrongCredentials, noSites, networkError }

class AuthSignInResult {
  const AuthSignInResult(this.status, [this.user]);

  final AuthSignInStatus status;
  final Usuario? user;
}

abstract interface class AuthService {
  bool get isRemote;

  Future<AuthSignInResult> signIn(String email, String password);

  Future<void> signOut();
}
