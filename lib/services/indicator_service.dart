import 'package:red_vitalys/modelos/indicadores.dart';

/// Gives and saves the monthly measurements of the quality indicators (AD-11).
abstract interface class IndicatorService {
  bool get isRemote;

  Future<List<Medicion>> listMeasurements();

  /// Saves [measurement]. A remote source saves its audit event in the same
  /// operation (F-12, F-20) and throws `AuditEventNotSaved` if the event
  /// cannot be created; [sessionSiteName] is the site of that event.
  Future<void> addMeasurement(
    Medicion measurement, {
    required String siteName,
    required String? sessionSiteName,
  });
}

/// The measurement already exists for that indicator, site and month (F-12).
class DuplicateMeasurement implements Exception {
  const DuplicateMeasurement();
}
