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

  Future<void> addEncounter(
    PacienteEnSeguimiento patient,
    NuevaAtencion encounter, {
    required String siteName,
    required Proposito purpose,
  });
}
