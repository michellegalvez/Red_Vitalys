import 'dart:typed_data';

import 'package:red_vitalys/repositorios/foto_repositorio.dart';

/// La foto en memoria: sirve sin Supabase y en las pruebas. Se pierde al
/// cerrar la app.
class FotoMemoria implements FotoPerfilRepositorio {
  Uint8List? _foto;

  @override
  bool get esRemoto => false;

  @override
  Future<Uint8List?> descargar() async => _foto;

  @override
  Future<void> subir({
    required Uint8List bytes,
    required String extension,
  }) async => _foto = bytes;

  @override
  Future<void> quitar() async => _foto = null;
}
