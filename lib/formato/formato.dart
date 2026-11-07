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
