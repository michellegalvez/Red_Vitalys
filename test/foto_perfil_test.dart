import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/fuente_de_datos.dart';
import 'package:red_vitalys/reglas/foto.dart';
import 'package:red_vitalys/repositorios/foto_memoria.dart';
import 'package:red_vitalys/repositorios/foto_repositorio.dart';
import 'package:red_vitalys/repositorios/foto_supabase.dart';
import 'package:red_vitalys/repositorios/selector_foto.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

/// Un PNG de 1×1 válido, para que `Image.memory` lo pueda pintar.
final Uint8List _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _SelectorFalso implements SelectorFoto {
  _SelectorFalso(this.foto);

  FotoElegida? foto;

  @override
  Future<FotoElegida?> elegir() async => foto;
}

class _FotoQueFalla extends FotoMemoria {
  @override
  Future<void> subir({required Uint8List bytes, required String extension}) {
    throw StateError('sin red');
  }
}

void main() {
  group('reglas de la foto (F-22)', () {
    test('acepta JPG, JPEG y PNG, sin importar las mayúsculas', () {
      for (final nombre in ['a.jpg', 'a.JPEG', 'a.png', 'mi foto.PNG']) {
        expect(
          validarFoto(nombre: nombre, bytes: 1000),
          isNull,
          reason: nombre,
        );
      }
    });

    test('rechaza otros tipos', () {
      for (final nombre in ['a.gif', 'a.pdf', 'a.webp', 'a']) {
        expect(
          validarFoto(nombre: nombre, bytes: 1000),
          mensajeFotoTipo,
          reason: nombre,
        );
      }
    });

    test('sin extensión en el nombre mira el tipo MIME', () {
      expect(
        validarFoto(nombre: 'blob', bytes: 10, tipoMime: 'image/png'),
        isNull,
      );
      expect(
        validarFoto(nombre: 'blob', bytes: 10, tipoMime: 'image/gif'),
        mensajeFotoTipo,
      );
    });

    test('2 MB justos se aceptan; un byte más se rechaza', () {
      expect(validarFoto(nombre: 'a.png', bytes: tamanoMaximoFoto), isNull);
      expect(
        validarFoto(nombre: 'a.png', bytes: tamanoMaximoFoto + 1),
        mensajeFotoPesada,
      );
    });

    test('una foto vacía se rechaza', () {
      expect(validarFoto(nombre: 'a.png', bytes: 0), mensajeFotoVacia);
    });

    test('jpeg y jpg dan la misma extensión', () {
      expect(extensionDeFoto('a.jpeg'), 'jpg');
      expect(extensionDeFoto('a.JPG'), 'jpg');
      expect(extensionDeFoto('a.png'), 'png');
    });
  });

  group('repositorio de fotos', () {
    test('en memoria: subir, descargar y quitar', () async {
      final repo = FotoMemoria();
      expect(repo.esRemoto, isFalse);
      expect(await repo.descargar(), isNull);
      await repo.subir(bytes: _png, extension: 'png');
      expect(await repo.descargar(), _png);
      await repo.quitar();
      expect(await repo.descargar(), isNull);
    });

    test('la ruta es <id_usuario>/foto.<ext>', () {
      expect(rutaDeFoto('abc-123', 'png'), 'abc-123/foto.png');
    });

    test('sin Supabase la fuente de fotos es la de memoria', () {
      expect(elegirFotos(), isNull);
    });
  });

  group('perfil con foto', () {
    Future<void> abrirPerfilConFoto(
      WidgetTester t, {
      required FotoPerfilRepositorio fotos,
      required SelectorFoto selector,
    }) async {
      t.view.physicalSize = celularAyuda;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: temaRedVitalys(),
          home: AppScreen(
            datos: DatosSimulados.porDefecto,
            reloj: () => DatosSimulados.porDefecto.hoy,
            fotos: fotos,
            selectorFoto: selector,
          ),
        ),
      );
      await entrarSedeUnica(t, 'Auditor');
      await tocarAyuda(t, find.byTooltip('Menú de usuario'));
      await tocarAyuda(t, find.text('Mi perfil'));
    }

    testWidgets('sin foto ofrece subirla; al subirla la muestra', (t) async {
      final fotos = FotoMemoria();
      await abrirPerfilConFoto(
        t,
        fotos: fotos,
        selector: _SelectorFalso((
          nombre: 'yo.png',
          tipoMime: null,
          bytes: _png,
        )),
      );
      expect(find.text('Subir foto'), findsOneWidget);
      expect(find.text('Quitar foto'), findsNothing);

      await tocarAyuda(t, find.text('Subir foto'));
      expect(await fotos.descargar(), _png);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Cambiar foto'), findsOneWidget);
      expect(find.text('Quitar foto'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('con foto guardada la trae al abrir el perfil', (t) async {
      final fotos = FotoMemoria();
      await fotos.subir(bytes: _png, extension: 'png');
      await abrirPerfilConFoto(t, fotos: fotos, selector: _SelectorFalso(null));
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Cambiar foto'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('quitar la foto la borra', (t) async {
      final fotos = FotoMemoria();
      await fotos.subir(bytes: _png, extension: 'png');
      await abrirPerfilConFoto(t, fotos: fotos, selector: _SelectorFalso(null));
      await tocarAyuda(t, find.text('Quitar foto'));
      expect(await fotos.descargar(), isNull);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Subir foto'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('un tipo no aceptado se rechaza y no se guarda', (t) async {
      final fotos = FotoMemoria();
      await abrirPerfilConFoto(
        t,
        fotos: fotos,
        selector: _SelectorFalso((
          nombre: 'a.gif',
          tipoMime: null,
          bytes: _png,
        )),
      );
      await tocarAyuda(t, find.text('Subir foto'));
      expect(find.text(mensajeFotoTipo), findsOneWidget);
      expect(await fotos.descargar(), isNull);
      await cerrarAppAyuda(t);
    });

    testWidgets('una foto de más de 2 MB se rechaza', (t) async {
      final fotos = FotoMemoria();
      await abrirPerfilConFoto(
        t,
        fotos: fotos,
        selector: _SelectorFalso((
          nombre: 'grande.png',
          tipoMime: null,
          bytes: Uint8List(tamanoMaximoFoto + 1),
        )),
      );
      await tocarAyuda(t, find.text('Subir foto'));
      expect(find.text(mensajeFotoPesada), findsOneWidget);
      expect(await fotos.descargar(), isNull);
      await cerrarAppAyuda(t);
    });

    testWidgets('si falla el guardado avisa y no cambia la foto', (t) async {
      await abrirPerfilConFoto(
        t,
        fotos: _FotoQueFalla(),
        selector: _SelectorFalso((
          nombre: 'yo.png',
          tipoMime: null,
          bytes: _png,
        )),
      );
      await tocarAyuda(t, find.text('Subir foto'));
      expect(find.text(mensajeFotoNoGuardada), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Subir foto'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('cancelar el selector no cambia nada', (t) async {
      final fotos = FotoMemoria();
      await abrirPerfilConFoto(t, fotos: fotos, selector: _SelectorFalso(null));
      await tocarAyuda(t, find.text('Subir foto'));
      expect(find.text('Subir foto'), findsOneWidget);
      expect(find.text(mensajeFotoNoGuardada), findsNothing);
      await cerrarAppAyuda(t);
    });
  });
}
