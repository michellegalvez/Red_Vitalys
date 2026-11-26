import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';

/// Gives the unified clinical history of a patient (AD-02, AD-09, AD-10).
abstract interface class HistoryService {
  bool get isRemote;

  Future<Patient> historyOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  });
}
