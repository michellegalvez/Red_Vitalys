import 'package:flutter/foundation.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// An account as the director sees it (F-24).
typedef Account = ({
  String id,
  String name,
  String email,
  Rol? role,
  List<String> sites,
  bool active,
});

/// How creating an account ended (F-24).
enum SignUpStatus { created, emailTaken, failed }

/// Why the database refused a change to an account (F-24 A5, A6, A7).
enum AccountRefusal { ownAccount, noSites, role }

/// The database refused a change to an account for a rule of F-24.
class AccountRejected implements Exception {
  const AccountRejected(this.refusal);

  final AccountRefusal refusal;
}

/// Creates accounts and lets the director change them (F-24, RF-39, RF-40).
abstract interface class AccountService {
  bool get isRemote;

  Future<SignUpStatus> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<List<Account>> listAccounts();

  Future<void> saveAccount({
    required Account account,
    required Rol role,
    required List<String> sites,
    required bool active,
    required String sessionSite,
  });
}

/// Keeps the accounts while the app is open, for the tests and without
/// Supabase. The simulated sign-in reads them too, so an approved account can
/// enter.
class AccountMemory implements AccountService {
  AccountMemory(DatosSimulados data) {
    for (final user in data.usuarios) {
      _accounts[user.correo] = (
        user: user,
        password: data.contrasenaPrototipo,
        active: true,
      );
    }
  }

  final _accounts = <String, ({Usuario user, String password, bool active})>{};
  var _next = 1;

  @override
  bool get isRemote => false;

  /// The user behind [email] and [password], or `null` if they do not match
  /// or the account is not active.
  Usuario? userFor(String email, String password) {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) return null;
    return account.active ? account.user : null;
  }

  /// Whether [email] belongs to an account, active or not.
  bool knows(String email) => _accounts.containsKey(email.trim().toLowerCase());

  @override
  Future<SignUpStatus> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) return SignUpStatus.emailTaken;
    final words = name.trim().split(RegExp(r'\s+'));
    _accounts[key] = (
      user: Usuario(
        id: 'n${_next++}',
        nombre: name.trim(),
        saludo: words.first,
        iniciales: words.length > 1
            ? '${words.first[0]}${words.last[0]}'.toUpperCase()
            : words.first[0].toUpperCase(),
        correo: key,
        rol: Rol.medico,
        sedesAsignadas: const [],
      ),
      password: password,
      active: true,
    );
    return SignUpStatus.created;
  }

  @override
  Future<List<Account>> listAccounts() async => [
    for (final account in _accounts.values)
      (
        id: account.user.id,
        name: account.user.nombre,
        email: account.user.correo,
        role: account.user.rol,
        sites: account.user.sedesAsignadas,
        active: account.active,
      ),
  ];

  @override
  Future<void> saveAccount({
    required Account account,
    required Rol role,
    required List<String> sites,
    required bool active,
    required String sessionSite,
  }) async {
    final current = _accounts[account.email];
    if (current == null) throw StateError('Unknown account');
    final user = current.user;
    _accounts[account.email] = (
      user: Usuario(
        id: user.id,
        nombre: user.nombre,
        saludo: user.saludo,
        iniciales: user.iniciales,
        correo: user.correo,
        rol: role,
        sedesAsignadas: List.unmodifiable(sites),
      ),
      password: current.password,
      active: active,
    );
  }
}

/// Creates the account in Supabase Auth and saves changes through the
/// `guardar_cuenta` function, which also writes the audit event (F-20).
class AccountSupabase implements AccountService {
  AccountSupabase({required this.client, required this.sitesByName});

  final SupabaseClient client;

  /// App site id by the site name in the database.
  final Map<String, String> sitesByName;

  Map<String, int>? _databaseSites;

  @override
  bool get isRemote => true;

  @override
  Future<SignUpStatus> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'nombre_completo': name.trim()},
      );
      // An email already registered comes back without identities.
      if (response.user?.identities?.isEmpty ?? false) {
        return SignUpStatus.emailTaken;
      }
      // The new account waits for approval: it never stays signed in here.
      if (response.session != null) {
        try {
          await client.auth.signOut();
        } catch (error) {
          debugPrint('Could not close the new account session: $error');
        }
      }
      return SignUpStatus.created;
    } on AuthException catch (error) {
      if (error.code == 'user_already_exists') return SignUpStatus.emailTaken;
      debugPrint('Could not create the account: $error');
      return SignUpStatus.failed;
    } catch (error) {
      debugPrint('Could not create the account: $error');
      return SignUpStatus.failed;
    }
  }

  @override
  Future<List<Account>> listAccounts() async {
    final rows = await client
        .from('usuario')
        .select(
          'id_usuario, nombre_completo, correo, activo, rol(nombre), '
          'usuario_sede(sede(nombre))',
        )
        .order('nombre_completo');
    return [
      for (final row in rows)
        (
          id: row['id_usuario'] as String,
          name: row['nombre_completo'] as String,
          email: row['correo'] as String,
          role: _role((row['rol'] as Map?)?['nombre'] as String?),
          sites: [
            for (final link in (row['usuario_sede'] as List? ?? const []))
              ?sitesByName[((link as Map)['sede'] as Map?)?['nombre']],
          ],
          active: row['activo'] as bool? ?? true,
        ),
    ];
  }

  @override
  Future<void> saveAccount({
    required Account account,
    required Rol role,
    required List<String> sites,
    required bool active,
    required String sessionSite,
  }) async {
    final ids = await _siteIds();
    final names = {for (final e in sitesByName.entries) e.value: e.key};
    int idOf(String site) => ids[names[site]]!;
    try {
      await client.rpc<void>(
        'guardar_cuenta',
        params: {
          'p_id_usuario': account.id,
          'p_rol': role.name,
          'p_sedes': [for (final site in sites) idOf(site)],
          'p_activo': active,
          'p_id_sede_sesion': idOf(sessionSite),
        },
      );
    } on PostgrestException catch (error) {
      final refusal = switch (error.message) {
        'propia' => AccountRefusal.ownAccount,
        'sin_sedes' => AccountRefusal.noSites,
        'rol' => AccountRefusal.role,
        _ => null,
      };
      if (refusal != null) throw AccountRejected(refusal);
      rethrow;
    }
  }

  Future<Map<String, int>> _siteIds() async {
    final known = _databaseSites;
    if (known != null) return known;
    final rows = await client.from('sede').select('id_sede, nombre');
    return _databaseSites = {
      for (final row in rows) row['nombre'] as String: row['id_sede'] as int,
    };
  }

  Rol? _role(String? name) => switch (name) {
    'medico' => Rol.medico,
    'administrativo' => Rol.administrativo,
    'auditor' => Rol.auditor,
    'director' => Rol.director,
    _ => null,
  };
}
