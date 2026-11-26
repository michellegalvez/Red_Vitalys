import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/history_service.dart';

/// Builds the simulated history, for the tests and for running without Supabase.
class HistoryMemory implements HistoryService {
  const HistoryMemory();

  @override
  bool get isRemote => false;

  @override
  Future<Patient> historyOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  }) async => historiaDe(patient, sedeAlta: siteName, hoy: today);
}
