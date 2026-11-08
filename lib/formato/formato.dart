/// Formato de fechas, horas y números en un solo lugar (AD-12, RNF-05).
library;

const List<String> _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _dosDigitos(int n) => n.toString().padLeft(2, '0');

/// "30 oct 2026".
String formatoFecha(DateTime f) => '${f.day} ${_meses[f.month - 1]} ${f.year}';

/// "30 oct 2026 · 09:47", con la hora en formato de 24 horas.
String formatoFechaHora(DateTime f) =>
    '${formatoFecha(f)} · ${_dosDigitos(f.hour)}:${_dosDigitos(f.minute)}';

/// "30/10/2026 10:42": la fecha y hora como se escriben en un formulario.
String formatoFechaHoraCampo(DateTime f) =>
    '${_dosDigitos(f.day)}/${_dosDigitos(f.month)}/${f.year} '
    '${_dosDigitos(f.hour)}:${_dosDigitos(f.minute)}';

/// Lee "30/10/2026 10:42". Devuelve `null` si no tiene esa forma o la fecha
/// no existe, por ejemplo "31/02/2026 10:00".
DateTime? leerFechaHoraCampo(String texto) {
  final m = RegExp(r'^\s*(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})\s*$')
      .firstMatch(texto);
  if (m == null) return null;
  final n = [for (var i = 1; i <= 5; i++) int.parse(m.group(i)!)];
  final f = DateTime(n[2], n[1], n[0], n[3], n[4]);
  final coincide =
      f.day == n[0] && f.month == n[1] && f.year == n[2] && f.hour == n[3];
  return coincide && n[4] < 60 ? f : null;
}

/// "15 d", o "Mismo día" cuando la estancia fue de 0 días.
String formatoEstancia(int dias) => dias == 0 ? 'Mismo día' : '$dias d';

/// "Buenos días", "Buenas tardes" o "Buenas noches" según la hora.
String saludoSegunHora(DateTime f) {
  if (f.hour < 12) return 'Buenos días';
  if (f.hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// Minúsculas y sin tildes, para buscar sin distinguirlas (F-01).
String normalizarTexto(String texto) {
  const conTilde = 'áéíóúüñÁÉÍÓÚÜÑ';
  const sinTilde = 'aeiouunAEIOUUN';
  final buffer = StringBuffer();
  for (final c in texto.split('')) {
    final i = conTilde.indexOf(c);
    buffer.write(i >= 0 ? sinTilde[i] : c);
  }
  return buffer.toString().toLowerCase().trim();
}
