import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/auth_memory.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

class FakeAuth implements AuthService {
  FakeAuth(this.results);

  final List<SignInResult> results;
  final calls = <String>[];
  var signOuts = 0;

  @override
  bool get isRemote => true;

  @override
  Future<SignInResult> signIn(String email, String password) async {
    calls.add('$email|$password');
    final index = calls.length - 1;
    return results[index < results.length ? index : results.length - 1];
  }

  @override
  Future<void> signOut() async => signOuts++;

  @override
  Future<Usuario> reloadProfile(Usuario current) async => current;
}

final _datos = DatosSimulados.porDefecto;
Usuario _user(String email) => _datos.usuarioPorCorreo(email)!;

Future<void> _open(WidgetTester t, AuthService auth) async {
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: _datos, auth: auth, reloj: () => _datos.hoy),
    ),
  );
}

Future<void> _signIn(WidgetTester t, String email, String password) async {
  await escribirAyuda(t, email, password);
  await tocarAyuda(t, find.text('Ingresar'));
}

String _text(WidgetTester t, int field) =>
    t.widget<TextField>(find.byType(TextField).at(field)).controller!.text;

void main() {
  group('AuthMemory (T-03 · F-13 CA-1 a CA-5)', () {
    final auth = AuthMemory(_datos);

    test(
      'CA-1 y CA-3: la Dra. Camila entra y ve exactamente sus 2 sedes',
      () async {
        final r = await auth.signIn('camila.martinez@vitalys.co', claveAyuda);
        expect(r.status, SignInStatus.success);
        expect(r.user!.sedesAsignadas.length, 2);
        expect(r.user!.rol, Rol.medico);
      },
    );

    test('CA-2: un usuario de una sola sede entra con esa sede', () async {
      final r = await auth.signIn('andres.ruiz@vitalys.co', claveAyuda);
      expect(r.status, SignInStatus.success);
      expect(r.user!.sedesAsignadas.length, 1);
    });

    test('CA-4: un correo que existe con la contraseña equivocada', () async {
      final r = await auth.signIn('camila.martinez@vitalys.co', 'equivocada');
      expect(r.status, SignInStatus.wrongCredentials);
      expect(r.user, isNull);
    });

    test('CA-5: un correo que no existe da el mismo resultado', () async {
      final r = await auth.signIn('nadie@vitalys.co', claveAyuda);
      expect(r.status, SignInStatus.wrongCredentials);
    });

    test('una cuenta con las credenciales correctas y sin sedes', () async {
      final r = await auth.signIn('tomas.herrera@vitalys.co', claveAyuda);
      expect(r.status, SignInStatus.noSites);
    });

    test('el correo se recorta antes de buscarlo', () async {
      final r = await auth.signIn('  andres.ruiz@vitalys.co ', claveAyuda);
      expect(r.status, SignInStatus.success);
    });

    test(
      'CA-11: un usuario por rol con sede, uno con 2 sedes y uno sin sedes',
      () {
        for (final rol in Rol.values) {
          final deRol = _datos.usuarios.where((u) => u.rol == rol);
          expect(deRol.any((u) => u.sedesAsignadas.isNotEmpty), isTrue);
        }
        expect(
          _datos.usuarios.any((u) => u.sedesAsignadas.length == 2),
          isTrue,
        );
        expect(_datos.usuarios.any((u) => u.sedesAsignadas.isEmpty), isTrue);
      },
    );
  });

  group('La Screen con el servicio (T-03 a T-06 · F-13)', () {
    testWidgets('T-06 CA-8: con el correo vacío no se llama al servicio', (
      t,
    ) async {
      final auth = FakeAuth([
        const SignInResult(SignInStatus.wrongCredentials),
      ]);
      await _open(t, auth);
      await _signIn(t, '', claveAyuda);
      expect(find.text(mensajeCamposVacios), findsOneWidget);
      expect(auth.calls, isEmpty);
      await cerrarAppAyuda(t);
    });

    testWidgets(
      'T-03 CA-4 y CA-5: datos incorrectos muestran el mismo mensaje',
      (t) async {
        final auth = FakeAuth([
          const SignInResult(SignInStatus.wrongCredentials),
        ]);
        await _open(t, auth);
        await _signIn(t, 'nadie@vitalys.co', 'x');
        expect(find.text(mensajeDatosIncorrectos), findsOneWidget);
        expect(auth.calls.single, 'nadie@vitalys.co|x');
        await cerrarAppAyuda(t);
      },
    );

    testWidgets('T-03 CA-9: sin red se avisa y el correo sigue escrito', (
      t,
    ) async {
      final auth = FakeAuth([const SignInResult(SignInStatus.networkError)]);
      await _open(t, auth);
      await _signIn(t, 'camila.martinez@vitalys.co', claveAyuda);
      expect(
        find.text('No se pudo iniciar sesión. Intente de nuevo.'),
        findsOneWidget,
      );
      expect(_text(t, 0), 'camila.martinez@vitalys.co');
      expect(_text(t, 1), isEmpty);
      await cerrarAppAyuda(t);
    });

    testWidgets('T-05 CA-7: una cuenta sin sedes ve su mensaje y no entra', (
      t,
    ) async {
      final auth = FakeAuth([const SignInResult(SignInStatus.noSites)]);
      await _open(t, auth);
      await _signIn(t, 'tomas.herrera@vitalys.co', claveAyuda);
      expect(find.text(mensajeSinSedes), findsOneWidget);
      expect(find.text('Confirmar sede'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('T-03 CA-1 y T-04 CA-12: valida, elige la sede y entra', (
      t,
    ) async {
      final camila = _user('camila.martinez@vitalys.co');
      final auth = FakeAuth([SignInResult(SignInStatus.success, camila)]);
      await _open(t, auth);
      await _signIn(t, camila.correo, claveAyuda);
      expect(find.text('Confirmar sede'), findsOneWidget);
      await tocarAyuda(t, find.byType(DropdownButtonFormField<String>));
      await tocarAyuda(t, find.text('Clínica Vitalys Cali Norte').last);
      await tocarAyuda(t, find.text('Confirmar sede'));
      expect(find.text('Seguimiento de reingreso'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets(
      'T-04 CA-13: salir sin confirmar la sede cierra la sesión de Auth',
      (t) async {
        final admin = _user('andres.ruiz@vitalys.co');
        final auth = FakeAuth([SignInResult(SignInStatus.success, admin)]);
        await _open(t, auth);
        await _signIn(t, admin.correo, claveAyuda);
        await tocarAyuda(t, find.text('Volver'));
        expect(auth.signOuts, 1);
        expect(find.text('Confirmar sede'), findsNothing);
        expect(find.text('Ingresar'), findsOneWidget);
        await cerrarAppAyuda(t);
      },
    );

    testWidgets(
      'T-04 CA-10: al cerrar la sesión también se cierra la de Auth',
      (t) async {
        final admin = _user('andres.ruiz@vitalys.co');
        final auth = FakeAuth([SignInResult(SignInStatus.success, admin)]);
        await _open(t, auth);
        await _signIn(t, admin.correo, claveAyuda);
        await tocarAyuda(t, find.text('Confirmar sede'));
        await cerrarSesionDelMenu(t);
        expect(auth.signOuts, 1);
        await cerrarAppAyuda(t);
      },
    );
  });
}
