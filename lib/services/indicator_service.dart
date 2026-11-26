import 'package:red_vitalys/modelos/indicadores.dart';

/// Gives and saves the monthly measurements of the quality indicators (AD-11).
abstract interface class IndicatorService {
  bool get isRemote;

  Future<List<Medicion>> listMeasurements();

  Future<void> addMeasurement(Medicion measurement, {required String siteName});
}

/// The measurement already exists for that indicator, site and month (F-12).
class DuplicateMeasurement implements Exception {
  const DuplicateMeasurement();
}
