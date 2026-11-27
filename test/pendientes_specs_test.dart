import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:red_vitalys/services/lock_store.dart';
import 'package:red_vitalys/services/relationship_service.dart';
import 'package:red_vitalys/services/session_service.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

// Lo que quedó pendiente al marcar las specs como implementadas: el bloqueo
// sobrevive a recargar (F-14), escribir cuenta como actividad (F-15), la
// relación la confirma la base (F-05 CA-8, F-18 CA-9) y el perfil y el cierre
// de sesión muestran sus errores reales (F-22 CA-8, F-23 CA-5).

final _datos = DatosSimulados.porDefecto;
final _now = _datos.hoy;
const _jorge = 'Jorge Eliécer Pardo Villamizar';
const _hernan = 'Hernán Darío Quintero Salcedo';

class AnsweredRelationship implements RelationshipService {
  bool? answer;
  var fails = false;
  var calls = 0;

  @override
  bool get isRemote => true;

  @override
  Future<bool> hasRelationship(
    Usuario doctor,
    PacienteEnSeguimiento patient,
    DateTime today,
  ) async {
    calls++;
    if (fails) throw StateError('sin red');
    return answer ?? tieneRelacion(doctor, patient, today);
  }
}

class RemoteAuth implements AuthService {
  var failsSignOut = false;
  var failsProfile = false;
  var signOuts = 0;

  @override
  bool get isRemote => true;

  @override
  Future<SignInResult> signIn(String email, String password) async {
    final user = _datos.usuarioPorCorreo(email.trim());
    if (user == null || password != _datos.contrasenaPrototipo) {
      return const SignInResult(SignInStatus.wrongCredentials);
    }
    return SignInResult(SignInStatus.success, user);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (failsSignOut) throw StateError('sin red');
  }

  @override
  Future<Usuario> reloadProfile(Usuario current) async {
    if (failsProfile) throw StateError('sin red');
    return current;
  }
}

Future<void> _open(
  WidgetTester t, {
  LockStore? lockStore,
  RelationshipService? relationships,
  AuthService? auth,
}) async {
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: _datos,
        lockStore: lockStore,
        relationships: relationships,
        auth: auth,
        reloj: () => _datos.hoy,
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _openPatient(WidgetTester t, String name, String purpose) async {
  await tocarAyuda(t, find.text('Ver todos →'));
  await tocarAyuda(t, find.text(name));
  await tocarAyuda(t, find.text(purpose));
  await tocarAyuda(t, find.text('Abrir historia clínica'));
}

Future<void> _profile(WidgetTester t) async {
  await tocarAyuda(t, find.byTooltip('Menú de usuario'));
  await tocarAyuda(t, find.text('Mi perfil'));
}

void main() {
  group('F-14 · el bloqueo sobrevive a recargar', () {
    test('lo que guarda el equipo lo lee la sesión siguiente', () async {
      final store = LockMemory();
      final first = SessionService(store: store);
      for (var i = 0; i < intentosParaBloqueo; i++) {
        first.registerFailure(_now);
      }
      await Future<void>.delayed(Duration.zero);

      final reloaded = SessionService(store: store);
      await reloaded.restore();
      expect(reloaded.isLocked(_now), isTrue);
      expect(reloaded.isLocked(_now.add(duracionBloqueo)), isFalse);
      await Future<void>.delayed(Duration.zero);

      final later = SessionService(store: store);
      await later.restore();
      expect(later.isLocked(_now), isFalse);
      expect(later.failures, 0);
    });

    test('los fallos sueltos no se guardan: no vencen en un bloqueo', () async {
      final store = LockMemory();
      final first = SessionService(store: store);
      for (var i = 1; i < intentosParaBloqueo; i++) {
        first.registerFailure(_now);
      }
      await Future<void>.delayed(Duration.zero);
      final reloaded = SessionService(store: store);
      await reloaded.restore();
      expect(reloaded.registerFailure(_now), isFalse);
      expect(reloaded.failures, 1);
    });

    test('leer el equipo tarde no pisa un bloqueo que empezó aquí', () async {
      final store = LockMemory();
      await store.write((failures: 5, lockedSince: _now));
      final session = SessionService(store: store);
      final later = _now.add(const Duration(minutes: 10));
      for (var i = 0; i < intentosParaBloqueo; i++) {
        session.registerFailure(later);
      }
      await session.restore();
      expect(session.isLocked(_now.add(duracionBloqueo)), isTrue);
    });

    testWidgets(
      'tras recargar la app, sigue bloqueada aun con la clave buena',
      (t) async {
        final store = LockMemory();
        await _open(t, lockStore: store);
        for (var i = 0; i < intentosParaBloqueo; i++) {
          await escribirAyuda(t, 'camila.martinez@vitalys.co', 'mala$i');
          await tocarAyuda(t, find.text('Ingresar'));
        }
        expect(find.text(mensajeBloqueo), findsOneWidget);
        await cerrarAppAyuda(t);

        await _open(t, lockStore: store);
        await escribirAyuda(t, 'camila.martinez@vitalys.co', claveAyuda);
        await tocarAyuda(t, find.text('Ingresar'));
        expect(find.text(mensajeBloqueo), findsOneWidget);
        expect(find.text('Confirmar sede'), findsNothing);
        await cerrarAppAyuda(t);
      },
    );
  });

  testWidgets('F-15 CA-2: escribir, también con el teclado en pantalla, '
      'cuenta como actividad', (t) async {
    await _open(t);
    await entrarMedica(t, proposito: 'Seguimiento de reingreso');
    await tocarAyuda(t, find.text('Buscar'));
    await t.pump(limiteInactividad - const Duration(minutes: 1));
    // enterText escribe como el teclado en pantalla: sin teclas ni toques.
    await t.enterText(find.byType(TextField).first, 'quintero');
    await t.pump(const Duration(minutes: 2));
    await t.pumpAndSettle();
    expect(find.text(mensajeInactividad), findsNothing);
    expect(find.text(_hernan), findsOneWidget);
    await cerrarAppAyuda(t);
  });

  group('F-05 CA-8 y F-18 CA-9 · la relación la confirma la base', () {
    testWidgets('si no responde se ve "No se pudo verificar el acceso" y '
        'Reintentar la vuelve a pedir', (t) async {
      final relationships = AnsweredRelationship()..fails = true;
      await _open(t, relationships: relationships);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      await _openPatient(t, _jorge, 'Atención del paciente');
      expect(find.text('No se pudo verificar el acceso'), findsOneWidget);
      expect(find.text('Registrar atención'), findsNothing);

      relationships.fails = false;
      await tocarAyuda(t, find.text('Reintentar'));
      expect(relationships.calls, 2);
      expect(find.text('No se pudo verificar el acceso'), findsNothing);
      expect(find.text('Registrar atención'), findsWidgets);
      await cerrarAppAyuda(t);
    });

    testWidgets('manda lo que dice la base, no los datos cargados', (t) async {
      final relationships = AnsweredRelationship()..answer = true;
      await _open(t, relationships: relationships);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      await _openPatient(t, _hernan, 'Atención del paciente');
      expect(find.text(rechazoRelacion), findsNothing);
      expect(find.text('Registrar atención'), findsWidgets);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();

      relationships.answer = false;
      await tocarAyuda(t, find.text(_jorge));
      await tocarAyuda(t, find.text('Atención del paciente'));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('con Urgencia no se pregunta: no necesita relación', (t) async {
      final relationships = AnsweredRelationship()..fails = true;
      await _open(t, relationships: relationships);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      await _openPatient(t, _hernan, 'Urgencia (acceso de emergencia)');
      expect(relationships.calls, 0);
      expect(find.text('No se pudo verificar el acceso'), findsNothing);
      await cerrarAppAyuda(t);
    });
  });

  testWidgets('F-22 CA-8: si el perfil no carga se ve el error, Reintentar y '
      'todavía se puede cerrar sesión', (t) async {
    final auth = RemoteAuth()..failsProfile = true;
    await _open(t, auth: auth);
    await entrarSedeUnica(t, 'Auditor');
    await _profile(t);
    expect(find.text('No se pudo cargar su perfil'), findsOneWidget);
    expect(find.text('Marcela Ospina'), findsNothing);

    auth.failsProfile = false;
    await tocarAyuda(t, find.text('Reintentar'));
    expect(find.text('No se pudo cargar su perfil'), findsNothing);
    expect(find.text('Marcela Ospina'), findsWidgets);

    auth.failsProfile = true;
    await tocarAyuda(t, find.byTooltip('Menú de usuario'));
    await tocarAyuda(t, find.text('Mi perfil'));
    await tocarAyuda(t, find.text('Cerrar sesión').last);
    expect(find.text('Ingresar'), findsOneWidget);
    await cerrarAppAyuda(t);
  });

  testWidgets('F-23 CA-5: si no se puede cerrar la sesión sigue en el perfil '
      'con el mensaje y al reintentar sale', (t) async {
    final auth = RemoteAuth()..failsSignOut = true;
    await _open(t, auth: auth);
    await entrarSedeUnica(t, 'Auditor');
    await _profile(t);
    await tocarAyuda(t, find.text('Cerrar sesión').last);
    expect(
      find.text('No se pudo cerrar la sesión. Intente de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Ingresar'), findsNothing);

    auth.failsSignOut = false;
    await tocarAyuda(t, find.text('Cerrar sesión').last);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(auth.signOuts, 2);
    await cerrarAppAyuda(t);
  });
}
