// Reglas de la foto de perfil (F-22): tipo y tamaño. Puras, sin Flutter.

/// Lo máximo que puede pesar una foto: 2 MB.
const int tamanoMaximoFoto = 2 * 1024 * 1024;

const String mensajeFotoTipo = 'La foto debe ser JPG o PNG.';
const String mensajeFotoPesada = 'La foto pesa más de 2 MB.';
const String mensajeFotoVacia = 'La foto está vacía.';

/// La extensión normalizada de la foto (`jpg` o `png`), o `null` si no es de
/// un tipo aceptado. Mira primero el nombre y, si no sirve, el tipo MIME.
String? extensionDeFoto(String nombre, {String? tipoMime}) {
  final punto = nombre.lastIndexOf('.');
  if (punto != -1) {
    return _normalizar(nombre.substring(punto + 1));
  }
  return tipoMime == null ? null : _normalizar(tipoMime.split('/').last);
}

String? _normalizar(String texto) {
  return switch (texto.toLowerCase()) {
    'jpg' || 'jpeg' => 'jpg',
    'png' => 'png',
    _ => null,
  };
}

/// El mensaje de rechazo, o `null` si la foto se puede guardar.
String? validarFoto({
  required String nombre,
  required int bytes,
  String? tipoMime,
}) {
  if (extensionDeFoto(nombre, tipoMime: tipoMime) == null) {
    return mensajeFotoTipo;
  }
  if (bytes == 0) return mensajeFotoVacia;
  if (bytes > tamanoMaximoFoto) return mensajeFotoPesada;
  return null;
}

const String mensajeFotoNoElegida = 'No se pudo abrir el selector de fotos.';
const String mensajeFotoNoGuardada =
    'No se pudo guardar su foto. Inténtelo de nuevo.';
