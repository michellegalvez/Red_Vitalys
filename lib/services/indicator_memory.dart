import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/services/indicator_service.dart';

class IndicatorMemory implements IndicatorService {
  IndicatorMemory(this._data);

  final DatosSimulados _data;

  @override
  bool get isRemote => false;

  @override
  Future<List<Medicion>> listMeasurements() async =>
      List.unmodifiable(_data.mediciones);

  @override
  Future<void> addMeasurement(
    Medicion measurement, {
    required String siteName,
  }) async {}
}
