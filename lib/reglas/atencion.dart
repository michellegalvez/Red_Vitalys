import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';

const mensajeElijaTipoAtencion = 'Elija el tipo de atención.';
const mensajeIndiqueFechaInicio = 'Indique la fecha de inicio.';
const mensajeFechaFutura = 'La fecha no puede ser futura';
const mensajeFechaInvalida = 'Escriba la fecha como 30 oct 2026';
const mensajeFechaAntigua = 'La fecha no puede ser anterior a 1900';
const mensajeAltaAnterior =
    'La fecha de alta no puede ser anterior a la de inicio';

/// El destino al alta que se propone (F-04).
const String destinoSinDefinir = 'Sin definir';

/// Los destinos al alta que se pueden elegir (F-04).
const List<String> destinosAlta = [
  destinoSinDefinir,
  'Domicilio',
  'Traslado a otra institución',
  'Atención domiciliaria',
];

/// La fecha más antigua que se acepta para una atención.
final DateTime fechaMinimaAtencion = DateTime(1900);

/// Lo que el médico llenó en el formulario de una atención (F-04).
typedef NuevaAtencion = ({
  EncounterType tipo,
  String sedeId,
  DateTime inicio,
  DateTime? alta,
  String destino,
});

/// El resultado de validar el formulario (F-04): los datos obligatorios que
/// faltan y el error de cada fecha. Sirve si no hay ninguno.
typedef ValidacionAtencion = ({
  List<String> faltantes,
  String? errorInicio,
  String? errorAlta,
  DateTime? inicio,
  DateTime? alta,
});

extension ValidacionAtencionTexto on ValidacionAtencion {
  bool get sirve =>
      faltantes.isEmpty && errorInicio == null && errorAlta == null;
}

DateTime _dia(DateTime f) => DateTime(f.year, f.month, f.day);

/// Lee "30 oct 2026" (RNF-05) y, por comodidad, "30/10/2026". Devuelve `null`
/// si no tiene esa forma o la fecha no
/// existe, por ejemplo "31/02/2026".
DateTime? leerFechaCampo(String texto) {
  final numerica = RegExp(r'^\s*(\d{1,2})/(\d{1,2})/(\d{4})\s*$')
      .firstMatch(texto);
  final escrita = RegExp(r'^\s*(\d{1,2})\s+([A-Za-zñÑ]{3})\.?\s+(\d{4})\s*$')
      .firstMatch(texto);
  final int d;
  final int? mes;
  final int a;
  if (numerica != null) {
    d = int.parse(numerica.group(1)!);
    mes = int.parse(numerica.group(2)!);
    a = int.parse(numerica.group(3)!);
  } else if (escrita != null) {
    d = int.parse(escrita.group(1)!);
    mes = numeroDeMes(escrita.group(2)!);
    a = int.parse(escrita.group(3)!);
  } else {
    return null;
  }
  if (mes == null) return null;
  final f = DateTime(a, mes, d);
  return f.day == d && f.month == mes && f.year == a ? f : null;
}

/// Días entre el inicio y el alta; 0 si fue el mismo día.
int duracionEnDias(DateTime inicio, DateTime alta) {
  final i = DateTime.utc(inicio.year, inicio.month, inicio.day);
  final a = DateTime.utc(alta.year, alta.month, alta.day);
  return a.difference(i).inDays;
}

/// Valida los datos de una atención (F-04). El tipo y la fecha de inicio son
/// obligatorios; la de alta es opcional.
ValidacionAtencion validarAtencion({
  required EncounterType? tipo,
  required String inicioTexto,
  required String altaTexto,
  required DateTime ahora,
}) {
  final faltantes = [
    if (tipo == null) mensajeElijaTipoAtencion,
    if (inicioTexto.trim().isEmpty) mensajeIndiqueFechaInicio,
  ];
  final hoy = _dia(ahora);

  String? error(String texto, DateTime? fecha) {
    if (texto.trim().isEmpty) return null;
    if (fecha == null) return mensajeFechaInvalida;
    if (fecha.isAfter(hoy)) return mensajeFechaFutura;
    if (fecha.isBefore(fechaMinimaAtencion)) return mensajeFechaAntigua;
    return null;
  }

  final inicio = leerFechaCampo(inicioTexto);
  final alta = leerFechaCampo(altaTexto);
  final errorInicio = error(inicioTexto, inicio);
  var errorAlta = error(altaTexto, alta);
  if (errorInicio == null &&
      errorAlta == null &&
      inicio != null &&
      alta != null &&
      alta.isBefore(inicio)) {
    errorAlta = mensajeAltaAnterior;
  }
  return (
    faltantes: faltantes,
    errorInicio: errorInicio,
    errorAlta: errorAlta,
    inicio: errorInicio == null ? inicio : null,
    alta: errorAlta == null ? alta : null,
  );
}

/// La atención ya validada, lista para entrar a la historia: *Finalizada* con
/// fecha de alta y *En curso* sin ella (F-02, F-04).
Encounter atencionDeFormulario({
  required String id,
  required NuevaAtencion nueva,
  required String sede,
  required String medico,
}) {
  final alta = nueva.alta;
  return Encounter(
    id: id,
    type: nueva.tipo,
    status: alta == null ? EncounterStatus.enCurso : EncounterStatus.finalizada,
    facilityName: sede,
    startDate: nueva.inicio,
    endDate: alta,
    lengthOfStayDays: alta == null ? null : duracionEnDias(nueva.inicio, alta),
    dischargeDestination: alta == null ? destinoSinDefinir : nueva.destino,
    doctorName: medico,
  );
}

/// Ordena las atenciones por fecha de inicio, la más reciente primero. Con la
/// misma fecha conserva el orden recibido (las nuevas van delante).
List<Encounter> ordenarAtenciones(List<Encounter> atenciones) {
  final conPosicion = [
    for (var i = 0; i < atenciones.length; i++) (i, atenciones[i]),
  ];
  conPosicion.sort((a, b) {
    final porFecha = b.$2.startDate.compareTo(a.$2.startDate);
    return porFecha != 0 ? porFecha : a.$1.compareTo(b.$1);
  });
  return [for (final (_, a) in conPosicion) a];
}
