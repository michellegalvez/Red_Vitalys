// lib/models/patient.dart

enum EncounterType {
  hospitalizacion,
  urgencias,
  consultaExterna,
}

enum EncounterStatus {
  enCurso,
  finalizada,
}

enum RiskFactorImpact {
  sube,
  baja,
}

class SystemIdentifier {
  final String systemName;
  final String identifier;

  const SystemIdentifier({
    required this.systemName,
    required this.identifier,
  });
}

class RiskFactor {
  final String name;
  final RiskFactorImpact impact;
  final double points;
  final String description;

  const RiskFactor({
    required this.name,
    required this.impact,
    required this.points,
    this.description = 'Aumenta el riesgo',
  });
}

class ReadmissionRisk {
  final double score; // 0 a 100
  final double threshold; // 70 por regla AD-10
  final DateTime calculatedDate;
  final String periodDescription;
  final List<RiskFactor> factors;

  const ReadmissionRisk({
    required this.score,
    this.threshold = 70.0,
    required this.calculatedDate,
    required this.periodDescription,
    required this.factors,
  });

  bool get isHighRisk => score >= threshold;
}

class Encounter {
  final String id;
  final EncounterType type;
  final EncounterStatus status;
  final String facilityName;
  final DateTime startDate;
  final DateTime? endDate;
  final int? lengthOfStayDays;
  final String dischargeDestination;
  final String doctorName;
  final String? reason;
  final String? diagnosis;

  const Encounter({
    required this.id,
    required this.type,
    required this.status,
    required this.facilityName,
    required this.startDate,
    this.endDate,
    this.lengthOfStayDays,
    required this.dischargeDestination,
    required this.doctorName,
    this.reason,
    this.diagnosis,
  });

  String get typeLabel {
    switch (type) {
      case EncounterType.hospitalizacion:
        return 'Hospitalización';
      case EncounterType.urgencias:
        return 'Urgencias';
      case EncounterType.consultaExterna:
        return 'Consulta externa';
    }
  }

  String get statusLabel {
    switch (status) {
      case EncounterStatus.enCurso:
        return 'En curso';
      case EncounterStatus.finalizada:
        return 'Finalizada';
    }
  }
}

class Patient {
  final String id; // ID unificado en Red Vitalys (AD-09)
  final String fullName;
  final int age;
  final String sex;
  final String documentType;
  final String documentNumber;
  final DateTime birthDate;
  final String address;
  final List<SystemIdentifier> systemIdentifiers;
  final ReadmissionRisk? readmissionRisk;
  final List<Encounter> encounters;

  const Patient({
    required this.id,
    required this.fullName,
    required this.age,
    required this.sex,
    required this.documentType,
    required this.documentNumber,
    required this.birthDate,
    required this.address,
    required this.systemIdentifiers,
    this.readmissionRisk,
    this.encounters = const [],
  });

  String get documentDisplay => '$documentType - $documentNumber';
}
