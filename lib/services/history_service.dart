import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';

/// Gives the unified clinical history of a patient (AD-02, AD-09, AD-10).
abstract interface class HistoryService {
  bool get isRemote;

  Future<Patient> historyOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  });

  /// The latest stored readmission risk, loaded apart from the history so its
  /// own error can be shown (F-07 CA-8).
  Future<ReadmissionRisk?> riskOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  });

  /// Saves [encounter]. A remote source saves its audit event in the same
  /// operation (F-04 step 4, F-20) and throws `AuditEventNotSaved` if the
  /// event cannot be created; [sessionSiteName] is the site of that event
  /// (AD-05). Returns the id of the saved encounter, or `null` if the source
  /// does not give one.
  Future<String?> addEncounter(
    PacienteEnSeguimiento patient,
    NuevaAtencion encounter, {
    required String siteName,
    required Proposito purpose,
    required String? sessionSiteName,
  });
}
