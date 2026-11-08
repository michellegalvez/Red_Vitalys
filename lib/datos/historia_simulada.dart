/// Historia clínica simulada de cada paciente (RNF-02, RNF-04). Ninguno de
/// estos datos es real.
///
/// La historia de Jorge Eliécer Pardo es la del diseño. Las de los demás se
/// arman con sus datos de la lista (sede del alta, fechas, estancia y riesgo)
/// para que la lista, la historia y el riesgo siempre cuenten lo mismo.
library;

import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';

/// Teléfono de contacto de cada paciente (F-03). Ninguno es real.
const _telefonos = <String, String>{
  'p1': '310 555 0101',
  'p2': '311 555 0102',
  'p3': '312 555 0103',
  'p4': '313 555 0104',
  'p5': '314 555 0105',
  'p6': '315 555 0106',
  'p7': '316 555 0107',
  'p8': '317 555 0108',
  'p9': '318 555 0109',
  'p10': '319 555 0110',
  'p11': '320 555 0111',
  'p12': '321 555 0112',
  'p13': '322 555 0113',
};

/// Sede del control previo de cada paciente: es otra sede de la red, para
/// que su historia reúna atenciones de varias sedes (F-02, RNF-04).
String _sedeControl(String sedeAlta) =>
    sedeAlta == 'Amb. Cali Sur' ? 'Amb. Envigado' : 'Amb. Cali Sur';

/// Dirección de residencia de cada paciente (F-02). Ninguna es real.
const _direcciones = <String, String>{
  'p1': 'Cra 24 # 5-60, Cali',
  'p2': 'Cl 70 # 11-25, Bogotá',
  'p3': 'Cra 43A # 1-50, Medellín',
  'p4': 'Cl 84 # 52-10, Barranquilla',
  'p5': 'Cra 33 # 48-12, Bucaramanga',
  'p6': 'Cl 5 # 38-40, Cali',
  'p7': 'Cra 15 # 93-20, Bogotá',
  'p8': 'Cl 10 # 42-18, Cali',
  'p9': 'Cra 7 # 60-35, Bogotá',
  'p10': 'Cl 9 Sur # 43-15, Envigado',
  'p11': 'Cra 52 # 76-30, Barranquilla',
  'p12': 'Cl 36 # 27-44, Bucaramanga',
  'p13': 'Cra 80 # 33-12, Medellín',
};

/// Destino al alta de la hospitalización de cada paciente, para que no todos
/// sean iguales.
const _destinos = [
  'Domicilio',
  'Atención domiciliaria',
  'Domicilio',
  'Traslado a otra institución',
];

const _medicos = [
  'Dra. Camila Martínez',
  'Dr. Tomás Herrera',
  'Dra. Paula Vélez',
];

EncounterType _tipoDe(TipoAtencion t) => switch (t) {
  TipoAtencion.hospitalizacion => EncounterType.hospitalizacion,
  TipoAtencion.urgencias => EncounterType.urgencias,
  TipoAtencion.consultaExterna => EncounterType.consultaExterna,
};

DateTime _dia(DateTime f) => DateTime(f.year, f.month, f.day);

/// Los factores del riesgo de [p]. Los de Jorge son los del diseño; los demás
/// se reparten en proporción a su riesgo, con un factor que lo baja.
List<RiskFactor> _factores(PacienteEnSeguimiento p) {
  if (p.id == 'p1') {
    return const [
      RiskFactor(name: 'Estancia de esta hospitalización', points: 20),
      RiskFactor(
        name: 'Consultas a urgencias en los últimos 12 meses',
        points: 16,
      ),
      RiskFactor(name: 'Edad', points: 14),
      RiskFactor(name: 'Condiciones crónicas registradas', points: 7),
      RiskFactor(name: 'Destino al alta', points: 5),
      RiskFactor(name: 'Seguimiento ambulatorio programado', points: -8),
    ];
  }
  int escala(int base) => (base * p.riesgo / 91).round().clamp(1, 99);
  return [
    RiskFactor(name: 'Estancia de esta hospitalización', points: escala(20)),
    RiskFactor(
      name: 'Consultas a urgencias en los últimos 12 meses',
      points: escala(16),
    ),
    RiskFactor(name: 'Edad', points: escala(14)),
    RiskFactor(name: 'Condiciones crónicas registradas', points: escala(7)),
    RiskFactor(name: 'Seguimiento ambulatorio programado', points: -escala(8)),
  ];
}

/// Las atenciones de [p] de la más reciente a la más antigua, con las
/// [nuevas] que se hayan registrado en esta sesión (F-02, F-04).
List<Encounter> _atenciones(
  PacienteEnSeguimiento p,
  String sedeAlta,
  List<Encounter> nuevas,
) {
  final numero = int.tryParse(p.id.replaceAll(RegExp(r'\D'), '')) ?? 0;
  // La historia de Jorge es la del diseño: la atendió la Dra. Camila.
  final medico = p.id == 'p1'
      ? _medicos.first
      : _medicos[numero % _medicos.length];
  final alta = _dia(p.fechaAlta);
  final base = <Encounter>[
    Encounter(
      id: 'enc-${p.id}-1',
      type: _tipoDe(p.tipoAtencion),
      status: EncounterStatus.finalizada,
      facilityName: sedeAlta,
      startDate: alta.subtract(Duration(days: p.diasEstancia)),
      endDate: alta,
      lengthOfStayDays: p.diasEstancia,
      dischargeDestination: p.id == 'p1' ? 'Domicilio' : _destinos[numero % 4],
      doctorName: medico,
    ),
    if (p.id == 'p1') ...[
      Encounter(
        id: 'enc-p1-2',
        type: EncounterType.urgencias,
        status: EncounterStatus.finalizada,
        facilityName: 'Bogotá Usaquén',
        startDate: DateTime(2026, 5, 2),
        endDate: DateTime(2026, 5, 2),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: 'Dra. Camila Martínez',
      ),
      Encounter(
        id: 'enc-p1-3',
        type: EncounterType.urgencias,
        status: EncounterStatus.finalizada,
        facilityName: 'Amb. Cali Sur',
        startDate: DateTime(2026, 1, 18),
        endDate: DateTime(2026, 1, 18),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: 'Dra. Camila Martínez',
      ),
    ] else
      Encounter(
        id: 'enc-${p.id}-0',
        type: EncounterType.consultaExterna,
        status: EncounterStatus.finalizada,
        facilityName: _sedeControl(sedeAlta),
        startDate: alta.subtract(Duration(days: p.diasEstancia + 75)),
        endDate: alta.subtract(Duration(days: p.diasEstancia + 75)),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: medico,
      ),
  ];
  return ordenarAtenciones([...nuevas, ...base]);
}

/// La historia clínica unificada de [p] (F-02, F-03, F-07).
///
/// [sedeAlta] es el nombre corto de la sede del alta y [nuevas] las atenciones
/// que el médico registró en esta sesión.
Patient historiaDe(
  PacienteEnSeguimiento p, {
  required String sedeAlta,
  required DateTime hoy,
  List<Encounter> nuevas = const [],
}) {
  final inicio = _dia(p.fechaAlta).subtract(Duration(days: p.diasEstancia));
  return Patient(
    id: 'pac-${p.id}',
    fullName: p.nombre,
    age: p.edad,
    sex: p.sexo == 'M' ? 'Masculino' : 'Femenino',
    documentType: p.tipoDocumento,
    documentNumber: p.numeroDocumento,
    birthDate: DateTime(hoy.year - p.edad, 6, 2),
    phone: _telefonos[p.id] ?? 'No registrado',
    address: _direcciones[p.id] ?? 'No registrada',
    systemIdentifiers: [
      SystemIdentifier(
        systemName: 'HCE $sedeAlta',
        identifier:
            'HCE-${p.numeroDocumento.substring(p.numeroDocumento.length - 6)}',
      ),
      SystemIdentifier(
        systemName: 'Laboratorio central',
        identifier: 'LAB-${p.id.substring(1).padLeft(4, '0')}${p.edad}',
      ),
    ],
    readmissionRisk: ReadmissionRisk(
      score: p.riesgo,
      calculatedDate: _dia(p.fechaAlta).add(const Duration(days: 7)),
      periodDescription:
          'calculado del ${formatoFecha(inicio)} al ${formatoFecha(p.fechaAlta)}',
      factors: _factores(p),
    ),
    encounters: _atenciones(p, sedeAlta, nuevas),
  );
}
