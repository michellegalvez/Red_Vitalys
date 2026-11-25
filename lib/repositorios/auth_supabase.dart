import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auth_repositorio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación con Supabase Auth y PostgREST (AD-02, AD-04).
///
/// La autenticación se verifica con `signInWithPassword`, y el rol y las sedes
/// asignadas se obtienen de las tablas `usuario`, `rol` y `usuario_sede`.
class AuthSupabase implements AuthRepositorio {
  AuthSupabase({required this.cliente, required this.datos});

  final SupabaseClient cliente;
  final DatosSimulados datos;

  Usuario? _usuarioActual;

  @override
  bool get esRemoto => true;

  @override
  Usuario? get usuarioActual => _usuarioActual;

  @override
  Future<AuthResultado> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final correoLimpio = correo.trim().toLowerCase();
    try {
      final respuesta = await cliente.auth.signInWithPassword(
        email: correoLimpio,
        password: contrasena,
      );

      final user = respuesta.user;
      if (user == null) {
        return const AuthErrorCredenciales();
      }

      // Consultar el registro relacional en public.usuario y su rol
      final usuarioMap = await cliente
          .from('usuario')
          .select(
            'id_usuario, nombre_completo, correo, activo, rol:id_rol(nombre)',
          )
          .eq('id_usuario', user.id)
          .maybeSingle();

      if (usuarioMap == null) {
        // En caso de que no exista fila en public.usuario
        await cliente.auth.signOut();
        return const AuthErrorCredenciales();
      }

      final activo = usuarioMap['activo'] as bool? ?? true;
      if (!activo) {
        await cliente.auth.signOut();
        return const AuthErrorCredenciales();
      }

      final nombreCompleto =
          usuarioMap['nombre_completo'] as String? ?? 'Usuario';
      final rolData = usuarioMap['rol'] as Map<String, dynamic>?;
      final rolNombre = rolData?['nombre'] as String? ?? 'medico';
      final rol = switch (rolNombre) {
        'administrativo' => Rol.administrativo,
        'auditor' => Rol.auditor,
        _ => Rol.medico,
      };

      // Consultar sedes asignadas en usuario_sede
      final sedesRows = await cliente
          .from('usuario_sede')
          .select('sede:id_sede(id_sede, nombre, nombre_corto, tipo_sede)')
          .eq('id_usuario', user.id);

      final sedesAsignadasIds = <String>[];
      final sedesLista = <Sede>[];

      for (final fila in (sedesRows as List<dynamic>)) {
        final sedeMap = fila['sede'] as Map<String, dynamic>?;
        if (sedeMap == null) continue;
        final nombreSede = sedeMap['nombre'] as String? ?? '';
        final nombreCorto = sedeMap['nombre_corto'] as String? ?? '';
        final tipoSedeStr = sedeMap['tipo_sede'] as String? ?? 'clinica';
        final tipoSede = switch (tipoSedeStr) {
          'centro_ambulatorio' => TipoSede.centroAmbulatorio,
          'laboratorio' => TipoSede.laboratorio,
          _ => TipoSede.clinica,
        };

        // Buscar si existe un id de sede equivalente en los datos simulados por nombre
        final sedeSimulada = datos.sedes.cast<Sede?>().firstWhere(
          (s) => s?.nombre == nombreSede,
          orElse: () => null,
        );
        final idSede = sedeSimulada?.id ?? 's${sedeMap['id_sede']}';
        sedesAsignadasIds.add(idSede);

        sedesLista.add(
          Sede(
            id: idSede,
            nombre: nombreSede,
            nombreCorto: nombreCorto,
            tipo: tipoSede,
          ),
        );
      }

      // Si por id simulado coincide con los datos locales, enriquecemos saludo
      final usuarioSimulado = datos.usuarios.cast<Usuario?>().firstWhere(
        (u) => u?.correo.toLowerCase() == correoLimpio,
        orElse: () => null,
      );

      final usuario = Usuario(
        id: usuarioSimulado?.id ?? user.id,
        nombre: nombreCompleto,
        saludo: usuarioSimulado?.saludo ?? _calcularSaludo(nombreCompleto, rol),
        iniciales:
            usuarioSimulado?.iniciales ?? _calcularIniciales(nombreCompleto),
        correo: correoLimpio,
        rol: rol,
        sedesAsignadas: sedesAsignadasIds,
      );

      _usuarioActual = usuario;
      return AuthExito(usuario: usuario, sedes: sedesLista);
    } on AuthException catch (e) {
      return AuthErrorCredenciales(e.message);
    } catch (e) {
      return AuthErrorRed(e.toString());
    }
  }

  @override
  Future<void> cerrarSesion() async {
    _usuarioActual = null;
    try {
      await cliente.auth.signOut();
    } catch (_) {}
  }

  static String _calcularSaludo(String nombre, Rol rol) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final primerNombre = partes.isNotEmpty ? partes.first : nombre;
    return switch (rol) {
      Rol.medico => 'Dr(a). $primerNombre',
      Rol.administrativo => primerNombre,
      Rol.auditor => primerNombre,
    };
  }

  static String _calcularIniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'U';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}
