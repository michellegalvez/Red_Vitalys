import 'package:red_vitalys/modelos/modelos.dart';

/// Los textos que usa la tabla `evento_auditoria` de Supabase para cada valor
/// de la app (docs/modelo.md). Funciones puras, sin Supabase.

String accionATexto(AccionAuditoria a) => switch (a) {
  AccionAuditoria.ingresar => 'ingresar',
  AccionAuditoria.consultar => 'consultar',
  AccionAuditoria.registrar => 'registrar',
};

String recursoATexto(RecursoAuditoria r) => switch (r) {
  RecursoAuditoria.sesion => 'sesion',
  RecursoAuditoria.datosBasicos => 'datos_basicos',
  RecursoAuditoria.historiaClinica => 'historia_clinica',
  RecursoAuditoria.riesgoReingreso => 'riesgo_reingreso',
  RecursoAuditoria.atencion => 'atencion',
  RecursoAuditoria.medicionIndicador => 'medicion_indicador',
  RecursoAuditoria.pacientesAltaReciente => 'pacientes_alta_reciente',
  RecursoAuditoria.auditoriaAccesos => 'auditoria_accesos',
};

String resultadoATexto(ResultadoAuditoria r) => switch (r) {
  ResultadoAuditoria.permitido => 'permitido',
  ResultadoAuditoria.denegado => 'denegado',
};

String propositoATexto(Proposito p) => switch (p) {
  Proposito.seguimientoReingreso => 'seguimiento_reingreso',
  Proposito.consultaHistoria => 'consulta_historia',
  Proposito.atencionPaciente => 'atencion_paciente',
  Proposito.revisionCalidad => 'revision_calidad',
  Proposito.urgencia => 'urgencia',
};

AccionAuditoria textoAAccion(String t) =>
    AccionAuditoria.values.firstWhere((a) => accionATexto(a) == t);

RecursoAuditoria textoARecurso(String t) =>
    RecursoAuditoria.values.firstWhere((r) => recursoATexto(r) == t);

ResultadoAuditoria textoAResultado(String t) =>
    ResultadoAuditoria.values.firstWhere((r) => resultadoATexto(r) == t);

Proposito? textoAProposito(String? t) {
  if (t == null) return null;
  return Proposito.values.firstWhere((p) => propositoATexto(p) == t);
}
