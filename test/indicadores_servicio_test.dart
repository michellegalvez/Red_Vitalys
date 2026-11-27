import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/pages/registrar_medicion_page.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';

import 'ayudas.dart';

class FakeIndicators implements IndicatorService {
  var failsLoading = false;
  var duplicate = false;
  var loads = 0;
  final saved = <(Medicion, String)>[];

  @override
  bool get isRemote => true;

  @override
  Future<List<Medicion>> listMeasurements() async {
    loads++;
    if (failsLoading) throw StateError('sin red');
    return DatosSimulados.porDefecto.mediciones;
  }

  @override
  Future<void> addMeasurement(
    Medicion measurement, {
    required String siteName,
  }) async {
    if (duplicate) throw const DuplicateMeasurement();
    saved.add((measurement, siteName));
  }
}

class FakeAuth implements AuthService {
  var signIns = 0;

  @override
  bool get isRemote => true;

  @override
  Future<SignInResult> signIn(String email, String password) async {
    signIns++;
    return SignInResult(
      SignInStatus.success,
      DatosSimulados.porDefecto.usuarios[1],
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Usuario> reloadProfile(Usuario current) async => current;
}

Future<void> _enterAsAdmin(
  WidgetTester t,
  FakeIndicators indicators, {
  AuthService? auth,
}) async {
  final datos = DatosSimulados.porDefecto;
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: datos,
        auth: auth,
        indicators: indicators,
        reloj: () => datos.hoy,
      ),
    ),
  );
  await entrarSedeUnica(t, 'Administrativo');
}

Future<void> _choose<T>(WidgetTester t, String option) async {
  await tocarAyuda(t, find.byType(DropdownButtonFormField<T>));
  await tocarAyuda(t, find.text(option).last);
}

Future<void> _register(WidgetTester t) async {
  await tocarAyuda(t, find.text('Mediciones'));
  await _choose<IdIndicador>(t, 'Eventos adversos evitables');
  await _choose<String>(t, 'Centro Ambulatorio Envigado');
  await t.enterText(find.byType(TextField).first, '1,6');
  await t.pump();
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Registrar medición'));
}

void main() {
  group('Tablero desde el servicio (T-23 · F-08)', () {
    testWidgets('el ingreso pasa por el servicio de autenticación', (t) async {
      final indicators = FakeIndicators();
      final auth = FakeAuth();
      await _enterAsAdmin(t, indicators, auth: auth);
      expect(auth.signIns, 1);
      expect(indicators.loads, 1);
      await cerrarAppAyuda(t);
    });

    testWidgets('carga las mediciones al abrir la sesión', (t) async {
      final indicators = FakeIndicators();
      await _enterAsAdmin(t, indicators);
      expect(indicators.loads, 1);
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      expect(find.text('Reingreso hospitalario a 30 días'), findsWidgets);
      await cerrarAppAyuda(t);
    });

    testWidgets('si falla avisa y Reintentar la carga', (t) async {
      final indicators = FakeIndicators()..failsLoading = true;
      await _enterAsAdmin(t, indicators);
      expect(find.text('No se pudo cargar el tablero'), findsOneWidget);

      indicators.failsLoading = false;
      await tocarAyuda(t, find.text('Reintentar'));
      expect(indicators.loads, 2);
      expect(find.text('No se pudo cargar el tablero'), findsNothing);
      expect(find.text('Dónde actuar primero'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('Registrar una medición en el servicio (T-24 · F-12)', () {
    testWidgets('se guarda con su sede y entra a la sesión', (t) async {
      final indicators = FakeIndicators();
      await _enterAsAdmin(t, indicators);
      await _register(t);
      final (measurement, site) = indicators.saved.single;
      expect(measurement.indicador, IdIndicador.eventos);
      expect(measurement.valor, 1.6);
      expect(site, 'Centro Ambulatorio Envigado');
      expect(find.text(mensajeMedicionRegistrada), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('si la base ya la tiene, avisa que está repetida', (t) async {
      final indicators = FakeIndicators()..duplicate = true;
      await _enterAsAdmin(t, indicators);
      await _register(t);
      expect(indicators.saved, isEmpty);
      expect(find.text(mensajeMedicionRepetida), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });
}
