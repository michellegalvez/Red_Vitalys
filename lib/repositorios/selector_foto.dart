import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Una foto que eligió el usuario en su dispositivo.
typedef FotoElegida = ({String nombre, String? tipoMime, Uint8List bytes});

/// Abre el selector de imágenes del dispositivo (galería o archivos).
abstract class SelectorFoto {
  /// La foto elegida, o `null` si el usuario cancela.
  Future<FotoElegida?> elegir();
}

/// El selector real, con `image_picker` (web y Android).
class SelectorFotoDispositivo implements SelectorFoto {
  final _selector = ImagePicker();

  @override
  Future<FotoElegida?> elegir() async {
    final archivo = await _selector.pickImage(source: ImageSource.gallery);
    if (archivo == null) return null;
    return (
      nombre: archivo.name,
      tipoMime: archivo.mimeType,
      bytes: await archivo.readAsBytes(),
    );
  }
}
