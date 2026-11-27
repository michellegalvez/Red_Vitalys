import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';

/// Interfaz del repositorio de historia clínica unificada y registro de
/// atenciones médicas (P-04, F-02, F-04, F-07).
///
/// Desacopla la fuente de persistencia (Supabase vs Memoria, AD-02, AD-03).
abstract class HistoriaRepositorio {
  /// Obtiene la historia clínica unificada completa del paciente por su [pacienteId],
  /// incluyendo sus identificadores por sistema de origen, todas sus atenciones
  /// históricas y su última predicción de riesgo de reingreso con factores.
  Future<Patient> obtenerHistoria(String pacienteId);

  /// Registra una nueva atención médica para el paciente [pacienteId] con los
  /// datos validados en [nueva], vinculándola al médico [medicoId] y registrando
  /// el [proposito] declarado (F-04, F-16).
  Future<Encounter> registrarAtencion({
    required String pacienteId,
    required NuevaAtencion nueva,
    required String medicoId,
    required String medicoNombre,
    required Proposito proposito,
  });
}
