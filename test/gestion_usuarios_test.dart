import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:red_vitalys/pages/usuarios_page.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/pages/perfil_page.dart';
import 'package:red_vitalys/reglas/cuentas.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
import 'package:red_vitalys/services/account_service.dart';
import 'package:red_vitalys/services/auth_supabase.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ayudas.dart';

// F-24 · Registro de cuentas y gestión de usuarios por el director.

final _datos = DatosSimulados.porDefecto;
const _director = 'direccion@vitalys.co';
const _nueva = 'laura.rios@vitalys.co';

class SavedAudit implements AuditoriaRepositorio {
  final saved = <EventoAuditoria>[];
  var fails = false;

  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async {
    if (fails) throw StateError('sin red');
    saved.add(evento);
  }

  @override
  Future<List<EventoAuditoria>> listar() async => saved.reversed.toList();
}

class CountingPatients implements PatientService {
  var calls = 0;

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async {
    calls++;
    return const [];
  }
}

class CountingIndicators implements IndicatorService {
  var calls = 0;

  @override
  bool get isRemote => true;

  @override
  Future<List<Medicion>> listMeasurements() async {
    calls++;
    return const [];
  }

  @override
  Future<void> addMeasurement(
    Medicion measurement, {
    required String siteName,
  }) async {}
}

Future<SavedAudit> _open(WidgetTester t) async {
  final audit = SavedAudit();
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: _datos, auditoria: audit, reloj: () => _datos.hoy),
    ),
  );
  return audit;
}

Future<void> _signUp(
  WidgetTester t, {
  String name = 'Laura Ríos',
  String email = _nueva,
  String password = 'clave1234',
  String? repeated,
}) async {
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Crear cuenta'));
  final fields = find.byType(TextField);
  await t.enterText(fields.at(0), name);
  await t.enterText(fields.at(1), email);
  await t.enterText(fields.at(2), password);
  await t.enterText(fields.at(3), repeated ?? password);
  await t.pump();
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Crear cuenta').last);
}

Future<void> _signIn(WidgetTester t, String email) async {
  await escribirAyuda(t, email, claveAyuda);
  await tocarAyuda(t, find.text('Ingresar'));
}

Future<void> _enterAsDirector(WidgetTester t) async {
  await _signIn(t, _director);
  await tocarAyuda(t, find.text('Confirmar sede'));
}

Future<void> _signOut(WidgetTester t) async {
  await tocarAyuda(t, find.byTooltip('Menú de usuario'));
  await tocarAyuda(t, find.text('Cerrar sesión'));
}

Future<void> _approveAsDoctorInCaliNorte(WidgetTester t, String name) async {
  await tocarAyuda(t, find.text(name));
  await tocarAyuda(t, find.byType(DropdownButtonFormField<Rol>));
  await tocarAyuda(t, find.text('Médico').last);
  await tocarAyuda(
    t,
    find.widgetWithText(CheckboxListTile, 'Clínica Vitalys Cali Norte'),
  );
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Guardar'));
}

void main() {
  group('Crear una cuenta (RF-39)', () {
    testWidgets('CA-1 y CA-4: se crea, queda pendiente y no entra hasta que la '
        'aprueben', (t) async {
      await _open(t);
      await _signUp(t);
      expect(find.text(mensajeCuentaCreada), findsOneWidget);
      await tocarAyuda(t, find.text('Volver al acceso'));

      await _signIn(t, _nueva);
      expect(find.text(mensajeSinSedes), findsNothing);
      await escribirAyuda(t, _nueva, 'clave1234');
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text(mensajeSinSedes), findsOneWidget);
      expect(find.text('Confirmar sede'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-2: con un correo que ya tiene cuenta no se crea otra', (
      t,
    ) async {
      await _open(t);
      await _signUp(t, email: 'camila.martinez@vitalys.co');
      expect(find.text(mensajeCorreoTomado), findsOneWidget);
      expect(find.text(mensajeCuentaCreada), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-3: con 7 caracteres no se crea', (t) async {
      await _open(t);
      await _signUp(t, password: 'clave12');
      expect(find.text(mensajeClaveCorta), findsOneWidget);
      await tocarAyuda(t, find.text('Acceso  /  Crear cuenta'));
      await _signIn(t, _nueva);
      expect(find.text(mensajeDatosIncorrectos), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('El director gestiona las cuentas (RF-40)', () {
    testWidgets('CA-5 y CA-12: entra a Usuarios con las pendientes primero y '
        'su perfil solo permite gestionar usuarios', (t) async {
      await _open(t);
      await _signUp(t);
      await tocarAyuda(t, find.text('Volver al acceso'));
      await _enterAsDirector(t);
      expect(find.text('Usuarios'), findsWidgets);
      final names = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .whereType<String>()
          .where((n) => n == 'Laura Ríos' || n == 'Dra. Camila Martínez')
          .toList();
      expect(names, ['Laura Ríos', 'Dra. Camila Martínez']);
      expect(find.text('Pendiente'), findsWidgets);

      await tocarAyuda(t, find.byTooltip('Menú de usuario'));
      await tocarAyuda(t, find.text('Mi perfil'));
      final permisos = t.widget<PerfilPage>(find.byType(PerfilPage)).permisos;
      expect(
        [
          for (final p in permisos)
            if (p.permitido) p.accion,
        ],
        [
          AccionPermitida.gestionarUsuarios.nombre,
          AccionPermitida.verPerfil.nombre,
        ],
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-6: al aprobarla queda el evento y la persona entra desde '
        'Cali Norte', (t) async {
      final audit = await _open(t);
      await _signUp(t);
      await tocarAyuda(t, find.text('Volver al acceso'));
      await _enterAsDirector(t);
      await _approveAsDoctorInCaliNorte(t, 'Laura Ríos');
      final event = audit.saved.last;
      expect(event.recurso, RecursoAuditoria.usuario);
      expect(event.accion, AccionAuditoria.registrar);
      expect(event.resultado, ResultadoAuditoria.permitido);
      expect(event.cuentaAfectada, _nueva);
      expect(event.sedeId, 's1');
      await _signOut(t);

      await escribirAyuda(t, _nueva, 'clave1234');
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text('Clínica Vitalys Cali Norte'), findsWidgets);
      await tocarAyuda(t, find.text('Confirmar sede'));
      expect(find.text('Confirmar sede'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-7: una cuenta activa sin sedes no se guarda', (t) async {
      final audit = await _open(t);
      await _enterAsDirector(t);
      final before = audit.saved.length;
      await tocarAyuda(t, find.text('Andrés Felipe Ruiz'));
      await tocarAyuda(
        t,
        find.widgetWithText(CheckboxListTile, 'Clínica Vitalys Bogotá Usaquén'),
      );
      await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Guardar'));
      expect(find.text(mensajeAsigneSede), findsOneWidget);
      expect(audit.saved.length, before);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-8: no puede quitarse su rol ni desactivarse', (t) async {
      final audit = await _open(t);
      await _enterAsDirector(t);
      final before = audit.saved.length;
      await tocarAyuda(t, find.text('Patricia Londoño Vélez'));
      await tocarAyuda(t, find.text('Cuenta activa'));
      await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Guardar'));
      expect(find.text(mensajeCuentaPropia), findsOneWidget);
      expect(audit.saved.length, before);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-9: una cuenta desactivada no entra', (t) async {
      await _open(t);
      await _enterAsDirector(t);
      await tocarAyuda(t, find.text('Andrés Felipe Ruiz'));
      await tocarAyuda(t, find.text('Cuenta activa'));
      await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Guardar'));
      expect(find.text('Desactivada'), findsOneWidget);
      await _signOut(t);

      await _signIn(t, 'andres.ruiz@vitalys.co');
      expect(find.text(mensajeDatosIncorrectos), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-10: los otros roles no pueden gestionar usuarios', (
      t,
    ) async {
      final audit = await _open(t);
      await entrarSedeUnica(t, 'Administrativo');
      expect(find.text('Usuarios'), findsNothing);
      final allowed = estadoApp(t).intentarAcceso(
        AccionPermitida.gestionarUsuarios,
        RecursoAuditoria.usuario,
      ) as bool;
      await t.pumpAndSettle();
      expect(allowed, isFalse);
      expect(find.text(rechazoRol), findsWidgets);
      final denied = audit.saved.last;
      expect(denied.recurso, RecursoAuditoria.usuario);
      expect(denied.resultado, ResultadoAuditoria.denegado);
      await t.pumpAndSettle(const Duration(seconds: 6));
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-11: si el evento no se puede crear, la cuenta no cambia', (
      t,
    ) async {
      final audit = await _open(t);
      await _signUp(t);
      await tocarAyuda(t, find.text('Volver al acceso'));
      await _enterAsDirector(t);
      audit.fails = true;
      await _approveAsDoctorInCaliNorte(t, 'Laura Ríos');
      expect(find.text(mensajeFallaCambio), findsOneWidget);
      await tocarAyuda(t, find.text('Cancelar'));
      expect(find.text('Pendiente'), findsWidgets);
      await cerrarAppAyuda(t);
    });
  });

  testWidgets('el director no pide pacientes ni mediciones; el médico sí', (
    t,
  ) async {
    final patients = CountingPatients();
    final indicators = CountingIndicators();
    t.view.physicalSize = celularAyuda;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: temaRedVitalys(),
        home: AppScreen(
          datos: _datos,
          patients: patients,
          indicators: indicators,
          reloj: () => _datos.hoy,
        ),
      ),
    );
    await _enterAsDirector(t);
    expect(find.byType(UsuariosPage), findsOneWidget);
    expect(patients.calls, 0);
    expect(indicators.calls, 0);
    await _signOut(t);

    await entrarMedica(t);
    expect(patients.calls, 1);
    expect(indicators.calls, 1);
    await cerrarAppAyuda(t);
  });

  testWidgets('CA-5: cada cuenta muestra su rol, sus sedes y su estado', (
    t,
  ) async {
    await _open(t);
    await _enterAsDirector(t);
    expect(find.text('Administrativo · Bogotá Usaquén'), findsOneWidget);
    expect(find.text('Auditor · Cali Norte'), findsOneWidget);
    expect(find.text('Activa'), findsWidgets);
    await cerrarAppAyuda(t);
  });

  testWidgets('Atrás en el editor de una cuenta vuelve a la lista', (t) async {
    await _open(t);
    await _enterAsDirector(t);
    await tocarAyuda(t, find.text('Andrés Felipe Ruiz'));
    expect(find.text('Cuenta activa'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Cuenta activa'), findsNothing);
    expect(find.byType(UsuariosPage), findsOneWidget);
    await cerrarAppAyuda(t);
  });

  testWidgets('Atrás en Crear cuenta vuelve al acceso', (t) async {
    await _open(t);
    await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Crear cuenta'));
    expect(find.text('Repita la contraseña'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Repita la contraseña'), findsNothing);
    expect(find.text('Ingresar'), findsOneWidget);
    await cerrarAppAyuda(t);
  });

  group('Cuentas con Supabase', () {
    SupabaseClient client(
      Future<http.Response> Function(http.Request request) answer,
    ) => SupabaseClient(
      'https://ejemplo.supabase.co',
      'clave-publica',
      httpClient: MockClient(answer),
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );

    http.Response json(Object body, http.Request request, [int status = 200]) =>
        http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );

    test(
      'un correo ya registrado vuelve sin identidades: no se crea otra',
      () async {
        final service = AccountSupabase(
          client: client(
            (r) async => json({
              'id': 'u9',
              'aud': 'authenticated',
              'email': _nueva,
              'identities': <Object>[],
              'app_metadata': <String, Object>{},
              'user_metadata': <String, Object>{},
              'created_at': '2026-11-27T00:00:00Z',
            }, r),
          ),
          sitesByName: const {},
        );
        final result = await service.signUp(
          name: 'Laura Ríos',
          email: _nueva,
          password: 'clave1234',
        );
        expect(result, SignUpStatus.emailTaken);
      },
    );

    test(
      'la app entiende cada rechazo de la base y no tapa las fallas',
      () async {
        Future<void> save(String message, int status) {
          final service = AccountSupabase(
            client: client((r) async {
              if (r.url.path.endsWith('/sede')) {
                return json([
                  {'id_sede': 1, 'nombre': 'Clínica Vitalys Cali Norte'},
                ], r);
              }
              return json(
                {
                  'code': 'P0001',
                  'message': message,
                  'details': null,
                  'hint': null,
                },
                r,
                status,
              );
            }),
            sitesByName: const {'Clínica Vitalys Cali Norte': 's1'},
          );
          return service.saveAccount(
            account: (
              id: 'x',
              name: 'Laura',
              email: _nueva,
              role: Rol.medico,
              sites: const [],
              active: true,
            ),
            role: Rol.medico,
            sites: const [],
            active: true,
            sessionSite: 's1',
          );
        }

        await expectLater(
          save('sin_sedes', 400),
          throwsA(
            isA<AccountRejected>().having(
              (e) => e.refusal,
              'refusal',
              AccountRefusal.noSites,
            ),
          ),
        );
        await expectLater(
          save('rol', 400),
          throwsA(
            isA<AccountRejected>().having(
              (e) => e.refusal,
              'refusal',
              AccountRefusal.role,
            ),
          ),
        );
        await expectLater(
          save('se cayó la base', 500),
          throwsA(isA<PostgrestException>()),
        );
      },
    );

    test('la directora inicia sesión con su rol', () async {
      String part(Map<String, Object> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      final exp = DateTime.now().add(const Duration(hours: 1));
      final token =
          '${part({'alg': 'HS256'})}.'
          '${part({'sub': 'u5', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.f';
      final auth = AuthSupabase(
        client: client((r) async {
          if (r.url.path.endsWith('/token')) {
            return json({
              'access_token': token,
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'r',
              'user': {
                'id': 'u5',
                'aud': 'authenticated',
                'email': _director,
                'app_metadata': <String, Object>{},
                'user_metadata': <String, Object>{},
                'created_at': '2026-11-27T00:00:00Z',
              },
            }, r);
          }
          return json({
            'nombre_completo': 'Patricia Londoño Vélez',
            'correo': _director,
            'activo': true,
            'rol': {'nombre': 'director'},
            'usuario_sede': [
              {
                'sede': {'nombre': 'Clínica Vitalys Cali Norte'},
              },
            ],
          }, r);
        }),
        sitesByName: const {'Clínica Vitalys Cali Norte': 's1'},
        knownUsers: const {},
      );
      final result = await auth.signIn(_director, 'vitalys2026');
      expect(result.status, SignInStatus.success);
      expect(result.user?.rol, Rol.director);
    });

    test(
      'la base rechaza quitarse el propio rol y la app lo entiende',
      () async {
        final service = AccountSupabase(
          client: client((r) async {
            if (r.url.path.endsWith('/sede')) {
              return json([
                {'id_sede': 1, 'nombre': 'Clínica Vitalys Cali Norte'},
              ], r);
            }
            return json(
              {
                'code': 'P0001',
                'message': 'propia',
                'details': null,
                'hint': null,
              },
              r,
              400,
            );
          }),
          sitesByName: const {'Clínica Vitalys Cali Norte': 's1'},
        );
        await expectLater(
          service.saveAccount(
            account: (
              id: 'u5',
              name: 'Patricia',
              email: _director,
              role: Rol.director,
              sites: const ['s1'],
              active: true,
            ),
            role: Rol.medico,
            sites: const ['s1'],
            active: true,
            sessionSite: 's1',
          ),
          throwsA(
            isA<AccountRejected>().having(
              (e) => e.refusal,
              'refusal',
              AccountRefusal.ownAccount,
            ),
          ),
        );
      },
    );
  });
}
