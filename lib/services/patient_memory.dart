import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/patient_service.dart';

/// Gives the simulated patients, for the tests and for running without Supabase.
class PatientMemory implements PatientService {
  PatientMemory(this._data);

  final DatosSimulados _data;

  @override
  bool get isRemote => false;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async =>
      List.unmodifiable(_data.pacientes);
}
