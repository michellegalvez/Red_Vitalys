import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';

// Pruebas del modo demo "Simular fallas de red": la carga de cada pantalla y
// su error con Reintentar, y las acciones que fallan una vez. Mientras algo
// carga hay un indicador animado, por eso no se usa pumpAndSettle hasta que
// la carga termina.

const celular = Size(360, 780);
const clave = 'vitalys2026';
const correoCamila = 'camila.martinez@vitalys.co';
const correoMarcela = 'marcela.ospina@vitalys.co';
const correoAdministrativo = 'andres.ruiz@vitalys.co';
const paciente = 'María Fernanda Rojas Benítez';

Future<void> abrirApp(WidgetTester t) async {
  t.view.physicalSize = celular;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: DatosSimulados.porDefecto,
        reloj: () => DatosSimulados.porDefecto.hoy,
      ),
    ),
  );
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

/// Toca sin esperar a que todo se asiente: para lo que empieza a cargar.
Future<void> ir(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pump(const Duration(milliseconds: 50));
  await t.tap(f.first);
  await t.pump(const Duration(milliseconds: 50));
}

/// Deja pasar la carga simulada (600 ms) y lo que sigue.
Future<void> pasar(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 700));
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> reintentar(WidgetTester t) async {
  await ir(t, find.text('Reintentar'));
  await pasar(t);
}

Future<void> escribirCredenciales(WidgetTester t, String correo) async {
  await t.enterText(find.byType(TextField).at(0), correo);
  await t.enterText(find.byType(TextField).at(1), clave);
  await t.pump();
}

String? texto(WidgetTester t, int campo) =>
    t.widget<TextField>(find.byType(TextField).at(campo)).controller?.text;

Future<void> activarFallas(WidgetTester t) async {
  await abrirApp(t);
  expect(find.text('Simular fallas de red'), findsOneWidget);
  await tocar(t, find.text('Simular fallas de red'));
}

/// Entra con las fallas activas. La primera falla de [ingresar] se consume
/// reintentando. Termina sin esperar la carga de la primera pantalla.
Future<void> entrar(
  WidgetTester t,
  String correo, {
  bool elegirSede = false,
  String? propositoLista,
}) async {
  await activarFallas(t);
  await escribirCredenciales(t, correo);
  await tocar(t, find.text('Ingresar'));
  expect(
    find.text('No se pudo iniciar sesión. Intente de nuevo.'),
    findsOneWidget,
  );
  await escribirCredenciales(t, correo);
  await tocar(t, find.text('Ingresar'));
  if (elegirSede) {
    await tocar(t, find.byType(DropdownButtonFormField<String>));
    await tocar(t, find.text('Clínica Vitalys Cali Norte').last);
  }
  // Al confirmar la sede el registro del ingreso falla una vez (F-13).
  await tocar(t, find.text('Confirmar sede'));
  expect(
    find.text('No se pudo iniciar sesión. Intente de nuevo.'),
    findsOneWidget,
  );
  if (propositoLista == null) {
    await ir(t, find.text('Confirmar sede'));
    return;
  }
  await tocar(t, find.text('Confirmar sede'));
  await tocar(t, find.text(propositoLista));
  await ir(t, find.text('Ver pacientes'));
}

Future<void> entrarComoMedica(WidgetTester t) => entrar(
  t,
  correoCamila,
  elegirSede: true,
  propositoLista: 'Seguimiento de reingreso',
);

/// Médica en la historia de [paciente], con la verificación y el evento ya
/// reintentados y la historia y el riesgo cargados.
Future<void> abrirHistoria(WidgetTester t) async {
  await entrarComoMedica(t);
  await ir(t, find.text('Ver todos →'));
  await pasar(t);
  await reintentar(t);
  await tocar(t, find.text(paciente));
  await tocar(t, find.text('Consulta de historia clínica'));
  await tocar(t, find.text('Abrir historia clínica'));
  await tocar(t, find.text('Reintentar'));
  await ir(t, find.text('Reintentar'));
  await pasar(t);
  await reintentar(t);
  await pasar(t);
  await reintentar(t);
}

void main() {
  group('Sin el modo demo', () {
    testWidgets('el interruptor empieza apagado y no hay cargas', (t) async {
      await abrirApp(t);
      expect(t.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(
        find.text(
          'Para la demo: cada pantalla muestra su carga y falla una '
          'vez; Reintentar la carga.',
        ),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Acceso con fallas (F-13)', () {
    testWidgets('conserva el correo, borra la contraseña y no crea evento', (
      t,
    ) async {
      await activarFallas(t);
      await escribirCredenciales(t, correoMarcela);
      await tocar(t, find.text('Ingresar'));
      expect(
        find.text('No se pudo iniciar sesión. Intente de nuevo.'),
        findsOneWidget,
      );
      expect(texto(t, 0), correoMarcela);
      expect(texto(t, 1), isEmpty);

      await escribirCredenciales(t, correoMarcela);
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      await ir(t, find.text('Confirmar sede'));
      // Auditoría: carga, error y, al reintentar, los 8 del Figma más el
      // ingreso de Marcela (el intento fallido de red no creó ninguno).
      expect(find.text('Cargando eventos…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudieron cargar los eventos'), findsOneWidget);
      await reintentar(t);
      await t.ensureVisible(find.text('9 eventos'));
      expect(find.text('9 eventos'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Registro del ingreso con fallas (F-13 paso 5)', () {
    testWidgets('si falla, no abre la sesión y al reintentar entra', (t) async {
      await activarFallas(t);
      await escribirCredenciales(t, correoMarcela);
      await tocar(t, find.text('Ingresar'));
      await escribirCredenciales(t, correoMarcela);
      await tocar(t, find.text('Ingresar'));

      await tocar(t, find.text('Confirmar sede'));
      expect(
        find.text('No se pudo iniciar sesión. Intente de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Confirmar sede'), findsOneWidget);
      expect(find.text('Auditoría de accesos'), findsNothing);

      await ir(t, find.text('Confirmar sede'));
      expect(find.text('Cargando eventos…'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Cargas y errores (F-01, F-02, F-03, F-06, F-07, F-21, F-22)', () {
    testWidgets('la lista del inicio y la de seguimiento (F-06)', (t) async {
      await entrarComoMedica(t);
      expect(find.text('Cargando pacientes…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudo cargar la lista'), findsOneWidget);
      await reintentar(t);
      expect(find.text('No se pudo cargar la lista'), findsNothing);
      expect(find.text('Cargando pacientes…'), findsNothing);

      await ir(t, find.text('Ver todos →'));
      expect(find.text('Cargando pacientes…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudo cargar la lista'), findsOneWidget);
      await reintentar(t);
      expect(find.text(paciente), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('la búsqueda repite la carga con cada texto (F-01)', (t) async {
      await entrarComoMedica(t);
      await ir(t, find.text('Buscar'));
      await t.pump(const Duration(milliseconds: 300));
      await t.enterText(find.byType(TextField).first, 'rojas');
      await t.pump();
      expect(find.text('Buscando…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudo buscar. Intente de nuevo.'), findsOneWidget);
      await reintentar(t);
      expect(find.text(paciente), findsOneWidget);

      await t.enterText(find.byType(TextField).first, 'maria');
      await t.pump();
      expect(find.text('Buscando…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudo buscar. Intente de nuevo.'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('la historia y su riesgo (F-02, F-07)', (t) async {
      await entrarComoMedica(t);
      await ir(t, find.text('Ver todos →'));
      await pasar(t);
      await reintentar(t);
      await tocar(t, find.text(paciente));
      await tocar(t, find.text('Consulta de historia clínica'));
      await tocar(t, find.text('Abrir historia clínica'));
      // La verificación y el evento fallan una vez cada uno (F-05, F-20).
      expect(find.text('No se pudo verificar el acceso'), findsOneWidget);
      expect(find.text('Cargando historia…'), findsNothing);
      await tocar(t, find.text('Reintentar'));
      expect(find.text('No se pudo completar la acción'), findsOneWidget);
      await ir(t, find.text('Reintentar'));
      expect(find.text('Cargando historia…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudo cargar la historia'), findsOneWidget);
      await reintentar(t);
      expect(find.text('Cargando riesgo…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudo cargar el riesgo'), findsOneWidget);
      await reintentar(t);
      expect(find.text('Cargando riesgo…'), findsNothing);
      expect(find.textContaining('Base del modelo:'), findsOneWidget);
      expect(find.text('Sube'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('los datos básicos del administrativo (F-03)', (t) async {
      await entrar(t, correoAdministrativo);
      await ir(t, find.text('Buscar'));
      await t.pump(const Duration(milliseconds: 300));
      await t.enterText(find.byType(TextField).first, 'rojas');
      await t.pump();
      await pasar(t);
      await reintentar(t);
      await tocar(t, find.text(paciente));
      await tocar(t, find.text('Revisión de calidad'));
      await tocar(t, find.text('Ver datos básicos'));
      expect(find.text('No se pudo verificar el acceso'), findsOneWidget);
      await tocar(t, find.text('Reintentar'));
      expect(find.text('No se pudo completar la acción'), findsOneWidget);
      await ir(t, find.text('Reintentar'));
      expect(find.text('Cargando datos del paciente…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudieron cargar los datos'), findsOneWidget);
      await reintentar(t);
      expect(find.text('DATOS BÁSICOS'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('la auditoría (F-21)', (t) async {
      await entrar(t, correoMarcela);
      expect(find.text('Cargando eventos…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudieron cargar los eventos'), findsOneWidget);
      await reintentar(t);
      expect(find.text('No se pudieron cargar los eventos'), findsNothing);
      expect(find.text('Auditoría de accesos'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('el perfil mantiene Cerrar sesión (F-22)', (t) async {
      await entrar(t, correoMarcela);
      await pasar(t);
      await ir(t, find.byTooltip('Menú de usuario'));
      await t.pump(const Duration(milliseconds: 300));
      await ir(t, find.text('Mi perfil'));
      expect(find.text('Cargando perfil…'), findsOneWidget);
      await pasar(t);
      expect(find.text('No se pudo cargar su perfil'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      await reintentar(t);
      expect(find.text('Qué puede hacer con su rol'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Acciones que fallan (F-04, F-12, F-23)', () {
    testWidgets('guardar la atención conserva lo escrito (F-04, F-20)', (
      t,
    ) async {
      await abrirHistoria(t);
      await tocar(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar atención').first,
      );
      await tocar(t, find.text('Atención del paciente'));
      await tocar(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar atención').last,
      );
      await tocar(t, find.text('Consulta externa'));
      final campos = find.byType(TextField);
      await t.enterText(campos.at(0), '06/11/2026');
      await t.enterText(campos.at(1), '06/11/2026');
      await t.pump();

      Future<void> guardar() async {
        await tocar(t, find.widgetWithText(BotonVitalys, 'Guardar atención'));
        await t.pump(const Duration(milliseconds: 500));
        await t.pumpAndSettle();
      }

      await guardar();
      expect(find.text('No se pudo completar la acción'), findsOneWidget);
      expect(find.text('06/11/2026'), findsNWidgets(2));
      await guardar();
      expect(find.text('No se pudo registrar la atención'), findsOneWidget);
      expect(find.text('06/11/2026'), findsNWidgets(2));
      await guardar();
      expect(find.text('No se pudo registrar la atención'), findsNothing);
      expect(
        find.text('Atención registrada en la historia unificada'),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('guardar la medición conserva el valor (F-12)', (t) async {
      await entrar(t, correoAdministrativo);
      await pasar(t);
      await tocar(t, find.text('Mediciones'));
      await tocar(t, find.byType(DropdownButtonFormField<IdIndicador>));
      await tocar(t, find.text('Eventos adversos evitables').last);
      await tocar(t, find.byType(DropdownButtonFormField<String>).first);
      await tocar(t, find.text('Centro Ambulatorio Envigado').last);
      await t.enterText(find.byType(TextField).first, '1,6');
      await t.pump();
      Future<void> guardar() async {
        await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar medición'));
        await t.pump(const Duration(milliseconds: 500));
        await t.pumpAndSettle();
      }

      // Primero falla el evento (F-20) y después el guardado (F-12).
      await guardar();
      expect(find.text('No se pudo completar la acción'), findsOneWidget);
      expect(find.text('1,6'), findsOneWidget);
      await guardar();
      expect(find.text('No se pudo registrar la medición'), findsOneWidget);
      expect(find.text('1,6'), findsOneWidget);
      await guardar();
      expect(find.text('Medición registrada'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('el error de cierre se ve con el perfil en error (F-23)', (
      t,
    ) async {
      await entrar(t, correoMarcela);
      await pasar(t);
      await ir(t, find.byTooltip('Menú de usuario'));
      await t.pump(const Duration(milliseconds: 300));
      await ir(t, find.text('Mi perfil'));
      await pasar(t);
      expect(find.text('No se pudo cargar su perfil'), findsOneWidget);

      await ir(t, find.text('Cerrar sesión'));
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();
      expect(
        find.text('No se pudo cerrar la sesión. Intente de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('No se pudo cargar su perfil'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('cerrar sesión muestra el error y sigue en el perfil (F-23)', (
      t,
    ) async {
      await entrar(t, correoMarcela);
      await pasar(t);
      await ir(t, find.byTooltip('Menú de usuario'));
      await t.pump(const Duration(milliseconds: 300));
      await ir(t, find.text('Mi perfil'));
      await pasar(t);
      await reintentar(t);

      await ir(t, find.text('Cerrar sesión'));
      expect(find.text('Cerrando sesión…'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();
      expect(
        find.text('No se pudo cerrar la sesión. Intente de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Perfil'), findsWidgets);
      expect(find.text('Ingrese a su sesión'), findsNothing);

      await ir(t, find.text('Cerrar sesión'));
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();
      expect(find.text('Ingrese a su sesión'), findsOneWidget);
      // El interruptor se conserva al cerrar la sesión.
      expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);
      await t.pumpWidget(const SizedBox());
    });
  });
}
