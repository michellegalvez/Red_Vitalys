import 'package:red_vitalys/datos/indicadores_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';

/// Datos simulados del prototipo (RNF-02, RNF-03, RNF-04). Ninguno es real.
///
/// Los pacientes y las sedes salen del diseño del Figma. La red tiene una
/// cadena de laboratorios clínicos propia; como no se sabe cuántos son, se
/// simulan 2 (RNF-04).
class DatosSimulados {
  const DatosSimulados({
    required this.hoy,
    required this.sedes,
    required this.usuarios,
    required this.pacientes,
    required this.contrasenaPrototipo,
    required this.mediciones,
    required this.eventos,
    required this.ipPrototipo,
  });

  /// La fecha de hoy fija de los datos simulados (RNF-04).
  final DateTime hoy;
  final List<Sede> sedes;
  final List<Usuario> usuarios;
  final List<PacienteEnSeguimiento> pacientes;

  /// Contraseña única del prototipo, sin servidor.
  final String contrasenaPrototipo;

  /// Mediciones de los indicadores de los últimos 6 meses (F-08 a F-12).
  final List<Medicion> mediciones;

  /// Eventos de acceso que ya había al abrir la app (F-20, F-21).
  final List<EventoAuditoria> eventos;

  /// IP simulada de los inicios de sesión fallidos (F-20 A4, AD-15).
  final String ipPrototipo;

  Sede sede(String id) => sedes.firstWhere((s) => s.id == id);

  Usuario? usuarioPorCorreo(String correo) {
    final buscado = correo.trim().toLowerCase();
    for (final u in usuarios) {
      if (u.correo.toLowerCase() == buscado) return u;
    }
    return null;
  }

  /// La fecha de hoy fija de los datos simulados, el 6 de noviembre de 2026
  /// (RNF-04): el último periodo cerrado es octubre.
  static final DateTime _hoy = DateTime(2026, 11, 6, 10, 42);

  static final DatosSimulados porDefecto = DatosSimulados(
    hoy: _hoy,
    contrasenaPrototipo: 'vitalys2026',
    mediciones: medicionesSimuladas(_hoy),
    ipPrototipo: '192.168.10.24',
    sedes: const [
      Sede(
        id: 's1',
        nombre: 'Clínica Vitalys Cali Norte',
        nombreCorto: 'Cali Norte',
        tipo: TipoSede.clinica,
      ),
      Sede(
        id: 's2',
        nombre: 'Clínica Vitalys Bogotá Usaquén',
        nombreCorto: 'Bogotá Usaquén',
        tipo: TipoSede.clinica,
      ),
      Sede(
        id: 's3',
        nombre: 'Clínica Vitalys Bogotá Chapinero',
        nombreCorto: 'Bogotá Chapinero',
        tipo: TipoSede.clinica,
      ),
      Sede(
        id: 's4',
        nombre: 'Clínica Vitalys Medellín El Poblado',
        nombreCorto: 'Medellín El Poblado',
        tipo: TipoSede.clinica,
      ),
      Sede(
        id: 's5',
        nombre: 'Clínica Vitalys Barranquilla Prado',
        nombreCorto: 'Barranquilla Prado',
        tipo: TipoSede.clinica,
      ),
      Sede(
        id: 's6',
        nombre: 'Clínica Vitalys Bucaramanga Cabecera',
        nombreCorto: 'Bucaramanga Cabecera',
        tipo: TipoSede.clinica,
      ),
      Sede(
        id: 's7',
        nombre: 'Centro Ambulatorio Cali Sur',
        nombreCorto: 'Amb. Cali Sur',
        tipo: TipoSede.centroAmbulatorio,
      ),
      Sede(
        id: 's8',
        nombre: 'Centro Ambulatorio Envigado',
        nombreCorto: 'Amb. Envigado',
        tipo: TipoSede.centroAmbulatorio,
      ),
      Sede(
        id: 'l1',
        nombre: 'Laboratorio Clínico Vitalys Cali',
        nombreCorto: 'Lab. Cali',
        tipo: TipoSede.laboratorio,
      ),
      Sede(
        id: 'l2',
        nombre: 'Laboratorio Clínico Vitalys Bogotá',
        nombreCorto: 'Lab. Bogotá',
        tipo: TipoSede.laboratorio,
      ),
    ],
    usuarios: const [
      Usuario(
        id: 'u1',
        nombre: 'Dra. Camila Martínez',
        saludo: 'Dra. Camila',
        iniciales: 'CM',
        correo: 'camila.martinez@vitalys.co',
        rol: Rol.medico,
        sedesAsignadas: ['s1', 's7'],
      ),
      Usuario(
        id: 'u2',
        nombre: 'Andrés Felipe Ruiz',
        saludo: 'Andrés',
        iniciales: 'AR',
        correo: 'andres.ruiz@vitalys.co',
        rol: Rol.administrativo,
        sedesAsignadas: ['s2'],
      ),
      Usuario(
        id: 'u3',
        nombre: 'Marcela Ospina',
        saludo: 'Marcela',
        iniciales: 'MO',
        correo: 'marcela.ospina@vitalys.co',
        rol: Rol.auditor,
        sedesAsignadas: ['s1'],
      ),
      // Cuenta sin sedes asignadas, para mostrar el caso A3 de F-13.
      Usuario(
        id: 'u4',
        nombre: 'Dr. Tomás Herrera',
        saludo: 'Dr. Tomás',
        iniciales: 'TH',
        correo: 'tomas.herrera@vitalys.co',
        rol: Rol.medico,
        sedesAsignadas: [],
      ),
    ],
    // Los 8 eventos de la auditoría del Figma (RNF-04: 2 denegados y 1 de
    // emergencia). La sede es la primera sede asignada de cada usuario.
    eventos: [
      EventoAuditoria(
        id: 'e1',
        usuarioId: 'u2',
        fechaHora: DateTime(2026, 10, 30, 9, 47),
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.riesgoReingreso,
        pacienteId: 'p2',
        proposito: Proposito.revisionCalidad,
        resultado: ResultadoAuditoria.denegado,
        sedeId: 's2',
      ),
      EventoAuditoria(
        id: 'e2',
        usuarioId: 'u2',
        fechaHora: DateTime(2026, 10, 30, 9, 44),
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.datosBasicos,
        pacienteId: 'p4',
        proposito: Proposito.revisionCalidad,
        resultado: ResultadoAuditoria.permitido,
        sedeId: 's2',
      ),
      EventoAuditoria(
        id: 'e3',
        usuarioId: 'u1',
        fechaHora: DateTime(2026, 10, 30, 9, 31),
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.historiaClinica,
        pacienteId: 'p1',
        proposito: Proposito.consultaHistoria,
        resultado: ResultadoAuditoria.permitido,
        sedeId: 's1',
      ),
      EventoAuditoria(
        id: 'e4',
        usuarioId: 'u1',
        fechaHora: DateTime(2026, 10, 30, 9, 12),
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.historiaClinica,
        pacienteId: 'p2',
        proposito: Proposito.seguimientoReingreso,
        resultado: ResultadoAuditoria.permitido,
        sedeId: 's1',
      ),
      EventoAuditoria(
        id: 'e5',
        usuarioId: 'u1',
        fechaHora: DateTime(2026, 10, 29, 16, 5),
        accion: AccionAuditoria.registrar,
        recurso: RecursoAuditoria.atencion,
        pacienteId: 'p3',
        proposito: Proposito.atencionPaciente,
        resultado: ResultadoAuditoria.permitido,
        sedeId: 's1',
      ),
      EventoAuditoria(
        id: 'e6',
        usuarioId: 'u3',
        fechaHora: DateTime(2026, 10, 29, 11, 20),
        accion: AccionAuditoria.ingresar,
        recurso: RecursoAuditoria.sesion,
        resultado: ResultadoAuditoria.permitido,
        sedeId: 's1',
      ),
      EventoAuditoria(
        id: 'e7',
        usuarioId: 'u1',
        fechaHora: DateTime(2026, 10, 28, 15, 48),
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.historiaClinica,
        pacienteId: 'p5',
        proposito: Proposito.urgencia,
        resultado: ResultadoAuditoria.permitido,
        sedeId: 's1',
      ),
      EventoAuditoria(
        id: 'e8',
        usuarioId: 'u3',
        fechaHora: DateTime(2026, 10, 28, 10, 2),
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.historiaClinica,
        pacienteId: 'p1',
        proposito: Proposito.revisionCalidad,
        resultado: ResultadoAuditoria.denegado,
        sedeId: 's1',
      ),
    ],
    // La Dra. Camila tiene relación con p1 (le registró una atención), con
    // p2 (alta en Cali Norte) y con p8 (alta en Amb. Cali Sur). Con los demás
    // no, y solo puede abrirlos declarando Urgencia (F-05, F-17).
    // Los pacientes, riesgos y fechas son los del diseño del Figma.
    pacientes: [
      PacienteEnSeguimiento(
        id: 'p1',
        nombre: 'Jorge Eliécer Pardo Villamizar',
        iniciales: 'JP',
        edad: 78,
        sexo: 'M',
        tipoDocumento: 'CC',
        numeroDocumento: '79457654',
        sedeAltaId: 's2',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 10, 14),
        diasEstancia: 15,
        riesgo: 91,
        medicosConAtencion: const ['u1'],
      ),
      PacienteEnSeguimiento(
        id: 'p2',
        nombre: 'María Fernanda Rojas Benítez',
        iniciales: 'MR',
        edad: 75,
        sexo: 'F',
        tipoDocumento: 'CC',
        numeroDocumento: '31285876',
        sedeAltaId: 's1',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 10, 16),
        diasEstancia: 11,
        riesgo: 82,
      ),
      PacienteEnSeguimiento(
        id: 'p3',
        nombre: 'Hernán Darío Quintero Salcedo',
        iniciales: 'HQ',
        edad: 71,
        sexo: 'M',
        tipoDocumento: 'CC',
        numeroDocumento: '72105531',
        sedeAltaId: 's5',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 10, 17),
        diasEstancia: 16,
        riesgo: 77,
      ),
      PacienteEnSeguimiento(
        id: 'p4',
        nombre: 'Carlos Andrés Gómez Ruiz',
        iniciales: 'CG',
        edad: 63,
        sexo: 'M',
        tipoDocumento: 'CC',
        numeroDocumento: '80234310',
        sedeAltaId: 's3',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 10, 15),
        diasEstancia: 7,
        riesgo: 72,
      ),
      PacienteEnSeguimiento(
        id: 'p5',
        nombre: 'Luz Marina Cardona Arias',
        iniciales: 'LC',
        edad: 67,
        sexo: 'F',
        tipoDocumento: 'CC',
        numeroDocumento: '43518902',
        sedeAltaId: 's4',
        tipoAtencion: TipoAtencion.urgencias,
        fechaAlta: DateTime(2026, 10, 15),
        diasEstancia: 1,
        riesgo: 48,
      ),
      PacienteEnSeguimiento(
        id: 'p6',
        nombre: 'Ana Lucía Ibarra Medina',
        iniciales: 'AI',
        edad: 58,
        sexo: 'F',
        tipoDocumento: 'CC',
        numeroDocumento: '63451204',
        sedeAltaId: 's6',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 10, 18),
        diasEstancia: 6,
        riesgo: 37,
      ),
      PacienteEnSeguimiento(
        id: 'p7',
        nombre: 'Santiago Restrepo Mejía',
        iniciales: 'SR',
        edad: 14,
        sexo: 'M',
        tipoDocumento: 'TI',
        numeroDocumento: '1023456778',
        sedeAltaId: 's4',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 10, 13),
        diasEstancia: 3,
        riesgo: 23,
      ),
      PacienteEnSeguimiento(
        id: 'p8',
        nombre: 'Valentina Ortiz Salazar',
        iniciales: 'VO',
        edad: 3,
        sexo: 'F',
        tipoDocumento: 'RC',
        numeroDocumento: '1107052145',
        sedeAltaId: 's7',
        tipoAtencion: TipoAtencion.urgencias,
        fechaAlta: DateTime(2026, 10, 19),
        diasEstancia: 0,
        riesgo: 12,
      ),
      // Alta hace 38 días: no sale en la lista aunque su riesgo sea alto.
      PacienteEnSeguimiento(
        id: 'p9',
        nombre: 'Rosa Elena Muñoz Patiño',
        iniciales: 'RM',
        edad: 81,
        sexo: 'F',
        tipoDocumento: 'CC',
        numeroDocumento: '29874512',
        sedeAltaId: 's1',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 9, 22),
        diasEstancia: 9,
        riesgo: 88,
      ),
      // Pacientes con alta de hace más de 30 días: no salen en la lista de
      // altas recientes, pero sí en la búsqueda (F-01).
      PacienteEnSeguimiento(
        id: 'p10',
        nombre: 'Ricardo Alberto Henao Zuluaga',
        iniciales: 'RH',
        edad: 69,
        sexo: 'M',
        tipoDocumento: 'CC',
        numeroDocumento: '70589234',
        sedeAltaId: 's3',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 9, 20),
        diasEstancia: 8,
        riesgo: 54,
      ),
      PacienteEnSeguimiento(
        id: 'p11',
        nombre: 'Gloria Patricia Mejía Londoño',
        iniciales: 'GM',
        edad: 72,
        sexo: 'F',
        tipoDocumento: 'CC',
        numeroDocumento: '43217655',
        sedeAltaId: 's4',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 8, 30),
        diasEstancia: 12,
        riesgo: 66,
      ),
      PacienteEnSeguimiento(
        id: 'p12',
        nombre: 'Andrés Felipe Cárdenas Rueda',
        iniciales: 'AC',
        edad: 45,
        sexo: 'M',
        tipoDocumento: 'CC',
        numeroDocumento: '1098765432',
        sedeAltaId: 's6',
        tipoAtencion: TipoAtencion.urgencias,
        fechaAlta: DateTime(2026, 10, 2),
        diasEstancia: 0,
        riesgo: 31,
      ),
      PacienteEnSeguimiento(
        id: 'p13',
        nombre: 'Daniela Sofía Pineda Ocampo',
        iniciales: 'DP',
        edad: 29,
        sexo: 'F',
        tipoDocumento: 'CC',
        numeroDocumento: '1144092211',
        sedeAltaId: 's1',
        tipoAtencion: TipoAtencion.hospitalizacion,
        fechaAlta: DateTime(2026, 7, 15),
        diasEstancia: 4,
        riesgo: 18,
      ),
    ],
  );
}
