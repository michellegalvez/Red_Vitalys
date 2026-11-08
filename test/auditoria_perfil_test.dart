import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/pages/perfil_page.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';

const celular = Size(360, 780);
const escritorio = Size(1280, 800);
const clave = 'vitalys2026';

final datos = DatosSimulados.porDefecto;

/// Los datos simulados sin los 8 eventos del Figma, para probar los
/// filtros vacíos.
final datosSinEventos = DatosSimulados(
  hoy: datos.hoy,
  sedes: datos.sedes,
  usuarios: datos.usuarios,
  pacientes: datos.pacientes,
  contrasenaPrototipo: datos.contrasenaPrototipo,
  indicadoresQueEmpeoraron: datos.indicadoresQueEmpeoraron,
  totalIndicadores: datos.totalIndicadores,
  eventos: const [],
  ipPrototipo: datos.ipPrototipo,
);

Future<void> abrirApp(
  WidgetTester t, {
  Size tamano = celular,
  DatosSimulados? conDatos,
}) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: conDatos ?? datos, reloj: () => datos.hoy),
    ),
  );
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

Future<void> escribir(WidgetTester t, String correo, String contrasena) async {
  await t.enterText(find.byType(TextField).at(0), correo);
  await t.enterText(find.byType(TextField).at(1), contrasena);
  await t.pump();
}

/// Entra con un usuario que tiene una sola sede asignada.
Future<void> entrar(WidgetTester t, String correo) async {
  await escribir(t, correo, clave);
  await tocar(t, find.text('Ingresar'));
  await tocar(t, find.text('Confirmar sede'));
}

Future<void> entrarComoAuditora(WidgetTester t) =>
    entrar(t, 'marcela.ospina@vitalys.co');

/// Entra como la Dra. Camila con Cali Norte y declara el propósito de la
/// lista de pacientes con alta reciente.
Future<void> entrarComoMedica(WidgetTester t) async {
  await escribir(t, 'camila.martinez@vitalys.co', clave);
  await tocar(t, find.text('Ingresar'));
  await tocar(t, find.byType(DropdownButtonFormField<String>));
  await tocar(t, find.text('Clínica Vitalys Cali Norte').last);
  await tocar(t, find.text('Confirmar sede'));
  await tocar(t, find.text('Seguimiento de reingreso'));
  await tocar(t, find.text('Ver pacientes'));
}

Future<void> abrirPerfil(WidgetTester t) async {
  await tocar(t, find.byTooltip('Menú de usuario'));
  await tocar(t, find.text('Mi perfil'));
}

Future<void> cerrarSesion(WidgetTester t) =>
    tocar(t, find.text('Cerrar sesión'));

/// Cierra la app para que no quede pendiente el temporizador de inactividad.
Future<void> cerrarApp(WidgetTester t) => t.pumpWidget(const SizedBox());

void main() {
  group('Reglas de la auditoría (F-20, F-21)', () {
    test('con Todos van los 8 eventos del Figma, del más reciente', () {
      final lista = eventosFiltrados(datos.eventos, FiltroAuditoria.todos);
      expect(lista.map((e) => e.id), [
        'e1',
        'e2',
        'e3',
        'e4',
        'e5',
        'e6',
        'e7',
        'e8',
      ]);
    });

    test('Denegados deja 2 y Emergencia deja el de Urgencia', () {
      expect(
        eventosFiltrados(
          datos.eventos,
          FiltroAuditoria.denegados,
        ).map((e) => e.id),
        ['e1', 'e8'],
      );
      expect(
        eventosFiltrados(
          datos.eventos,
          FiltroAuditoria.emergencia,
        ).map((e) => e.id),
        ['e7'],
      );
    });

    test('con la misma hora va primero el que se agregó último', () {
      EventoAuditoria evento(String id) => EventoAuditoria(
        id: id,
        fechaHora: datos.hoy,
        accion: AccionAuditoria.ingresar,
        recurso: RecursoAuditoria.sesion,
        resultado: ResultadoAuditoria.permitido,
      );
      final lista = eventosFiltrados([
        ...datos.eventos,
        evento('a'),
        evento('b'),
      ], FiltroAuditoria.todos);
      expect(lista.take(3).map((e) => e.id), ['b', 'a', 'e1']);
    });

    test('la lista filtrada no se puede modificar (AD-08)', () {
      final lista = eventosFiltrados(datos.eventos, FiltroAuditoria.todos);
      expect(() => lista.removeLast(), throwsUnsupportedError);
    });

    test('los datos cumplen RNF-04: 8 eventos, denegados y emergencia', () {
      expect(datos.eventos, hasLength(greaterThanOrEqualTo(8)));
      expect(
        datos.eventos.where((e) => e.resultado == ResultadoAuditoria.denegado),
        isNotEmpty,
      );
      expect(datos.eventos.where((e) => e.esEmergencia), isNotEmpty);
    });
  });

  group('Tabla de permisos (F-18, F-22)', () {
    List<AccionPermitida> permitidas(Rol rol) => [
      for (final a in AccionPermitida.values)
        if (rolPermite(rol, a)) a,
    ];

    test('el médico tiene 5 de las 7 acciones', () {
      expect(permitidas(Rol.medico), [
        AccionPermitida.buscarPaciente,
        AccionPermitida.verHistoria,
        AccionPermitida.registrarAtencion,
        AccionPermitida.verTablero,
        AccionPermitida.verPerfil,
      ]);
    });

    test('el administrativo tiene 4', () {
      expect(permitidas(Rol.administrativo), [
        AccionPermitida.buscarPaciente,
        AccionPermitida.verTablero,
        AccionPermitida.registrarMedicion,
        AccionPermitida.verPerfil,
      ]);
    });

    test('el auditor tiene 3', () {
      expect(permitidas(Rol.auditor), [
        AccionPermitida.verTablero,
        AccionPermitida.verAuditoria,
        AccionPermitida.verPerfil,
      ]);
    });
  });

  group('Auditoría de accesos (F-21)', () {
    testWidgets('el auditor ve los eventos con su ingreso primero', (t) async {
      await abrirApp(t);
      await entrarComoAuditora(t);
      expect(find.text('Auditoría de accesos'), findsWidgets);
      expect(find.text('Los registros no se pueden editar.'), findsNothing);
      expect(
        find.textContaining('Los registros no se pueden editar.'),
        findsOneWidget,
      );
      // Los 8 del Figma más el ingreso de Marcela (F-20 A3).
      await t.ensureVisible(find.text('9 eventos'));
      expect(find.text('9 eventos'), findsOneWidget);
      expect(find.text('30 oct 2026 · 10:42'), findsOneWidget);
      expect(find.text('30 oct 2026 · 09:47'), findsOneWidget);
      expect(find.text('28 oct 2026 · 10:02'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('los filtros son excluyentes y actualizan el contador', (
      t,
    ) async {
      await abrirApp(t);
      await entrarComoAuditora(t);

      await tocar(t, find.text('Denegados'));
      await t.ensureVisible(find.text('2 eventos'));
      expect(find.text('2 eventos'), findsOneWidget);
      expect(find.text('Riesgo de reingreso'), findsOneWidget);
      expect(find.text('30 oct 2026 · 09:44'), findsNothing);

      await tocar(t, find.text('Emergencia'));
      await t.ensureVisible(find.text('1 evento'));
      expect(find.text('1 evento'), findsOneWidget);
      expect(find.text('Luz Marina Cardona Arias'), findsOneWidget);

      await tocar(t, find.text('Todos'));
      await t.ensureVisible(find.text('9 eventos'));
      expect(find.text('9 eventos'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('un filtro sin eventos lo avisa', (t) async {
      await abrirApp(t, conDatos: datosSinEventos);
      await entrarComoAuditora(t);
      await tocar(t, find.text('Emergencia'));
      expect(find.text(mensajeSinEventos), findsOneWidget);
      await t.ensureVisible(find.text('0 eventos'));
      expect(find.text('0 eventos'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('en escritorio la tabla se ve completa, sin deslizar', (
      t,
    ) async {
      await abrirApp(t, tamano: escritorio);
      await entrarComoAuditora(t);
      expect(find.textContaining('Deslice la tabla'), findsNothing);
      expect(find.text('SEDE'), findsOneWidget);
      expect(find.text('RESULTADO'), findsOneWidget);
      expect(find.text('Urgencia (acceso de emergencia)'), findsOneWidget);
      expect(find.text('María Fernanda Rojas Benítez'), findsWidgets);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });

    for (final ancho in [1280.0, 960.0]) {
      testWidgets('en computador de $ancho px ninguna palabra se parte', (
        t,
      ) async {
        // Se entra en una ventana ancha y después se angosta: así se prueba
        // solo la tabla y no el inicio de sesión.
        await abrirApp(t, tamano: escritorio);
        await entrarComoAuditora(t);
        t.view.physicalSize = Size(ancho, 800);
        await t.pumpAndSettle();
        // Un texto está en una sola línea si mide lo mismo de alto que con
        // ancho infinito.
        for (final texto in [
          'Consultar',
          'Ingresar',
          'Permitido',
          'Denegado',
          '30 oct 2026 · 09:47',
        ]) {
          for (final elemento in find.text(texto).evaluate()) {
            final parrafo = elemento.renderObject! as RenderParagraph;
            expect(
              parrafo.size.height,
              parrafo.getMinIntrinsicHeight(double.infinity),
              reason: '"$texto" se partió en $ancho px',
            );
          }
        }
        expect(t.takeException(), isNull);
        await cerrarApp(t);
      });
    }

    testWidgets('en celular pide deslizar para ver el resto', (t) async {
      await abrirApp(t);
      await entrarComoAuditora(t);
      expect(find.textContaining('Deslice la tabla'), findsOneWidget);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });
  });

  group('Eventos que crea el flujo (F-20)', () {
    testWidgets('la lista, el rechazo y la Urgencia del médico se registran', (
      t,
    ) async {
      await abrirApp(t);
      await entrarComoMedica(t);
      await tocar(t, find.text('Ver todos →'));
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      await tocar(t, find.text('Atención del paciente'));
      await tocar(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);
      await tocar(t, find.text('Declarar Urgencia'));
      await tocar(t, find.text('Abrir historia clínica'));
      await tocar(t, find.textContaining('Pacientes  /'));

      await abrirPerfil(t);
      await cerrarSesion(t);
      await entrarComoAuditora(t);

      // 8 del Figma + ingreso de Camila + lista + rechazo + Urgencia +
      // ingreso de Marcela.
      await t.ensureVisible(find.text('13 eventos'));
      expect(find.text('13 eventos'), findsOneWidget);
      await tocar(t, find.text('Denegados'));
      await t.ensureVisible(find.text('3 eventos'));
      expect(find.text('3 eventos'), findsOneWidget);
      await tocar(t, find.text('Emergencia'));
      await t.ensureVisible(find.text('2 eventos'));
      expect(find.text('2 eventos'), findsOneWidget);
      expect(find.text('Hernán Darío Quintero Salcedo'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('un ingreso fallido queda con el correo y la IP', (t) async {
      await abrirApp(t, tamano: escritorio);
      await escribir(t, 'camila.martinez@vitalys.co', 'equivocada');
      await tocar(t, find.text('Ingresar'));
      expect(find.text(mensajeDatosIncorrectos), findsOneWidget);

      await entrarComoAuditora(t);
      await tocar(t, find.text('Denegados'));
      expect(find.text('camila.martinez@vitalys.co'), findsOneWidget);
      expect(find.text('IP ${datos.ipPrototipo}'), findsOneWidget);
      expect(find.text('3 eventos'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('en celular el correo de un ingreso fallido no se parte', (
      t,
    ) async {
      await abrirApp(t);
      await escribir(t, 'camila.martinez@vitalys.co', 'equivocada');
      await tocar(t, find.text('Ingresar'));
      await entrarComoAuditora(t);
      await tocar(t, find.text('Denegados'));

      final parrafo = t.renderObject(
        find.text('camila.martinez@vitalys.co'),
      ) as RenderParagraph;
      expect(
        parrafo.size.height,
        parrafo.getMinIntrinsicHeight(double.infinity),
      );
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });

    testWidgets('cancelar el propósito no crea un evento', (t) async {
      await abrirApp(t);
      await escribir(t, 'camila.martinez@vitalys.co', clave);
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.byType(DropdownButtonFormField<String>));
      await tocar(t, find.text('Clínica Vitalys Cali Norte').last);
      await tocar(t, find.text('Confirmar sede'));
      await tocar(t, find.text('Ahora no'));
      await abrirPerfil(t);
      await cerrarSesion(t);
      await entrarComoAuditora(t);
      // 8 + ingreso de Camila + ingreso de Marcela: la cancelación no suma.
      await t.ensureVisible(find.text('10 eventos'));
      expect(find.text('10 eventos'), findsOneWidget);
      await cerrarApp(t);
    });
  });

  group('Perfil (F-22) y cierre de sesión (F-23)', () {
    testWidgets('la médica ve sus datos, sus sedes y sus permisos', (t) async {
      await abrirApp(t);
      await entrarComoMedica(t);
      await abrirPerfil(t);

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Dra. Camila Martínez'), findsOneWidget);
      expect(find.text('camila.martinez@vitalys.co'), findsOneWidget);
      expect(find.text('Médico'), findsOneWidget);
      expect(find.text('SEDE DE ESTA SESIÓN'), findsOneWidget);
      expect(find.text('Clínica Vitalys Cali Norte'), findsOneWidget);
      expect(
        find.text('Clínica Vitalys Cali Norte\nCentro Ambulatorio Cali Sur'),
        findsOneWidget,
      );
      expect(find.text('Permitido'), findsNWidgets(5));
      expect(find.text('No incluido'), findsNWidgets(2));
      for (final a in AccionPermitida.values) {
        expect(find.text(a.nombre), findsOneWidget);
      }
      // Los 5 propósitos (F-22 CA-11).
      for (final p in Proposito.values) {
        expect(find.text(p.nombreCorto), findsOneWidget);
      }
      expect(find.text(notaPerfil), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('el auditor ve 3 permisos y ningún propósito', (t) async {
      await abrirApp(t, tamano: escritorio);
      await entrarComoAuditora(t);
      await abrirPerfil(t);
      expect(find.text('Auditor'), findsOneWidget);
      expect(find.text('Permitido'), findsNWidgets(3));
      expect(find.text('No incluido'), findsNWidgets(4));
      expect(find.text('Su rol no declara propósitos.'), findsOneWidget);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });

    testWidgets('el administrativo solo declara Revisión de calidad', (
      t,
    ) async {
      await abrirApp(t);
      await entrar(t, 'andres.ruiz@vitalys.co');
      await abrirPerfil(t);
      expect(find.text('Administrativo'), findsOneWidget);
      expect(find.text('Permitido'), findsNWidgets(4));
      expect(find.text('Revisión de calidad'), findsOneWidget);
      expect(find.text('Urgencia'), findsNothing);
      await cerrarApp(t);
    });

    testWidgets('un destino de la barra cierra el perfil', (t) async {
      await abrirApp(t);
      await entrarComoAuditora(t);
      await abrirPerfil(t);
      await tocar(t, find.text('Indicadores').last);
      expect(find.text('Perfil'), findsNothing);
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('Cerrar sesión vuelve al inicio y pide la sede otra vez', (
      t,
    ) async {
      await abrirApp(t);
      await entrarComoMedica(t);
      await abrirPerfil(t);
      await cerrarSesion(t);
      expect(find.text('Ingrese a su sesión'), findsOneWidget);

      // Atrás no vuelve a la app (F-23 A1).
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Perfil'), findsNothing);

      // La sede anterior ya no está elegida (F-23 CA-3).
      await escribir(t, 'camila.martinez@vitalys.co', clave);
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      expect(find.text(mensajeElijaSede), findsOneWidget);
      await cerrarApp(t);
    });
  });
}
