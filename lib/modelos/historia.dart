/// Historia clínica unificada de un paciente: sus datos, el identificador en
/// cada sistema de origen, sus atenciones y el riesgo de reingreso con los
/// factores que lo explican (F-02, F-03, F-04, F-07). Viven en memoria.
library;

enum EncounterType { hospitalizacion, urgencias, consultaExterna }

enum EncounterStatus { enCurso, finalizada }

enum RiskFactorImpact { sube, baja }

/// Identificador del paciente en uno de los sistemas de origen (AD-09).
class SystemIdentifier {
  const SystemIdentifier({required this.systemName, required this.identifier});

  final String systemName;
  final String identifier;
}

/// Un factor del riesgo. Los puntos llevan signo: positivos suben el riesgo
/// y negativos lo bajan (F-07).
class RiskFactor {
  const RiskFactor({required this.name, required this.points});

  final String name;
  final int points;

  RiskFactorImpact get impact =>
      points >= 0 ? RiskFactorImpact.sube : RiskFactorImpact.baja;
}

/// Riesgo de reingreso ya calculado: la app lo muestra tal cual (AD-10).
class ReadmissionRisk {
  const ReadmissionRisk({
    required this.score,
    required this.calculatedDate,
    required this.periodDescription,
    required this.factors,
  });

  /// Número entero de 0 a 100.
  final int score;
  final DateTime calculatedDate;
  final String periodDescription;
  final List<RiskFactor> factors;

  /// Lo que el modelo asigna antes de los factores. Base más factores da
  /// el puntaje, así que la explicación cuadra con el número (F-07).
  int get basePoints =>
      score - factors.fold<int>(0, (suma, f) => suma + f.points);

  /// Los factores del que más pesa al que menos, sin mirar si suben o bajan.
  /// Con la misma magnitud va primero el que sube (F-07).
  List<RiskFactor> get orderedFactors {
    final conPosicion = [
      for (var i = 0; i < factors.length; i++) (i, factors[i]),
    ];
    conPosicion.sort((a, b) {
      final porMagnitud = b.$2.points.abs().compareTo(a.$2.points.abs());
      if (porMagnitud != 0) return porMagnitud;
      final porEfecto = b.$2.points.compareTo(a.$2.points);
      return porEfecto != 0 ? porEfecto : a.$1.compareTo(b.$1);
    });
    return [for (final (_, f) in conPosicion) f];
  }
}

class Encounter {
  const Encounter({
    required this.id,
    required this.type,
    required this.status,
    required this.facilityName,
    required this.startDate,
    this.endDate,
    this.lengthOfStayDays,
    this.dischargeDestination,
    required this.doctorName,
  });

  final String id;
  final EncounterType type;
  final EncounterStatus status;
  final String facilityName;
  final DateTime startDate;
  final DateTime? endDate;
  final int? lengthOfStayDays;
  final String? dischargeDestination;
  final String doctorName;

  String get typeLabel => switch (type) {
    EncounterType.hospitalizacion => 'Hospitalización',
    EncounterType.urgencias => 'Urgencias',
    EncounterType.consultaExterna => 'Consulta externa',
  };

  String get statusLabel => switch (status) {
    EncounterStatus.enCurso => 'En curso',
    EncounterStatus.finalizada => 'Finalizada',
  };
}

class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    required this.age,
    required this.sex,
    required this.documentType,
    required this.documentNumber,
    required this.birthDate,
    required this.phone,
    required this.address,
    required this.systemIdentifiers,
    this.readmissionRisk,
    this.encounters = const [],
  });

  /// Identificador unificado en Red Vitalys (AD-09).
  final String id;
  final String fullName;
  final int age;

  /// "Masculino" o "Femenino".
  final String sex;
  final String documentType;
  final String documentNumber;
  final DateTime birthDate;

  /// Teléfono de contacto (F-03).
  final String phone;

  /// Dirección de residencia (F-02).
  final String address;
  final List<SystemIdentifier> systemIdentifiers;
  final ReadmissionRisk? readmissionRisk;

  /// De la más reciente a la más antigua por fecha de inicio.
  final List<Encounter> encounters;

  String get documentDisplay => '$documentType $documentNumber';
}
