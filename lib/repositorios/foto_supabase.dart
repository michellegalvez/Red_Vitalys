import 'dart:typed_data';

import 'package:red_vitalys/repositorios/foto_repositorio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Nombre del bucket de Storage donde van las fotos (privado).
const String bucketFotos = 'fotos-perfil';

/// La ruta de la foto de un usuario dentro del bucket: `<id>/foto.<ext>`.
/// La política de Storage exige que la primera carpeta sea el id del usuario.
String rutaDeFoto(String idUsuario, String extension) =>
    '$idUsuario/foto.$extension';

/// La foto en Supabase Storage. La ruta queda en `usuario.foto_ruta`.
class FotoSupabase implements FotoPerfilRepositorio {
  FotoSupabase(this.cliente);

  final SupabaseClient cliente;

  @override
  bool get esRemoto => true;

  String get _idUsuario {
    final id = cliente.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No hay sesión de Supabase para usar la foto');
    }
    return id;
  }

  Future<String?> _rutaActual(String idUsuario) async {
    final fila = await cliente
        .from('usuario')
        .select('foto_ruta')
        .eq('id_usuario', idUsuario)
        .maybeSingle();
    return fila?['foto_ruta'] as String?;
  }

  Future<void> _guardarRuta(String idUsuario, String? ruta) {
    return cliente
        .from('usuario')
        .update({'foto_ruta': ruta})
        .eq('id_usuario', idUsuario);
  }

  @override
  Future<Uint8List?> descargar() async {
    final ruta = await _rutaActual(_idUsuario);
    if (ruta == null) return null;
    return cliente.storage.from(bucketFotos).download(ruta);
  }

  @override
  Future<void> subir({
    required Uint8List bytes,
    required String extension,
  }) async {
    final id = _idUsuario;
    final anterior = await _rutaActual(id);
    final ruta = rutaDeFoto(id, extension);
    final bucket = cliente.storage.from(bucketFotos);
    await bucket.uploadBinary(
      ruta,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
      ),
    );
    await _guardarRuta(id, ruta);
    // Si cambió de JPG a PNG (o al revés), no queda la foto vieja suelta.
    if (anterior != null && anterior != ruta) {
      await bucket.remove([anterior]);
    }
  }

  @override
  Future<void> quitar() async {
    final id = _idUsuario;
    final ruta = await _rutaActual(id);
    if (ruta == null) return;
    await cliente.storage.from(bucketFotos).remove([ruta]);
    await _guardarRuta(id, null);
  }
}
