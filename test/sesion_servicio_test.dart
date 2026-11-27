import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:red_vitalys/services/session_service.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

class FailingSignOutAuth implements AuthService {
  FailingSignOutAuth(this.result);

  final SignInResult result;
  var signOutCalls = 0;

  @override
  bool get isRemote => true;

  @override
  Stream<void> get sessionEnded => const Stream.empty();

  @override
  Future<SignInResult> signIn(String email, String password) async => result;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    throw StateError('sin red');
  }

  @override
  Future<Usuario> reloadProfile(Usuario current) async => current;
}

final _now = DateTime(2026, 11, 6, 10, 42);

void main() {
  group('SessionService · bloqueo (T-07 · F-14)', () {
    test('CA-1: el quinto fallo seguido bloquea', () {
      final session = SessionService();
      for (var i = 1; i < intentosParaBloqueo; i++) {
        expect(session.registerFailure(_now), isFalse);
      }
      expect(session.registerFailure(_now), isTrue);
      expect(session.isLocked(_now), isTrue);
    });

    test('CA-2 y CA-3: sigue bloqueado hasta los 15 minutos y se libera', () {
      final session = SessionService();
      for (var i = 0; i < intentosParaBloqueo; i++) {
        session.registerFailure(_now);
      }
      final almost = _now.add(duracionBloqueo - const Duration(seconds: 1));
      expect(session.isLocked(almost), isTrue);
      expect(session.isLocked(_now.add(duracionBloqueo)), isFalse);
      expect(session.failures, 0);
    });

    test('CA-4: un ingreso exitoso reinicia el conteo', () {
      final session = SessionService();
      for (var i = 0; i < intentosParaBloqueo - 1; i++) {
        session.registerFailure(_now);
      }
      session.registerSuccess();
      expect(session.registerFailure(_now), isFalse);
      expect(session.failures, 1);
    });

    test('T-08 CA-8: un intento durante el bloqueo no lo alarga', () {
      final session = SessionService();
      for (var i = 0; i < intentosParaBloqueo; i++) {
        session.registerFailure(_now);
      }
      final later = _now.add(const Duration(minutes: 10));
      expect(session.registerFailure(later), isTrue);
      expect(session.isLocked(_now.add(duracionBloqueo)), isFalse);
    });
  });

  group('SessionService · inactividad (T-09 · F-15)', () {
    testWidgets('CA-1: cierra a los 15 minutos sin actividad', (t) async {
      var closed = 0;
      SessionService().startInactivityTimer(() => closed++);
      await t.pump(limiteInactividad - const Duration(seconds: 1));
      expect(closed, 0);
      await t.pump(const Duration(seconds: 1));
      expect(closed, 1);
    });

    testWidgets('CA-2: cualquier actividad reinicia el tiempo', (t) async {
      var closed = 0;
      final session = SessionService()..startInactivityTimer(() => closed++);
      await t.pump(const Duration(minutes: 14));
      session.registerActivity();
      await t.pump(const Duration(minutes: 14));
      expect(closed, 0);
      await t.pump(const Duration(minutes: 1));
      expect(closed, 1);
    });

    testWidgets('sin sesión la actividad no arranca el temporizador', (
      t,
    ) async {
      var closed = 0;
      final session = SessionService()..startInactivityTimer(() => closed++);
      session.stop();
      session.registerActivity();
      await t.pump(limiteInactividad * 2);
      expect(closed, 0);
    });
  });

  testWidgets('T-10 CA-7: si falla el cierre en Auth, igual vuelve al acceso', (
    t,
  ) async {
    final datos = DatosSimulados.porDefecto;
    final andres = datos.usuarioPorCorreo('andres.ruiz@vitalys.co')!;
    final auth = FailingSignOutAuth(SignInResult(SignInStatus.success, andres));
    t.view.physicalSize = celularAyuda;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: temaRedVitalys(),
        home: AppScreen(datos: datos, auth: auth, reloj: () => datos.hoy),
      ),
    );
    await escribirAyuda(t, andres.correo, claveAyuda);
    await tocarAyuda(t, find.text('Ingresar'));
    await tocarAyuda(t, find.text('Confirmar sede'));
    expect(find.text('Ingresar'), findsNothing);

    await t.pump(limiteInactividad);
    await t.pumpAndSettle();
    expect(auth.signOutCalls, 1);
    expect(find.text(mensajeInactividad), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Tablero de indicadores'), findsNothing);
    await cerrarAppAyuda(t);
  });
}
