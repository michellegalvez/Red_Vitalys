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

/// Motivo y diagnóstico de la hospitalización de cada paciente.
const _motivos = <String, (String, String)>{
  'p1': (
    'Insuficiencia cardíaca descompensada',
    'I50.9 Insuficiencia cardíaca no especificada',
  ),
  'p2': (
    'Neumonía adquirida en la comunidad',
    'J18.9 Neumonía no especificada',
  ),
  'p3': ('EPOC reagudizado', 'J44.1 EPOC con exacerbación aguda'),
  'p4': ('Crisis hipertensiva', 'I16.9 Crisis hipertensiva'),
  'p5': ('Infección urinaria complicada', 'N39.0 Infección de vías urinarias'),
  'p6': ('Diabetes descompensada', 'E11.65 Diabetes con hiperglucemia'),
  'p7': ('Apendicitis aguda', 'K35.8 Apendicitis aguda'),
  'p8': ('Bronquiolitis', 'J21.9 Bronquiolitis aguda'),
  'p9': ('Fractura de cadera', 'S72.0 Fractura del cuello del fémur'),
  'p10': ('Cirugía de rodilla', 'M17.1 Gonartrosis primaria'),
  'p11': ('Colecistitis aguda', 'K81.0 Colecistitis aguda'),
  'p12': ('Trauma por caída', 'S06.0 Conmoción cerebral'),
  'p13': ('Parto por cesárea', 'O82 Parto por cesárea'),
};

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
  final (motivo, diagnostico) =
      _motivos[p.id] ?? ('Atención médica', 'Sin diagnóstico registrado');
  final numero = int.tryParse(p.id.replaceAll(RegExp(r'\D'), '')) ?? 0;
  // La historia de Jorge es la del diseño: la atendió la Dra. Camila.
  final medico = p.id == 'p1'
      ? _medicos.first
      : _medicos[numero % _medicos.length];
  final alta = _dia(p.fechaAlta);
  // Las atenciones llevan hora (F-02); las simuladas son de media mañana.
  Duration manana(int minutos) => Duration(hours: 9, minutes: minutos);
  final base = <Encounter>[
    Encounter(
      id: 'enc-${p.id}-1',
      type: _tipoDe(p.tipoAtencion),
      status: EncounterStatus.finalizada,
      facilityName: sedeAlta,
      startDate: alta.subtract(Duration(days: p.diasEstancia)).add(manana(30)),
      endDate: alta.add(manana(30)),
      lengthOfStayDays: p.diasEstancia,
      dischargeDestination: 'Domicilio',
      doctorName: medico,
      reason: motivo,
      diagnosis: diagnostico,
    ),
    if (p.id == 'p1') ...[
      Encounter(
        id: 'enc-p1-2',
        type: EncounterType.urgencias,
        status: EncounterStatus.finalizada,
        facilityName: 'Bogotá Usaquén',
        startDate: DateTime(2026, 5, 2, 14, 10),
        endDate: DateTime(2026, 5, 2, 15, 5),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: 'Dra. Camila Martínez',
        reason: 'Disnea súbita',
        diagnosis: 'R06.0 Disnea',
      ),
      Encounter(
        id: 'enc-p1-3',
        type: EncounterType.urgencias,
        status: EncounterStatus.finalizada,
        facilityName: 'Amb. Cali Sur',
        startDate: DateTime(2026, 1, 18, 8, 45),
        endDate: DateTime(2026, 1, 18, 9, 30),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: 'Dra. Camila Martínez',
        reason: 'Control urgente de hipertensión',
        diagnosis: 'I10 Hipertensión esencial',
      ),
    ] else
      Encounter(
        id: 'enc-${p.id}-0',
        type: EncounterType.consultaExterna,
        status: EncounterStatus.finalizada,
        facilityName: _sedeControl(sedeAlta),
        startDate: alta
            .subtract(Duration(days: p.diasEstancia + 75))
            .add(manana(0)),
        endDate: alta
            .subtract(Duration(days: p.diasEstancia + 75))
            .add(manana(40)),
        lengthOfStayDays: 0,
        dischargeDestination: 'Domicilio',
        doctorName: medico,
        reason: 'Control programado',
        diagnosis: 'Z00.0 Examen médico general',
      ),
  ];
  return [...nuevas, ...base]
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
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
