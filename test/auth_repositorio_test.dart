import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auth_memoria.dart';
import 'package:red_vitalys/repositorios/auth_repositorio.dart';

void main() {
  group('AuthMemoria (P-03)', () {
    late DatosSimulados datos;
    late AuthMemoria auth;

    setUp(() {
      datos = DatosSimulados.porDefecto;
      auth = AuthMemoria(datos);
    });

    test(
      'iniciar sesión con credenciales válidas devuelve AuthExito y sus sedes',
      () async {
        final res = await auth.iniciarSesion(
          correo: 'camila.martinez@vitalys.co',
          contrasena: datos.contrasenaPrototipo,
        );

        expect(res, isA<AuthExito>());
        final exito = res as AuthExito;
        expect(exito.usuario.nombre, 'Dra. Camila Martínez');
        expect(exito.usuario.rol, Rol.medico);
        expect(exito.sedes.length, 2);
        expect(auth.usuarioActual, isNotNull);
        expect(auth.usuarioActual?.correo, 'camila.martinez@vitalys.co');
      },
    );

    test(
      'iniciar sesión con contraseña incorrecta devuelve AuthErrorCredenciales',
      () async {
        final res = await auth.iniciarSesion(
          correo: 'camila.martinez@vitalys.co',
          contrasena: 'clave_invalida',
        );

        expect(res, isA<AuthErrorCredenciales>());
        expect(auth.usuarioActual, isNull);
      },
    );

    test(
      'iniciar sesión con usuario inexistente devuelve AuthErrorCredenciales',
      () async {
        final res = await auth.iniciarSesion(
          correo: 'inexistente@vitalys.co',
          contrasena: datos.contrasenaPrototipo,
        );

        expect(res, isA<AuthErrorCredenciales>());
        expect(auth.usuarioActual, isNull);
      },
    );

    test(
      'usuario sin sedes asignadas devuelve AuthExito con lista de sedes vacía',
      () async {
        // Dr. Tomás Herrera no tiene sedes asignadas (F-13 A3)
        final res = await auth.iniciarSesion(
          correo: 'tomas.herrera@vitalys.co',
          contrasena: datos.contrasenaPrototipo,
        );

        expect(res, isA<AuthExito>());
        final exito = res as AuthExito;
        expect(exito.usuario.sedesAsignadas, isEmpty);
        expect(exito.sedes, isEmpty);
      },
    );

    test('cerrar sesión limpia el usuario actual', () async {
      await auth.iniciarSesion(
        correo: 'camila.martinez@vitalys.co',
        contrasena: datos.contrasenaPrototipo,
      );
      expect(auth.usuarioActual, isNotNull);

      await auth.cerrarSesion();
      expect(auth.usuarioActual, isNull);
    });
  });
}
