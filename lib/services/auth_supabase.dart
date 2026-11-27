import 'package:flutter/foundation.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Signs in with Supabase Auth and reads the role and the sites from the database (AD-04).
class AuthSupabase implements AuthService {
  AuthSupabase({
    required this.client,
    required this.sitesByName,
    required this.knownUsers,
  });

  final SupabaseClient client;

  final Map<String, String> sitesByName;

  final Map<String, Usuario> knownUsers;

  @override
  bool get isRemote => true;

  @override
  Stream<void> get sessionEnded => client.auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.signedOut)
      .map((_) {});

  @override
  Future<SignInResult> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final id = response.user?.id;
      if (id == null) return await _reject(SignInStatus.wrongCredentials);
      return await _loadProfile(id, email.trim());
    } on AuthRetryableFetchException {
      return const SignInResult(SignInStatus.networkError);
    } on AuthException {
      return const SignInResult(SignInStatus.wrongCredentials);
    } on PostgrestException catch (error) {
      debugPrint('Could not load the profile: $error');
      return _reject(SignInStatus.networkError);
    } catch (error) {
      debugPrint('Unexpected sign-in error: $error');
      return _reject(SignInStatus.networkError);
    }
  }

  /// Closes the session on the server first and only then on the device: if
  /// the server cannot be reached the session stays whole, the app keeps
  /// working and the user can try again (F-23 CA-5).
  @override
  Future<void> signOut() async {
    final token = client.auth.currentSession?.accessToken;
    if (token != null) {
      try {
        // Only this session: the same account may be open on other devices.
        await client.auth.admin.signOut(token, scope: SignOutScope.local);
      } on AuthException catch (error) {
        // An expired or unknown token is already signed out on the server.
        const gone = {'401', '403', '404'};
        if (!gone.contains(error.statusCode)) rethrow;
      }
    }
    try {
      await client.auth.signOut();
    } catch (error) {
      // The server session is already closed; the device one is gone too.
      debugPrint('Could not tell the server again about the sign-out: $error');
    }
  }

  @override
  Future<Usuario> reloadProfile(Usuario current) async {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('No Supabase session to read the profile');
    final row = await client
        .from('usuario')
        .select(
          'nombre_completo, correo, activo, rol(nombre), usuario_sede(sede(nombre))',
        )
        .eq('id_usuario', id)
        .single();
    final role = _roleFrom((row['rol'] as Map?)?['nombre'] as String?);
    final sites = [
      for (final link in (row['usuario_sede'] as List? ?? const []))
        ?sitesByName[((link as Map)['sede'] as Map?)?['nombre']],
    ];
    if (row['activo'] == false || role == null || sites.isEmpty) {
      throw StateError('The profile is no longer valid');
    }
    return Usuario(
      id: current.id,
      nombre: row['nombre_completo'] as String,
      saludo: current.saludo,
      iniciales: current.iniciales,
      correo: (row['correo'] as String?) ?? current.correo,
      rol: role,
      sedesAsignadas: sites,
    );
  }

  Future<SignInResult> _loadProfile(String id, String email) async {
    final row = await client
        .from('usuario')
        .select(
          'nombre_completo, correo, activo, rol(nombre), usuario_sede(sede(nombre))',
        )
        .eq('id_usuario', id)
        .maybeSingle();
    if (row == null || row['activo'] == false) {
      return _reject(SignInStatus.wrongCredentials);
    }
    final role = _roleFrom((row['rol'] as Map?)?['nombre'] as String?);
    if (role == null) return _reject(SignInStatus.wrongCredentials);

    final sites = <String>[];
    for (final link in (row['usuario_sede'] as List? ?? const [])) {
      final name = ((link as Map)['sede'] as Map?)?['nombre'] as String?;
      final siteId = sitesByName[name];
      if (siteId != null) sites.add(siteId);
    }
    if (sites.isEmpty) return _reject(SignInStatus.noSites);

    final mail = (row['correo'] as String?) ?? email;
    final name = row['nombre_completo'] as String;
    final known = knownUsers[mail] ?? knownUsers[mail.toLowerCase()];
    return SignInResult(
      SignInStatus.success,
      Usuario(
        id: known?.id ?? id,
        nombre: name,
        saludo: known?.saludo ?? name.split(' ').first,
        iniciales: known?.iniciales ?? _initialsOf(name),
        correo: mail,
        rol: role,
        sedesAsignadas: sites,
      ),
    );
  }

  Future<SignInResult> _reject(SignInStatus status) async {
    try {
      await client.auth.signOut();
    } catch (error) {
      debugPrint('Could not close the Auth session: $error');
    }
    return SignInResult(status);
  }

  Rol? _roleFrom(String? name) => switch (name) {
    'medico' => Rol.medico,
    'administrativo' => Rol.administrativo,
    'auditor' => Rol.auditor,
    _ => null,
  };

  String _initialsOf(String name) {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
