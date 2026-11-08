/// Enmascarado de documentos e identificadores (F-02): se ven completos solo
/// cuando el médico elige *Mostrar documentos*.
library;

const String _puntos = '···';

/// "CC ··· 7654": el tipo y los últimos 4 dígitos del documento.
String documentoEnmascarado(String tipo, String numero) =>
    '$tipo $_puntos ${_finales(numero)}';

/// "HCE-···7654": conserva el prefijo del sistema y los últimos 4
/// caracteres del identificador.
String identificadorEnmascarado(String identificador) {
  final guion = identificador.indexOf('-');
  final prefijo = guion < 0 ? '' : identificador.substring(0, guion + 1);
  return '$prefijo$_puntos${_finales(identificador)}';
}

String _finales(String texto) =>
    texto.length <= 4 ? texto : texto.substring(texto.length - 4);
