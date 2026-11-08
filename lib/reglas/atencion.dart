import 'package:red_vitalys/formato/formato.dart';

const mensajeCompleteAtencion = 'Complete el motivo y el diagnóstico';
const mensajeFechaFutura = 'La fecha no puede ser futura';
const mensajeFechaInvalida = 'Escriba la fecha como 30/10/2026 10:42';
const mensajeFechaAntigua = 'La fecha no puede ser anterior a 1900';
const mensajeMotivoLargo = 'El motivo no puede pasar de 200 caracteres';
const mensajeDiagnosticoLargo =
    'El diagnóstico no puede pasar de 200 caracteres';

const int maxCaracteresMotivo = 200;
const int maxCaracteresDiagnostico = 200;

/// La fecha más antigua que se acepta para una atención.
final DateTime fechaMinimaAtencion = DateTime(1900);

/// Valida los datos de una atención (F-04). Devuelve el mensaje de rechazo o,
/// si sirve, la fecha ya leída.
({String? error, DateTime? fecha}) validarAtencion({
  required String motivo,
  required String diagnostico,
  required String fechaTexto,
  required DateTime ahora,
}) {
  final m = motivo.trim();
  final d = diagnostico.trim();
  if (m.isEmpty || d.isEmpty) {
    return (error: mensajeCompleteAtencion, fecha: null);
  }
  if (m.length > maxCaracteresMotivo) {
    return (error: mensajeMotivoLargo, fecha: null);
  }
  if (d.length > maxCaracteresDiagnostico) {
    return (error: mensajeDiagnosticoLargo, fecha: null);
  }
  final fecha = leerFechaHoraCampo(fechaTexto);
  if (fecha == null) return (error: mensajeFechaInvalida, fecha: null);
  if (fecha.isAfter(ahora)) return (error: mensajeFechaFutura, fecha: null);
  if (fecha.isBefore(fechaMinimaAtencion)) {
    return (error: mensajeFechaAntigua, fecha: null);
  }
  return (error: null, fecha: fecha);
}
