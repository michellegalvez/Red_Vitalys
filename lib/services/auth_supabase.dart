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
    } on PostgrestException {
      return _reject(SignInStatus.networkError);
    } catch (_) {
      return const SignInResult(SignInStatus.networkError);
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();

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
    final known = knownUsers[mail];
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
    await client.auth.signOut().catchError(
      (Object error) => debugPrint('Could not close the Auth session: $error'),
    );
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
