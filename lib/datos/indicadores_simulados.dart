/// Mediciones simuladas de los indicadores (RNF-02, RNF-04). Ninguna es real.
///
/// Son las de los últimos 6 meses cerrados de cada sede a la que el indicador
/// aplica. Los valores del último periodo son los del diseño del Figma; los
/// de los meses anteriores salen de una mejora gradual, para que la tendencia
/// y el cambio frente al mes previo tengan sentido.
library;

import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/reglas/indicadores.dart';

/// Valor del último periodo por sede. Las sedes que no aparecen no tienen el
/// indicador (por ejemplo, los centros ambulatorios no miden el reingreso).
const _ultimoPeriodo = <IdIndicador, Map<String, double>>{
  IdIndicador.reingreso: {
    's1': 9.8,
    's2': 6.8,
    's3': 7.4,
    's4': 8.0,
    's5': 8.6,
    's6': 9.2,
  },
  IdIndicador.espera: {
    's1': 28.4,
    's2': 31.2,
    's3': 24.6,
    's4': 22.8,
    's5': 27.0,
    's6': 20.4,
    's7': 26.6,
    's8': 25.4,
  },
  IdIndicador.adherencia: {
    's1': 84.2,
    's2': 82.6,
    's3': 88.1,
    's4': 90.3,
    's5': 85.5,
    's6': 91.0,
    's7': 87.1,
    's8': 86.4,
  },
  IdIndicador.eventos: {
    's1': 2.4,
    's2': 2.1,
    's3': 1.9,
    's4': 1.4,
    's5': 1.7,
    's6': 1.2,
    's7': 2.0,
    's8': 1.7,
  },
};

/// Cuánto se alejaba cada mes del último, del más antiguo al más reciente.
/// Con signo: en los que mejoran hacia abajo es positivo y en la adherencia,
/// que mejora hacia arriba, es negativo.
const _distancia = <IdIndicador, List<double>>{
  IdIndicador.reingreso: [1.5, 1.1, 0.8, 0.5, 0.3, 0],
  IdIndicador.espera: [6.0, 5.0, 4.0, 2.5, 1.5, 0],
  IdIndicador.adherencia: [-4.5, -3.7, -2.9, -1.9, -1.1, 0],
  IdIndicador.eventos: [0.6, 0.4, 0.3, 0.2, 0.1, 0],
};

/// Las mediciones de los últimos 6 meses cerrados antes de [hoy].
///
/// Los *Amb. Envigado* (`s8`) no tiene la medición de eventos adversos del
/// último periodo: así se ve el caso *Sin medición* (RF-26) y el
/// administrativo puede registrarla.
List<Medicion> medicionesSimuladas(DateTime hoy) {
  final periodos = periodosCerrados(hoy);
  final mediciones = <Medicion>[];
  for (final entrada in _ultimoPeriodo.entries) {
    final id = entrada.key;
    var i = 0;
    for (final MapEntry(key: sedeId, value: ultimo) in entrada.value.entries) {
      // Cada sede se mueve un poco distinto, sin cambiar el promedio de la red.
      final escala = 0.9 + 0.1 * (i % 3);
      for (var m = 0; m < periodos.length; m++) {
        final esUltimo = m == periodos.length - 1;
        if (esUltimo && id == IdIndicador.eventos && sedeId == 's8') continue;
        final valor = (ultimo + _distancia[id]![m] * escala).clamp(0, 1440);
        mediciones.add(
          Medicion(
            indicador: id,
            sedeId: sedeId,
            periodo: periodos[m],
            valor: redondear1(valor.toDouble()),
          ),
        );
      }
      i++;
    }
  }
  return mediciones;
}
