import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/repositorios/auditoria_traduccion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Los eventos en la tabla `evento_auditoria` de Supabase.
///
/// La app todavía usa los ids simulados (`u1`, `s1`) y la base usa uuid y
/// números, así que este repositorio traduce en los dos sentidos: el usuario
/// sale de la sesión de Supabase y se vuelve a reconocer por su correo; la
/// sede, por su nombre.
///
/// No manda la IP ni la fecha: las pone la base (AD-15). Tampoco el paciente,
/// porque la tabla `paciente` todavía no existe (P-01).
class AuditoriaSupabase implements AuditoriaRepositorio {
  AuditoriaSupabase({
    required this.cliente,
    required this.sedesPorNombre,
    required this.usuariosPorCorreo,
  });

  final SupabaseClient cliente;

  /// Nombre de la sede → id que usa la app.
  final Map<String, String> sedesPorNombre;

  /// Correo del usuario → id que usa la app.
  final Map<String, String> usuariosPorCorreo;

  /// Id de la app → `id_sede` de la base. Se pide una sola vez.
  Map<String, int>? _idsDeSede;

  @override
  bool get esRemoto => true;

  Future<Map<String, int>> _sedes() async {
    final cargadas = _idsDeSede;
    if (cargadas != null) return cargadas;
    final filas = await cliente.from('sede').select('id_sede, nombre');
    final ids = <String, int>{};
    for (final fila in filas) {
      final idApp = sedesPorNombre[fila['nombre'] as String];
      if (idApp != null) ids[idApp] = fila['id_sede'] as int;
    }
    return _idsDeSede = ids;
  }

  @override
  Future<void> agregar(EventoAuditoria evento) async {
    String? idUsuario;
    if (evento.usuarioId != null) {
      idUsuario = cliente.auth.currentUser?.id;
      if (idUsuario == null) {
        throw StateError('No hay sesión de Supabase para guardar el evento');
      }
    }
    final sedeId = evento.sedeId;
    final idSede = sedeId == null ? null : (await _sedes())[sedeId];
    final proposito = evento.proposito;
    await cliente.from('evento_auditoria').insert({
      'id_usuario': idUsuario,
      'accion': accionATexto(evento.accion),
      'tipo_recurso': recursoATexto(evento.recurso),
      'resultado': resultadoATexto(evento.resultado),
      'proposito_uso': proposito == null ? null : propositoATexto(proposito),
      'id_sede': idSede,
      'correo_intento': evento.correoIntento,
    });
  }

  @override
  Future<List<EventoAuditoria>> listar() async {
    final filas = await cliente
        .from('evento_auditoria')
        .select(
          'id_evento, fecha_hora_evento, accion, tipo_recurso, resultado, '
          'proposito_uso, correo_intento, ip, usuario(correo), sede(nombre)',
        )
        .order('fecha_hora_evento', ascending: false);
    return [
      for (final fila in filas)
        EventoAuditoria(
          id: 'e${fila['id_evento']}',
          fechaHora: DateTime.parse(fila['fecha_hora_evento'] as String)
              .toLocal(),
          accion: textoAAccion(fila['accion'] as String),
          recurso: textoARecurso(fila['tipo_recurso'] as String),
          resultado: textoAResultado(fila['resultado'] as String),
          proposito: textoAProposito(fila['proposito_uso'] as String?),
          usuarioId: usuariosPorCorreo[(fila['usuario'] as Map?)?['correo']],
          sedeId: sedesPorNombre[(fila['sede'] as Map?)?['nombre']],
          correoIntento: fila['correo_intento'] as String?,
          ip: fila['ip'] as String?,
        ),
    ];
  }
}
