import 'package:red_vitalys/modelos/modelos.dart';

/// Gives the patients with their latest discharge and stored risk (AD-02, AD-10).
abstract interface class PatientService {
  bool get isRemote;

  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today);
}
