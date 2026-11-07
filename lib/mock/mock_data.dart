// lib/mock/mock_data.dart

import '../models/patient.dart';

class MockData {
  /// Paciente de ejemplo para las pantallas de Detalle de Historia Clínica
  /// y Registro de Atención, reflejando fielmente el diseño de la Entrega 2.
  static final Patient jorgePardo = Patient(
    id: 'pac-001',
    fullName: 'Jorge Eliécer Pardo Villamizar',
    age: 78,
    sex: 'Masculino',
    documentType: 'CC',
    documentNumber: '7654',
    birthDate: DateTime(1948, 6, 2),
    address: 'Cra 7 # 116-50, Bogotá',
    systemIdentifiers: const [
      SystemIdentifier(
        systemName: 'HCE Clínicas',
        identifier: 'CC - 7654',
      ),
      SystemIdentifier(
        systemName: 'Laboratorio central',
        identifier: 'CC - 7654',
      ),
    ],
    readmissionRisk: ReadmissionRisk(
      score: 91.2,
      threshold: 70.0,
      calculatedDate: DateTime(2026, 10, 21),
      periodDescription: 'calculado del 29 sep 2026 al 14 oct 2026',
      factors: const [
        RiskFactor(
          name: 'Estancia de esta hospitalización',
          impact: RiskFactorImpact.sube,
          points: 20.4,
          description: 'Aumenta el riesgo',
        ),
        RiskFactor(
          name: 'Consultas a urgencias en los últimos 12 meses',
          impact: RiskFactorImpact.sube,
          points: 16.1,
          description: 'Aumenta el riesgo',
        ),
        RiskFactor(
          name: 'Edad',
          impact: RiskFactorImpact.sube,
          points: 13.6,
          description: 'Aumenta el riesgo',
        ),
        RiskFactor(
          name: 'Condiciones crónicas registradas',
          impact: RiskFactorImpact.sube,
          points: 6.9,
          description: 'Aumenta el riesgo',
        ),
        RiskFactor(
          name: 'Destino al alta',
          impact: RiskFactorImpact.sube,
          points: 5.2,
          description: 'Aumenta el riesgo',
        ),
      ],
    ),
    encounters: [
      Encounter(
        id: 'enc-001',
        type: EncounterType.hospitalizacion,
        status: EncounterStatus.finalizada,
        facilityName: 'Bogotá Usaquén',
        startDate: DateTime(2026, 9, 29),
        endDate: DateTime(2026, 10, 14),
        lengthOfStayDays: 15,
        dischargeDestination: 'Domicilio',
        doctorName: 'Dra. Camila Martínez',
        reason: 'Insuficiencia cardíaca descompensada',
        diagnosis: 'I50.9 Insuficiencia cardíaca no especificada',
      ),
      Encounter(
        id: 'enc-002',
        type: EncounterType.urgencias,
        status: EncounterStatus.finalizada,
        facilityName: 'Bogotá Usaquén',
        startDate: DateTime(2026, 5, 2),
        endDate: DateTime(2026, 5, 2),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: 'Dra. Camila Martínez',
        reason: 'Disnea súbita',
        diagnosis: 'R06.0 Disnea',
      ),
      Encounter(
        id: 'enc-003',
        type: EncounterType.urgencias,
        status: EncounterStatus.finalizada,
        facilityName: 'Amb. Cali Sur',
        startDate: DateTime(2026, 1, 18),
        endDate: DateTime(2026, 1, 18),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: 'Dra. Camila Martínez',
        reason: 'Control urgente de hipertensión',
        diagnosis: 'I10 Hipertensión esencial',
      ),
    ],
  );

  /// Sedes disponibles en la red para el selector del formulario
  static const List<String> availableFacilities = [
    'Clínica Vitalys Cali Norte',
    'Clínica Vitalys Bogotá Usaquén',
    'Centro Ambulatorio Cali Sur',
    'Centro Ambulatorio Medellín Poblado',
  ];

  /// Destinos al alta disponibles
  static const List<String> dischargeDestinations = [
    'Sin definir',
    'Domicilio',
    'Traslado a otra institución',
    'Hospitalización en casa',
    'Fallecido',
  ];
}
