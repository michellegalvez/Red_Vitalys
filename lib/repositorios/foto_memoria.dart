import 'dart:typed_data';

import 'package:red_vitalys/repositorios/foto_repositorio.dart';

/// La foto en memoria: sirve sin Supabase y en las pruebas. Se pierde al
/// cerrar la app.
///
/// Con [dueno], cada usuario tiene su propia foto, como en Storage: la de uno
/// no la ve ni la cambia otro (F-22 CA-12, CA-17).
class FotoMemoria implements FotoPerfilRepositorio {
  FotoMemoria({String? Function()? dueno}) : _dueno = dueno ?? (() => null);

  final String? Function() _dueno;
  final Map<String?, Uint8List> _fotos = {};

  @override
  bool get esRemoto => false;

  @override
  Future<Uint8List?> descargar() async => _fotos[_dueno()];

  @override
  Future<void> subir({
    required Uint8List bytes,
    required String extension,
  }) async => _fotos[_dueno()] = bytes;

  @override
  Future<void> quitar() async => _fotos.remove(_dueno());
}
