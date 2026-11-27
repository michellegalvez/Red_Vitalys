import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/repositorios/selector_foto.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

// Lo que quedaba de la revisión del 26 nov: la auditoría se trae también al
// llegar desde el perfil, la foto en memoria es de cada usuario y el
// formulario de mediciones espera las de la base.

final _datos = DatosSimulados.porDefecto;

final _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class CountingAudit implements AuditoriaRepositorio {
  final saved = <EventoAuditoria>[];
  var lists = 0;

  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async => saved.add(evento);

  @override
  Future<List<EventoAuditoria>> listar() async {
    lists++;
    return saved.reversed.toList();
  }
}

class OnePhoto implements SelectorFoto {
  @override
  Future<FotoElegida?> elegir() async =>
      (nombre: 'foto.png', tipoMime: 'image/png', bytes: _png);
}

class SlowIndicators implements IndicatorService {
  final loads = <Completer<List<Medicion>>>[];

  @override
  bool get isRemote => true;

  @override
  Future<List<Medicion>> listMeasurements() {
    final load = Completer<List<Medicion>>();
    loads.add(load);
    return load.future;
  }

  @override
  Future<void> addMeasurement(
    Medicion measurement, {
    required String siteName,
  }) async {}
}

Future<void> _open(
  WidgetTester t, {
  AuditoriaRepositorio? audit,
  IndicatorService? indicators,
  SelectorFoto? selector,
}) async {
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: _datos,
        auditoria: audit,
        indicators: indicators,
        selectorFoto: selector,
        reloj: () => _datos.hoy,
      ),
    ),
  );
}

Future<void> _profile(WidgetTester t) async {
  await tocarAyuda(t, find.byTooltip('Menú de usuario'));
  await tocarAyuda(t, find.text('Mi perfil'));
}

Future<void> _signOut(WidgetTester t) async {
  await tocarAyuda(t, find.text('Cerrar sesión').last);
  expect(find.text('Ingresar'), findsOneWidget);
}

void main() {
  testWidgets('F-21 CA-1: al volver a la auditoría desde el perfil se trae '
      'de nuevo', (t) async {
    final audit = CountingAudit();
    await _open(t, audit: audit);
    await entrarSedeUnica(t, 'Auditor');
    final before = audit.lists;
    await _profile(t);
    await tocarAyuda(t, find.text('Auditoría').last);
    expect(find.text('Auditoría de accesos'), findsOneWidget);
    expect(audit.lists, before + 1);
    await cerrarAppAyuda(t);
  });

  testWidgets('F-22 CA-12 y CA-17: en memoria la foto de un usuario no la ve '
      'el siguiente', (t) async {
    await _open(t, selector: OnePhoto());
    await entrarSedeUnica(t, 'Auditor');
    await _profile(t);
    await tocarAyuda(t, find.text('Subir foto'));
    expect(find.text('Quitar foto'), findsOneWidget);
    await _signOut(t);

    await entrarSedeUnica(t, 'Administrativo');
    await _profile(t);
    expect(find.text('Subir foto'), findsOneWidget);
    expect(find.text('Quitar foto'), findsNothing);
    await _signOut(t);

    await entrarSedeUnica(t, 'Auditor');
    await _profile(t);
    expect(find.text('Quitar foto'), findsOneWidget);
    await cerrarAppAyuda(t);
  });

  testWidgets('F-12: el formulario espera las mediciones de la base y, si '
      'fallan, ofrece Reintentar', (t) async {
    final indicators = SlowIndicators();
    await _open(t, indicators: indicators);
    await tocarAyuda(t, find.text('Administrativo'));
    await tocarAyuda(t, find.text('Ingresar'));
    await t.tap(find.text('Confirmar sede'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Mediciones'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Cargando mediciones…'), findsOneWidget);
    expect(find.text('Registrar medición'), findsNothing);

    indicators.loads.single.completeError(StateError('sin red'));
    await t.pumpAndSettle();
    expect(find.text('No se pudieron cargar las mediciones'), findsOneWidget);

    await t.tap(find.text('Reintentar'));
    await t.pump();
    indicators.loads.last.complete(_datos.mediciones);
    await t.pumpAndSettle();
    expect(find.text('Registrar medición'), findsOneWidget);
    await cerrarAppAyuda(t);
  });
}
