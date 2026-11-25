import 'package:red_vitalys/models/sign_in_result.dart';

/// Signs users in and out against the data source (AD-02, AD-04).
abstract interface class AuthService {
  bool get isRemote;

  Future<SignInResult> signIn(String email, String password);

  Future<void> signOut();
}
