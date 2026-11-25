import 'package:red_vitalys/modelos/modelos.dart';

/// How a sign-in attempt ended.
enum SignInStatus { success, wrongCredentials, noSites, networkError }

/// The outcome of a sign-in attempt and, on success, the signed-in user.
class SignInResult {
  const SignInResult(this.status, [this.user]);

  final SignInStatus status;
  final Usuario? user;
}
