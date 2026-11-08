/// Reglas de negocio del prototipo, definidas en un solo lugar.
///
/// No son servicios ni repositorios: son funciones puras que las pantallas
/// usan para decidir qué mostrar. El control de acceso real llega después.
library;

import 'package:red_vitalys/modelos/modelos.dart';

/// Umbral de la alerta de riesgo (RF-06, AD-10).
const int umbralAlerta = 70;

/// Límites de la sesión (AD-14, RF-35, RF-36).
const int intentosParaBloqueo = 5;
const Duration duracionBloqueo = Duration(minutes: 15);
const Duration limiteInactividad = Duration(minutes: 15);

/// Días que cuenta un alta reciente (RF-05, RF-25).
const int diasAltaReciente = 30;

/// Mínimo de caracteres para buscar (F-01).
const int minimoCaracteresBusqueda = 3;

/// Mensajes del inicio de sesión (F-13, F-14).
const String mensajeDatosIncorrectos = 'Correo o contraseña incorrectos.';
const String mensajeCamposVacios = 'Escriba su correo y su contraseña.';
const String mensajeBloqueo =
    'Demasiados intentos fallidos. Intente de nuevo en 15 minutos.';
const String mensajeSinSedes = 'Su cuenta no tiene sedes asignadas.';
const String mensajeElijaSede = 'Elija la sede desde la que ingresa.';
const String mensajeInactividad = 'Su sesión se cerró por inactividad.';

/// Mensajes de rechazo según la causa (F-18).
const String rechazoRol = 'Su rol no permite esta acción.';
const String rechazoProposito = 'Su rol no puede declarar ese propósito.';
const String rechazoRelacion =
    'No tiene relación con este paciente. Si es una emergencia, declare '
    'Urgencia.';

/// Mensajes del propósito (F-16) y del acceso de emergencia (F-17).
const String mensajeElijaProposito = 'Elija el propósito de la consulta.';
const String avisoDeclarandoUrgencia =
    'Está declarando un acceso de emergencia.';
const String avisoAccesoEmergencia =
    'Acceso de emergencia: queda registrado y el auditor lo revisará.';

/// Mensaje de la lista sin altas recientes (F-06).
const String mensajeSinAltas =
    'No hay pacientes dados de alta en los últimos 30 días';

bool conAlerta(int riesgo) => riesgo >= umbralAlerta;

int _diasDesde(DateTime fecha, DateTime hoy) => DateTime(
  hoy.year,
  hoy.month,
  hoy.day,
).difference(DateTime(fecha.year, fecha.month, fecha.day)).inDays;

/// Pacientes con alta en los últimos 30 días, del mayor al menor riesgo;
/// con el mismo riesgo va primero el alta más reciente (F-06).
List<PacienteEnSeguimiento> pacientesConAltaReciente(
  List<PacienteEnSeguimiento> pacientes,
  DateTime hoy,
) {
  final recientes = [
    for (final p in pacientes)
      if (_diasDesde(p.fechaAlta, hoy) <= diasAltaReciente) p,
  ];
  recientes.sort((a, b) {
    final porRiesgo = b.riesgo.compareTo(a.riesgo);
    return porRiesgo != 0 ? porRiesgo : b.fechaAlta.compareTo(a.fechaAlta);
  });
  return List.unmodifiable(recientes);
}

/// Propósitos que puede declarar cada rol (tabla de permisos, RF-34).
List<Proposito> propositosDe(Rol rol) => switch (rol) {
  Rol.medico => Proposito.values,
  Rol.administrativo => const [Proposito.revisionCalidad],
  Rol.auditor => const [],
};

/// Propósitos con los que se puede registrar una atención: *Atención del
/// paciente* y *Urgencia* (F-04).
List<Proposito> propositosParaRegistrar(Rol rol) => [
  for (final p in propositosDe(rol))
    if (p == Proposito.atencionPaciente || p == Proposito.urgencia) p,
];

/// Relación médico-paciente (RF-25, F-05): registró una atención suya con
/// *Atención del paciente*, o el paciente fue dado de alta en los últimos
/// 30 días en una de sus sedes asignadas.
bool tieneRelacion(Usuario medico, PacienteEnSeguimiento p, DateTime hoy) {
  if (medico.rol != Rol.medico) return false;
  if (p.medicosConAtencion.contains(medico.id)) return true;
  return medico.sedesAsignadas.contains(p.sedeAltaId) &&
      _diasDesde(p.fechaAlta, hoy) <= diasAltaReciente;
}

/// Resultado de validar el correo y la contraseña (F-13, F-14).
enum ResultadoIngreso {
  valido,
  camposVacios,
  bloqueado,
  datosIncorrectos,
  sinSedes,
}

extension ResultadoIngresoTexto on ResultadoIngreso {
  String? get mensaje => switch (this) {
    ResultadoIngreso.valido => null,
    ResultadoIngreso.camposVacios => mensajeCamposVacios,
    ResultadoIngreso.bloqueado => mensajeBloqueo,
    ResultadoIngreso.datosIncorrectos => mensajeDatosIncorrectos,
    ResultadoIngreso.sinSedes => mensajeSinSedes,
  };

  /// Solo los datos incorrectos suman al conteo del bloqueo (F-14).
  bool get cuentaComoFallo => this == ResultadoIngreso.datosIncorrectos;
}

/// Valida un intento de ingreso. El mismo mensaje sale si el correo no
/// existe o si la contraseña está mal (F-13).
ResultadoIngreso evaluarIngreso({
  required String correo,
  required String contrasena,
  required Usuario? usuario,
  required String contrasenaValida,
  required bool bloqueado,
}) {
  if (correo.trim().isEmpty || contrasena.isEmpty) {
    return ResultadoIngreso.camposVacios;
  }
  if (bloqueado) return ResultadoIngreso.bloqueado;
  if (usuario == null || contrasena != contrasenaValida) {
    return ResultadoIngreso.datosIncorrectos;
  }
  if (usuario.sedesAsignadas.isEmpty) return ResultadoIngreso.sinSedes;
  return ResultadoIngreso.valido;
}

/// Resultado de intentar abrir la historia de un paciente.
enum ResultadoConsulta {
  permitido,
  rechazoRol,
  rechazoProposito,
  rechazoRelacion,
}

extension ResultadoConsultaTexto on ResultadoConsulta {
  String? get mensaje => switch (this) {
    ResultadoConsulta.permitido => null,
    ResultadoConsulta.rechazoRol => rechazoRol,
    ResultadoConsulta.rechazoProposito => rechazoProposito,
    ResultadoConsulta.rechazoRelacion => rechazoRelacion,
  };
}

/// Decide si se permiten ver los datos básicos de un paciente (F-03).
///
/// El administrativo solo puede declarar *Revisión de calidad*; el auditor no
/// consulta pacientes. El médico los ve dentro de la historia (F-02).
ResultadoConsulta evaluarDatosBasicos({
  required Usuario usuario,
  required Proposito proposito,
}) {
  if (usuario.rol == Rol.auditor) return ResultadoConsulta.rechazoRol;
  if (!propositosDe(usuario.rol).contains(proposito)) {
    return ResultadoConsulta.rechazoProposito;
  }
  return ResultadoConsulta.permitido;
}

/// Decide si se permite abrir la historia de un paciente (F-05, F-17, F-18).
ResultadoConsulta evaluarConsulta({
  required Usuario usuario,
  required PacienteEnSeguimiento paciente,
  required Proposito proposito,
  required DateTime hoy,
}) {
  if (usuario.rol != Rol.medico) return ResultadoConsulta.rechazoRol;
  if (!propositosDe(usuario.rol).contains(proposito)) {
    return ResultadoConsulta.rechazoProposito;
  }
  if (proposito == Proposito.urgencia) return ResultadoConsulta.permitido;
  return tieneRelacion(usuario, paciente, hoy)
      ? ResultadoConsulta.permitido
      : ResultadoConsulta.rechazoRelacion;
}

/// Decide si el usuario puede registrar una atención: solo el médico, con
/// *Atención del paciente* o *Urgencia*, y con las mismas reglas de relación
/// que para abrir la historia (F-04, F-05, F-18).
ResultadoConsulta evaluarRegistro({
  required Usuario usuario,
  required PacienteEnSeguimiento paciente,
  required Proposito proposito,
  required DateTime hoy,
}) {
  if (!rolPermite(usuario.rol, AccionPermitida.registrarAtencion)) {
    return ResultadoConsulta.rechazoRol;
  }
  if (!propositosParaRegistrar(usuario.rol).contains(proposito)) {
    return ResultadoConsulta.rechazoProposito;
  }
  return evaluarConsulta(
    usuario: usuario,
    paciente: paciente,
    proposito: proposito,
    hoy: hoy,
  );
}

// -----------------------------------------------------------------------
// Tabla de permisos (F-18) y auditoría de accesos (F-20, F-21)
// -----------------------------------------------------------------------

/// Las 7 acciones de la tabla de permisos de F-18, en su orden. El perfil
/// (F-22) se arma con esta misma tabla (AD-06).
enum AccionPermitida {
  buscarPaciente,
  verHistoria,
  registrarAtencion,
  verTablero,
  registrarMedicion,
  verAuditoria,
  verPerfil,
}

extension AccionPermitidaTexto on AccionPermitida {
  String get nombre => switch (this) {
    AccionPermitida.buscarPaciente => 'Buscar paciente y ver sus datos básicos',
    AccionPermitida.verHistoria =>
      'Ver la historia clínica y el riesgo de reingreso',
    AccionPermitida.registrarAtencion => 'Registrar una atención',
    AccionPermitida.verTablero =>
      'Ver el tablero y el detalle de los indicadores',
    AccionPermitida.registrarMedicion => 'Registrar una medición',
    AccionPermitida.verAuditoria => 'Ver la auditoría de accesos',
    AccionPermitida.verPerfil => 'Ver el perfil y cerrar sesión',
  };
}

/// Si el rol tiene la acción en la tabla de F-18. Lo que no está, se
/// rechaza.
bool rolPermite(Rol rol, AccionPermitida accion) => switch (accion) {
  AccionPermitida.buscarPaciente => rol != Rol.auditor,
  AccionPermitida.verHistoria => rol == Rol.medico,
  AccionPermitida.registrarAtencion => rol == Rol.medico,
  AccionPermitida.verTablero => true,
  AccionPermitida.registrarMedicion => rol == Rol.administrativo,
  AccionPermitida.verAuditoria => rol == Rol.auditor,
  AccionPermitida.verPerfil => true,
};

/// Mensaje de la auditoría cuando el filtro no tiene eventos (F-21 A4).
const String mensajeSinEventos = 'No hay eventos con este filtro';

/// Los eventos que cumplen el filtro, del más reciente al más antiguo
/// (F-21). Con la misma fecha y hora va primero el que se agregó último.
List<EventoAuditoria> eventosFiltrados(
  List<EventoAuditoria> eventos,
  FiltroAuditoria filtro,
) {
  final conOrden = [
    for (var i = 0; i < eventos.length; i++)
      if (switch (filtro) {
        FiltroAuditoria.todos => true,
        FiltroAuditoria.denegados =>
          eventos[i].resultado == ResultadoAuditoria.denegado,
        FiltroAuditoria.emergencia => eventos[i].esEmergencia,
      })
        (indice: i, evento: eventos[i]),
  ];
  conOrden.sort((a, b) {
    final porFecha = b.evento.fechaHora.compareTo(a.evento.fechaHora);
    return porFecha != 0 ? porFecha : b.indice.compareTo(a.indice);
  });
  return List.unmodifiable([for (final e in conOrden) e.evento]);
}
