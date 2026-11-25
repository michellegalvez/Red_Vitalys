import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/repositorios/auth_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';

class _AuditoriaFallaSimulada implements AuditoriaRepositorio {
  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async {
    throw Exception('Error simulado al guardar auditoría');
  }

  @override
  Future<List<EventoAuditoria>> listar() async => [];
}

class _AuthFalso implements AuthRepositorio {
  _AuthFalso({required this.usuario, required this.sedes});

  final Usuario usuario;
  final List<Sede> sedes;
  Usuario? _actual;

  @override
  bool get esRemoto => false;

  @override
  Usuario? get usuarioActual => _actual;

  @override
  Future<AuthResultado> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    _actual = usuario;
    return AuthExito(usuario: usuario, sedes: sedes);
  }

  @override
  Future<void> cerrarSesion() async {
    _actual = null;
  }
}

void main() {
  testWidgets(
    'Si falla el guardado de auditoría, la sesión no se abre (AD-07)',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final datos = DatosSimulados.porDefecto;
      final medica = datos.usuarioPorCorreo('camila.martinez@vitalys.co')!;
      final sedes = [datos.sede('s1'), datos.sede('s2')];

      final auth = _AuthFalso(usuario: medica, sedes: sedes);
      final auditoria = _AuditoriaFallaSimulada();

      await tester.pumpWidget(
        MaterialApp(
          theme: temaRedVitalys(),
          home: AppScreen(datos: datos, auth: auth, auditoria: auditoria),
        ),
      );

      // Ingresar credenciales
      await tester.enterText(
        find.byType(TextField).at(0),
        'camila.martinez@vitalys.co',
      );
      await tester.enterText(find.byType(TextField).at(1), 'vitalys2026');
      await tester.ensureVisible(find.text('Ingresar'));
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      // Debe estar en el paso de elegir sede
      expect(find.text('Confirmar sede'), findsOneWidget);

      // Elegir sede
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clínica Vitalys Cali Norte').last);
      await tester.pumpAndSettle();

      // Confirmar sede -> debe intentar guardar auditoría y fallar
      await tester.ensureVisible(find.text('Confirmar sede'));
      await tester.tap(find.text('Confirmar sede'));
      await tester.pumpAndSettle();

      // La sesión NO debe abrirse y debe mostrarse mensaje de error
      expect(
        find.text('No se pudo iniciar sesión. Intente de nuevo.'),
        findsOneWidget,
      );
      // Debe permanecer en la pantalla de acceso / selección de sede
      expect(find.text('Confirmar sede'), findsOneWidget);
    },
  );
}
