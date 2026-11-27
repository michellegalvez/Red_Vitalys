import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/modelos/modelos.dart';

/// Signs users in and out against the data source (AD-02, AD-04).
abstract interface class AuthService {
  bool get isRemote;

  /// Fires when the session ends outside the app: it expired or was closed
  /// from the server, so the data can no longer be read with it.
  Stream<void> get sessionEnded;

  Future<SignInResult> signIn(String email, String password);

  Future<void> signOut();

  /// Reads the signed-in user's profile again, for the profile screen (F-22).
  Future<Usuario> reloadProfile(Usuario current);
}
