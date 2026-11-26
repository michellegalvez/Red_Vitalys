import 'package:red_vitalys/modelos/indicadores.dart';

abstract interface class IndicatorService {
  bool get isRemote;

  Future<List<Medicion>> listMeasurements();

  Future<void> addMeasurement(Medicion measurement, {required String siteName});
}

class DuplicateMeasurement implements Exception {
  const DuplicateMeasurement();
}
