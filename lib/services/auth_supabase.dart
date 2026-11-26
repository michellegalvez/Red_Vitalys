import 'package:flutter/foundation.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<AuthSignInResult> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final id = response.user?.id;
      if (id == null) return await _reject(AuthSignInStatus.wrongCredentials);
      return await _loadProfile(id, email.trim());
    } on AuthRetryableFetchException {
      return const AuthSignInResult(AuthSignInStatus.networkError);
    } on AuthException {
      return const AuthSignInResult(AuthSignInStatus.wrongCredentials);
    } on PostgrestException catch (error) {
      debugPrint('No se pudo cargar el perfil de Supabase: $error');
      return _reject(AuthSignInStatus.networkError);
    } catch (error) {
      debugPrint('Error inesperado al iniciar sesión: $error');
      return _reject(AuthSignInStatus.networkError);
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  Future<AuthSignInResult> _loadProfile(String id, String email) async {
    final row = await client
        .from('usuario')
        .select(
          'nombre_completo, correo, activo, rol(nombre), usuario_sede(sede(nombre))',
        )
        .eq('id_usuario', id)
        .maybeSingle();
    if (row == null || row['activo'] == false) {
      return _reject(AuthSignInStatus.wrongCredentials);
    }

    final role = _roleFrom((row['rol'] as Map?)?['nombre'] as String?);
    if (role == null) return _reject(AuthSignInStatus.wrongCredentials);

    final sites = <String>[];
    for (final link in (row['usuario_sede'] as List? ?? const [])) {
      final name = ((link as Map)['sede'] as Map?)?['nombre'] as String?;
      final siteId = sitesByName[name];
      if (siteId != null) sites.add(siteId);
    }
    if (sites.isEmpty) return _reject(AuthSignInStatus.noSites);

    final mail = (row['correo'] as String?) ?? email;
    final name = row['nombre_completo'] as String;
    final known = knownUsers[mail] ?? knownUsers[mail.toLowerCase()];
    return AuthSignInResult(
      AuthSignInStatus.success,
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

  Future<AuthSignInResult> _reject(AuthSignInStatus status) async {
    try {
      await client.auth.signOut();
    } catch (error) {
      debugPrint('No se pudo cerrar la sesión de Auth: $error');
    }
    return AuthSignInResult(status);
  }

  Rol? _roleFrom(String? name) => switch (name) {
    'medico' => Rol.medico,
    'administrativo' => Rol.administrativo,
    'auditor' => Rol.auditor,
    _ => null,
  };

  String _initialsOf(String name) {
    final words = name.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
