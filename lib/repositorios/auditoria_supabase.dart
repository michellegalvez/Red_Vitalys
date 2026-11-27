import 'package:flutter/foundation.dart';
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
/// El paciente se traduce por su documento principal. No manda la IP ni la
/// fecha: las pone la base (AD-15).
class AuditoriaSupabase implements AuditoriaRepositorio {
  AuditoriaSupabase({
    required this.cliente,
    required this.sedesPorNombre,
    required this.usuariosPorCorreo,
    required this.pacientesPorDocumento,
  });

  final SupabaseClient cliente;

  /// Nombre de la sede → id que usa la app.
  final Map<String, String> sedesPorNombre;

  /// Correo del usuario → id que usa la app.
  final Map<String, String> usuariosPorCorreo;

  /// Número de documento → id del paciente en la app. Un paciente que la app
  /// no conoce se llama `db<id_paciente>`.
  final Map<String, String> pacientesPorDocumento;

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

  /// El `id_paciente` de la base, o `null` si no se puede saber: entonces el
  /// evento se guarda sin paciente en lugar de perderse (AD-07).
  Future<int?> _idDePaciente(String idApp) async {
    if (idApp.startsWith('db')) return int.tryParse(idApp.substring(2));
    final documento = pacientesPorDocumento.entries
        .where((e) => e.value == idApp)
        .map((e) => e.key)
        .firstOrNull;
    if (documento == null) return null;
    final filas = await cliente
        .from('identificador_paciente')
        .select('id_paciente')
        .eq('numero_identificacion', documento)
        .eq('es_principal', true)
        .limit(1);
    if (filas.isEmpty) {
      debugPrint('No se encontró el paciente del evento de auditoría');
      return null;
    }
    return filas.first['id_paciente'] as int;
  }

  /// `id_paciente` → id de la app, para los pacientes de la auditoría.
  Future<Map<int, String>> _pacientesDeLosEventos() async {
    final filas = await cliente.rpc<List<dynamic>>('pacientes_de_auditoria');
    return {
      for (final fila in filas.cast<Map<String, dynamic>>())
        fila['id_paciente'] as int:
            pacientesPorDocumento[fila['numero_identificacion']] ??
            'db${fila['id_paciente']}',
    };
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
    final pacienteId = evento.pacienteId;
    final idPaciente = pacienteId == null
        ? null
        : await _idDePaciente(pacienteId);
    await cliente.from('evento_auditoria').insert({
      'id_usuario': idUsuario,
      'id_paciente': idPaciente,
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
          'proposito_uso, correo_intento, ip, id_paciente, '
          'id_usuario_afectado, usuario(correo), '
          'sede(nombre)',
        )
        .order('fecha_hora_evento', ascending: false);
    final pacientes = filas.any((f) => f['id_paciente'] != null)
        ? await _pacientesDeLosEventos()
        : const <int, String>{};
    final cuentas = filas.any((f) => f['id_usuario_afectado'] != null)
        ? await _correosDeCuentas()
        : const <String, String>{};
    return [for (final fila in filas) ?_evento(fila, pacientes, cuentas)];
  }

  /// El correo de cada cuenta, para los cambios que hizo el director (F-24).
  Future<Map<String, String>> _correosDeCuentas() async {
    final filas = await cliente.from('usuario').select('id_usuario, correo');
    return {
      for (final fila in filas)
        fila['id_usuario'] as String: fila['correo'] as String,
    };
  }

  /// Un evento que esta versión no sabe leer se salta en vez de dejar la
  /// auditoría sin ninguno (F-21).
  EventoAuditoria? _evento(
    Map<String, dynamic> fila,
    Map<int, String> pacientes,
    Map<String, String> cuentas,
  ) {
    try {
      return EventoAuditoria(
        id: 'e${fila['id_evento']}',
        fechaHora: DateTime.parse(fila['fecha_hora_evento'] as String)
            .toLocal(),
        accion: textoAAccion(fila['accion'] as String),
        recurso: textoARecurso(fila['tipo_recurso'] as String),
        resultado: textoAResultado(fila['resultado'] as String),
        proposito: textoAProposito(fila['proposito_uso'] as String?),
        usuarioId: usuariosPorCorreo[(fila['usuario'] as Map?)?['correo']],
        sedeId: sedesPorNombre[(fila['sede'] as Map?)?['nombre']],
        pacienteId: pacientes[fila['id_paciente']],
        correoIntento: fila['correo_intento'] as String?,
        ip: fila['ip'] as String?,
        cuentaAfectada: cuentas[fila['id_usuario_afectado']],
      );
    } catch (error) {
      debugPrint('Evento de auditoría que no se pudo leer: $error');
      return null;
    }
  }
}
