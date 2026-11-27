import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';

/// The single place that says which purposes each role may declare (AD-06).
class AccessControlService {
  const AccessControlService();

  List<Proposito> purposesFor(Rol role, {bool registering = false}) =>
      registering ? propositosParaRegistrar(role) : propositosDe(role);

  ResultadoConsulta decidePurpose(
    Usuario user,
    Proposito purpose, {
    bool registering = false,
  }) {
    if (user.rol == Rol.auditor) return ResultadoConsulta.rechazoRol;
    final allowed = purposesFor(user.rol, registering: registering);
    return allowed.contains(purpose)
        ? ResultadoConsulta.permitido
        : ResultadoConsulta.rechazoProposito;
  }

  bool canDo(Rol role, AccionPermitida action) => rolPermite(role, action);

  bool hasRelationship(
    Usuario doctor,
    PacienteEnSeguimiento patient,
    DateTime today,
  ) => tieneRelacion(doctor, patient, today);

  ResultadoConsulta decideConsultation({
    required Usuario user,
    required PacienteEnSeguimiento patient,
    required Proposito purpose,
    required DateTime today,
    bool registering = false,
    bool? relationship,
  }) {
    if (user.rol == Rol.administrativo && !registering) {
      return evaluarDatosBasicos(usuario: user, proposito: purpose);
    }
    return registering
        ? evaluarRegistro(
            usuario: user,
            paciente: patient,
            proposito: purpose,
            hoy: today,
            relacion: relationship,
          )
        : evaluarConsulta(
            usuario: user,
            paciente: patient,
            proposito: purpose,
            hoy: today,
            relacion: relationship,
          );
  }
}
