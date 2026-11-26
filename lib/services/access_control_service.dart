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
}
