import 'dart:typed_data';

/// Dónde vive la foto de perfil del usuario con sesión (F-22).
///
/// Una sola foto por usuario: subir otra reemplaza la anterior.
abstract class FotoPerfilRepositorio {
  /// `true` si la foto se guarda en Supabase Storage.
  bool get esRemoto;

  /// Los bytes de la foto, o `null` si el usuario no tiene.
  Future<Uint8List?> descargar();

  /// Guarda [bytes] como la foto del usuario. [extension] es `jpg` o `png`.
  Future<void> subir({required Uint8List bytes, required String extension});

  /// Quita la foto del usuario.
  Future<void> quitar();
}
