/// Indicadores de calidad y sus mediciones mensuales por sede (F-08 a F-12).
/// Viven en memoria: todavía no hay base de datos.
library;

import 'package:red_vitalys/modelos/modelos.dart';

/// Qué valor es el mejor de un indicador.
enum DireccionIndicador { masBajoEsMejor, masAltoEsMejor }

/// Los 4 indicadores de la red (*Tabla de indicadores* de los requisitos).
enum IdIndicador { reingreso, espera, adherencia, eventos }

class Indicador {
  const Indicador({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.unidad,
    required this.unidadCambio,
    required this.minimo,
    required this.maximo,
    required this.direccion,
    required this.tiposSede,
  });

  final IdIndicador id;
  final String nombre;

  /// *Resultado*, *Estructura* o *Proceso*.
  final String categoria;
  final String descripcion;

  /// Lo que va junto al valor: "%", "min" o "por 1.000".
  final String unidad;

  /// Cómo se escribe un cambio: "puntos", "min" o "por 1.000" (F-08).
  final String unidadCambio;
  final double minimo;
  final double maximo;
  final DireccionIndicador direccion;

  /// Los tipos de sede a los que el indicador aplica. Los laboratorios no
  /// tienen indicadores.
  final Set<TipoSede> tiposSede;
}

/// La medición mensual de un indicador en una sede. El valor lo digita el
/// administrativo ya calculado por la sede: la app no lo calcula (RF-13).
class Medicion {
  const Medicion({
    required this.indicador,
    required this.sedeId,
    required this.periodo,
    required this.valor,
    this.registradaPor,
    this.registradaEn,
  });

  final IdIndicador indicador;
  final String sedeId;

  /// El primer día del mes que se midió.
  final DateTime periodo;
  final double valor;

  /// Quién la registró en esta sesión. Vacío en las que ya existían.
  final String? registradaPor;
  final DateTime? registradaEn;
}

/// Cómo está una sede frente al promedio de la red (RF-09).
enum MarcaSede { mejor, peor, igual }

extension MarcaSedeTexto on MarcaSede {
  String get nombre => switch (this) {
    MarcaSede.mejor => 'Mejor que el promedio',
    MarcaSede.peor => 'Peor que el promedio',
    MarcaSede.igual => 'Igual al promedio',
  };
}

/// Una sede en la comparación de un indicador. Sin [valor] es *Sin medición*
/// (RF-26).
class FilaSede {
  const FilaSede({
    required this.sedeId,
    required this.nombre,
    this.valor,
    this.marca,
  });

  final String sedeId;
  final String nombre;
  final double? valor;
  final MarcaSede? marca;
}

/// Un mes de la tendencia. Sin [valor] es *Sin medición*.
class PuntoTendencia {
  const PuntoTendencia({required this.periodo, this.valor});

  final DateTime periodo;
  final double? valor;
}

/// Una fila de las mediciones recientes (RF-12).
class FilaMedicion {
  const FilaMedicion({
    required this.periodo,
    required this.sedeId,
    required this.sedeNombre,
    required this.valor,
    required this.marca,
  });

  final DateTime periodo;
  final String sedeId;
  final String sedeNombre;
  final double valor;
  final MarcaSede marca;
}

/// El resumen de un indicador en el tablero (RF-08, RF-27).
class ResumenIndicador {
  const ResumenIndicador({
    required this.indicador,
    this.valorRed,
    this.cambio,
    this.mejoro,
    required this.tendencia,
  });

  final Indicador indicador;

  /// Vacío si ninguna sede tiene medición (F-08 A3).
  final double? valorRed;

  /// Con signo, en la unidad del indicador. Vacío si no hay periodo anterior.
  final String? cambio;

  /// Si el cambio fue para mejor. Vacío si no hay con qué comparar.
  final bool? mejoro;

  /// El valor de la red de los últimos 6 meses. Los meses sin dato se omiten.
  final List<double> tendencia;
}
