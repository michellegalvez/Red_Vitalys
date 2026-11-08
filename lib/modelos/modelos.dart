/// Modelos del prototipo. Siguen las entidades de la architectural spine
/// (sedes, usuarios con su rol y sedes asignadas, pacientes en seguimiento)
/// y viven en memoria: todavía no hay base de datos.
library;

enum Rol { medico, administrativo, auditor }

extension RolTexto on Rol {
  String get nombre => switch (this) {
    Rol.medico => 'Médico',
    Rol.administrativo => 'Administrativo',
    Rol.auditor => 'Auditor',
  };
}

enum TipoSede { clinica, centroAmbulatorio, laboratorio }

class Sede {
  const Sede({
    required this.id,
    required this.nombre,
    required this.nombreCorto,
    required this.tipo,
  });

  final String id;
  final String nombre;
  final String nombreCorto;
  final TipoSede tipo;
}

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.saludo,
    required this.iniciales,
    required this.correo,
    required this.rol,
    required this.sedesAsignadas,
  });

  final String id;
  final String nombre;

  /// Cómo se le saluda en el inicio, por ejemplo "Dra. Camila".
  final String saludo;
  final String iniciales;
  final String correo;
  final Rol rol;

  /// Ids de las sedes desde las que puede ingresar (RF-18).
  final List<String> sedesAsignadas;
}

enum TipoAtencion { hospitalizacion, urgencias, consultaExterna }

extension TipoAtencionTexto on TipoAtencion {
  String get nombre => switch (this) {
    TipoAtencion.hospitalizacion => 'Hospitalización',
    TipoAtencion.urgencias => 'Urgencias',
    TipoAtencion.consultaExterna => 'Consulta externa',
  };
}

/// Un paciente dado de alta en los últimos 30 días, con su riesgo de
/// reingreso ya calculado (AD-10: la app no calcula el riesgo).
class PacienteEnSeguimiento {
  const PacienteEnSeguimiento({
    required this.id,
    required this.nombre,
    required this.iniciales,
    required this.edad,
    required this.sexo,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.sedeAltaId,
    required this.tipoAtencion,
    required this.fechaAlta,
    required this.diasEstancia,
    required this.riesgo,
    this.medicosConAtencion = const [],
  });

  final String id;
  final String nombre;
  final String iniciales;
  final int edad;

  /// "M" o "F".
  final String sexo;

  /// "CC", "TI" o "RC".
  final String tipoDocumento;
  final String numeroDocumento;
  final String sedeAltaId;
  final TipoAtencion tipoAtencion;
  final DateTime fechaAlta;

  /// 0 significa que la atención fue el mismo día.
  final int diasEstancia;

  /// Número entero de 0 a 100 (F-06).
  final int riesgo;

  /// Ids de los médicos que le registraron una atención con el propósito
  /// *Atención del paciente*, que les da relación (RF-25).
  final List<String> medicosConAtencion;

  /// Copia con otros médicos con atención. El resto no cambia.
  PacienteEnSeguimiento copyWith({List<String>? medicosConAtencion}) {
    return PacienteEnSeguimiento(
      id: id,
      nombre: nombre,
      iniciales: iniciales,
      edad: edad,
      sexo: sexo,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
      sedeAltaId: sedeAltaId,
      tipoAtencion: tipoAtencion,
      fechaAlta: fechaAlta,
      diasEstancia: diasEstancia,
      riesgo: riesgo,
      medicosConAtencion: medicosConAtencion ?? this.medicosConAtencion,
    );
  }

  /// Documento con solo los últimos 4 dígitos, por ejemplo "CC ··· 7654".
  String get documentoOculto {
    final n = numeroDocumento;
    final ultimos = n.length <= 4 ? n : n.substring(n.length - 4);
    return '$tipoDocumento ··· $ultimos';
  }
}

/// Los 5 propósitos de RF-19, con los textos del diálogo de la galería.
enum Proposito {
  seguimientoReingreso,
  consultaHistoria,
  atencionPaciente,
  revisionCalidad,
  urgencia,
}

extension PropositoTexto on Proposito {
  String get nombre => switch (this) {
    Proposito.seguimientoReingreso => 'Seguimiento de reingreso',
    Proposito.consultaHistoria => 'Consulta de historia clínica',
    Proposito.atencionPaciente => 'Atención del paciente',
    Proposito.revisionCalidad => 'Revisión de calidad',
    Proposito.urgencia => 'Urgencia (acceso de emergencia)',
  };

  String get descripcion => switch (this) {
    Proposito.seguimientoReingreso =>
      'Revisar a un paciente dado de alta y su riesgo de reingreso.',
    Proposito.consultaHistoria =>
      'Leer atenciones y datos del paciente sin registrar nada.',
    Proposito.atencionPaciente =>
      'Atender o registrar una atención del paciente.',
    Proposito.revisionCalidad =>
      'Revisar casos para los indicadores de calidad de la red.',
    Proposito.urgencia =>
      'Acceso inmediato por riesgo vital. Queda marcado para el auditor.',
  };

  /// Nombre corto, sin la aclaración entre paréntesis.
  String get nombreCorto => this == Proposito.urgencia ? 'Urgencia' : nombre;
}

/// Las 3 acciones de un evento de acceso (F-20).
enum AccionAuditoria { ingresar, consultar, registrar }

extension AccionAuditoriaTexto on AccionAuditoria {
  String get nombre => switch (this) {
    AccionAuditoria.ingresar => 'Ingresar',
    AccionAuditoria.consultar => 'Consultar',
    AccionAuditoria.registrar => 'Registrar',
  };
}

/// Los recursos sobre los que se hace una acción, con los nombres de F-20.
enum RecursoAuditoria {
  sesion,
  datosBasicos,
  historiaClinica,
  riesgoReingreso,
  atencion,
  medicionIndicador,
  pacientesAltaReciente,
  auditoriaAccesos,
}

extension RecursoAuditoriaTexto on RecursoAuditoria {
  String get nombre => switch (this) {
    RecursoAuditoria.sesion => 'Sesión',
    RecursoAuditoria.datosBasicos => 'Datos básicos',
    RecursoAuditoria.historiaClinica => 'Historia clínica',
    RecursoAuditoria.riesgoReingreso => 'Riesgo de reingreso',
    RecursoAuditoria.atencion => 'Atención',
    RecursoAuditoria.medicionIndicador => 'Medición de indicador',
    RecursoAuditoria.pacientesAltaReciente => 'Pacientes con alta reciente',
    RecursoAuditoria.auditoriaAccesos => 'Auditoría de accesos',
  };
}

enum ResultadoAuditoria { permitido, denegado }

extension ResultadoAuditoriaTexto on ResultadoAuditoria {
  String get nombre => switch (this) {
    ResultadoAuditoria.permitido => 'Permitido',
    ResultadoAuditoria.denegado => 'Denegado',
  };
}

/// Un evento de acceso (EVENTO_AUDITORIA del MER, más la sede de F-20).
///
/// Solo se crean: ningún evento se edita ni se borra (AD-08), por eso todos
/// sus campos son finales y no hay forma de cambiarlos.
class EventoAuditoria {
  const EventoAuditoria({
    required this.id,
    required this.fechaHora,
    required this.accion,
    required this.recurso,
    required this.resultado,
    this.usuarioId,
    this.correoIntento,
    this.pacienteId,
    this.proposito,
    this.sedeId,
    this.ip,
  });

  final String id;

  /// Quien hizo la acción. Vacío en un inicio de sesión fallido.
  final String? usuarioId;

  /// El correo escrito en un inicio de sesión fallido (F-20 A4).
  final String? correoIntento;

  /// Vacío en *Ingresar*, en las mediciones, en la lista de pacientes con
  /// alta reciente y en la auditoría de accesos.
  final String? pacienteId;
  final DateTime fechaHora;
  final AccionAuditoria accion;
  final RecursoAuditoria recurso;
  final ResultadoAuditoria resultado;

  /// Vacío significa *No aplica*: inicio de sesión y medición.
  final Proposito? proposito;

  /// La sede de la sesión. Vacía en un inicio de sesión fallido.
  final String? sedeId;

  /// Solo en los inicios de sesión fallidos.
  final String? ip;

  /// Es de emergencia si se declaró *Urgencia* (F-17).
  bool get esEmergencia => proposito == Proposito.urgencia;

  String get propositoTexto => proposito?.nombreCorto ?? 'No aplica';
}

/// Los 3 filtros de la auditoría, excluyentes (F-21).
enum FiltroAuditoria { todos, denegados, emergencia }

extension FiltroAuditoriaTexto on FiltroAuditoria {
  String get nombre => switch (this) {
    FiltroAuditoria.todos => 'Todos',
    FiltroAuditoria.denegados => 'Denegados',
    FiltroAuditoria.emergencia => 'Emergencia',
  };
}
