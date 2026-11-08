import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/pages/registrar_atencion_page.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';

const celular = Size(360, 780);
const escritorio = Size(1280, 800);

Future<void> abrirApp(WidgetTester t, {Size tamano = celular}) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: DatosSimulados.porDefecto),
    ),
  );
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

Future<void> atras(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

/// Entra como la Dra. Camila y declara el propósito de la lista.
Future<void> entrarComoMedica(WidgetTester t, {Size tamano = celular}) async {
  await abrirApp(t, tamano: tamano);
  await tocar(t, find.text('Médico'));
  await tocar(t, find.text('Ingresar'));
  await tocar(t, find.byType(DropdownButtonFormField<String>));
  await tocar(t, find.text('Clínica Vitalys Cali Norte').last);
  await tocar(t, find.text('Confirmar sede'));
  await tocar(t, find.text('Seguimiento de reingreso'));
  await tocar(t, find.text('Ver pacientes'));
}

/// Abre a un paciente declarando [proposito].
Future<void> abrirPaciente(
  WidgetTester t,
  String nombre,
  String proposito,
) async {
  await tocar(t, find.text('Ver todos →'));
  await tocar(t, find.text(nombre));
  await tocar(t, find.text(proposito));
  await tocar(t, find.text('Abrir historia clínica'));
}

/// En la historia: pide registrar y declara el propósito del pop-up.
Future<void> pedirRegistro(WidgetTester t, String proposito) async {
  await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
  await tocar(t, find.text(proposito));
  // El botón del pop-up queda por encima del de la historia.
  await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención').last);
}

Future<void> llenarAtencion(
  WidgetTester t, {
  String motivo = 'Dolor torácico leve',
  String diagnostico = 'R07.4 Dolor torácico',
  String? fecha,
}) async {
  final campos = find.byType(TextField);
  if (fecha != null) await t.enterText(campos.at(0), fecha);
  await t.enterText(campos.at(1), motivo);
  await t.enterText(campos.at(2), diagnostico);
  await t.pump();
}

double arriba(WidgetTester t, String texto) =>
    t.getTopLeft(find.textContaining(texto).first).dy;

void main() {
  group('Indicadores integrados en la app', () {
    testWidgets('el tablero abre su detalle y Atrás vuelve (360 px)', (
      t,
    ) async {
      await entrarComoMedica(t);
      await tocar(t, find.text('Indicadores'));
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      expect(find.text('Dónde actuar primero'), findsOneWidget);

      await tocar(t, find.text('Tiempo de espera promedio'));
      expect(find.text('Tendencia mensual'), findsOneWidget);
      expect(find.text('Comparación entre sedes'), findsOneWidget);
      expect(find.text('Mediciones recientes'), findsOneWidget);
      expect(t.takeException(), isNull);

      await atras(t);
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      expect(find.text('Tendencia mensual'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('también se ve sin desbordes en escritorio', (t) async {
      await entrarComoMedica(t, tamano: escritorio);
      await tocar(t, find.text('Indicadores'));
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      await tocar(t, find.text('Tiempo de espera promedio'));
      expect(find.text('Tendencia mensual'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('el Inicio es coherente: 0 de 4 empeoraron', (t) async {
      await entrarComoMedica(t);
      expect(find.text('frente al mes previo, de 4'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Historia clínica integrada (F-02, F-07)', () {
    testWidgets('muestra la historia, el riesgo y sus factores ordenados', (
      t,
    ) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'María Fernanda Rojas Benítez',
        'Consulta de historia clínica',
      );
      expect(find.text('HISTORIA CLÍNICA UNIFICADA'), findsOneWidget);
      expect(find.text('Riesgo de reingreso'), findsOneWidget);
      expect(find.text('Datos básicos'), findsOneWidget);
      expect(find.text('+18'), findsOneWidget);
      expect(find.text('−7'), findsOneWidget);
      // Del que más aporta al que menos, con el negativo al final (F-07).
      expect(arriba(t, '+18'), lessThan(arriba(t, '−7')));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('la historia de Jorge es la del diseño', (t) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'Jorge Eliécer Pardo Villamizar',
        'Seguimiento de reingreso',
      );
      expect(find.text('3 registros'), findsOneWidget);
      expect(
        find.textContaining('Insuficiencia cardíaca descompensada'),
        findsOneWidget,
      );
      expect(find.text('HCE Bogotá Usaquén'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('con Urgencia avisa que es una emergencia', (t) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'Hernán Darío Quintero Salcedo',
        'Urgencia (acceso de emergencia)',
      );
      expect(find.text(avisoAccesoEmergencia), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Registrar atención (F-04)', () {
    testWidgets('al registrar solo se ofrecen Atención y Urgencia', (t) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'María Fernanda Rojas Benítez',
        'Consulta de historia clínica',
      );
      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      expect(find.text('ANTES DE REGISTRAR UNA ATENCIÓN'), findsOneWidget);
      expect(find.text('Atención del paciente'), findsOneWidget);
      expect(find.text('Urgencia (acceso de emergencia)'), findsOneWidget);
      expect(find.text('Revisión de calidad'), findsNothing);
      expect(find.text('Seguimiento de reingreso'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('valida el motivo, el diagnóstico y la fecha', (t) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'María Fernanda Rojas Benítez',
        'Consulta de historia clínica',
      );
      await pedirRegistro(t, 'Atención del paciente');

      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      expect(find.text(mensajeCompleteAtencion), findsOneWidget);

      await llenarAtencion(t, fecha: '31/12/2026 10:00');
      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      expect(find.text(mensajeFechaFutura), findsOneWidget);

      await llenarAtencion(t, fecha: 'ayer');
      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      expect(find.text(mensajeFechaInvalida), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('la atención queda primera en la historia', (t) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'María Fernanda Rojas Benítez',
        'Consulta de historia clínica',
      );
      expect(find.text('2 registros'), findsOneWidget);

      await pedirRegistro(t, 'Atención del paciente');
      await llenarAtencion(t);
      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();

      expect(find.text('3 registros'), findsOneWidget);
      expect(find.textContaining('Dolor torácico leve'), findsOneWidget);
      expect(
        find.text('Atención registrada en la historia unificada'),
        findsOneWidget,
      );
      // La nueva va primero, antes de la hospitalización del alta.
      expect(
        arriba(t, 'Dolor torácico leve'),
        lessThan(arriba(t, 'Neumonía adquirida en la comunidad')),
      );
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('sin relación se deniega y con Urgencia se registra', (
      t,
    ) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'Hernán Darío Quintero Salcedo',
        'Urgencia (acceso de emergencia)',
      );

      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      await tocar(t, find.text('Atención del paciente'));
      await tocar(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar atención').last,
      );
      expect(find.text(rechazoRelacion), findsOneWidget);

      await tocar(t, find.text('Declarar Urgencia'));
      // El pop-up vuelve sin propósito elegido: se elige Urgencia (F-16).
      await tocar(t, find.text('Urgencia (acceso de emergencia)'));
      await tocar(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar atención').last,
      );
      await llenarAtencion(t);
      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();
      expect(find.textContaining('Dolor torácico leve'), findsOneWidget);

      // Registrar con Urgencia no da relación (F-05, CA-12 de F-04).
      await atras(t);
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      await tocar(t, find.text('Atención del paciente'));
      await tocar(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Atrás del sistema cierra el formulario sin guardar', (
      t,
    ) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'María Fernanda Rojas Benítez',
        'Consulta de historia clínica',
      );
      await pedirRegistro(t, 'Atención del paciente');
      expect(find.text('NUEVA ATENCIÓN'), findsOneWidget);
      await atras(t);
      expect(find.text('3 registros'), findsNothing);
      expect(find.text('2 registros'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Lo registrado llega a la auditoría (F-20, F-21)', () {
    testWidgets('el auditor ve el evento de la atención registrada', (t) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'María Fernanda Rojas Benítez',
        'Consulta de historia clínica',
      );
      await pedirRegistro(t, 'Atención del paciente');
      await llenarAtencion(t);
      await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();
      // El aviso de confirmación desaparece solo a los pocos segundos.
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();

      await tocar(t, find.byTooltip('Menú de usuario'));
      await tocar(t, find.text('Mi perfil'));
      await tocar(t, find.text('Cerrar sesión'));
      await tocar(t, find.text('Auditor'));
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));

      // 8 del Figma + ingreso de Camila + lista + historia y riesgo de
      // María (F-07) + atención registrada + ingreso de Marcela.
      await t.ensureVisible(find.text('14 eventos'));
      expect(find.text('14 eventos'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Datos de la historia', () {
    final datos = DatosSimulados.porDefecto;

    test('cada paciente de la lista tiene historia coherente con la lista', () {
      for (final p in datos.pacientes) {
        final h = historiaDe(
          p,
          sedeAlta: datos.sede(p.sedeAltaId).nombreCorto,
          hoy: datos.hoy,
        );
        expect(h.fullName, p.nombre);
        expect(h.documentNumber, p.numeroDocumento);
        expect(h.readmissionRisk?.score, p.riesgo);
        expect(h.encounters, isNotEmpty);
        // De la más reciente a la más antigua.
        final fechas = h.encounters.map((e) => e.startDate).toList();
        expect(fechas, [...fechas]..sort((a, b) => b.compareTo(a)));
      }
    });

    test('las atenciones nuevas van primero', () {
      final p = datos.pacientes.first;
      final h = historiaDe(p, sedeAlta: 'Bogotá Usaquén', hoy: datos.hoy);
      expect(h.encounters.length, 3);
    });

    test('la fecha del formulario se lee y se escribe igual', () {
      final f = DateTime(2026, 10, 30, 10, 42);
      expect(formatoFechaHoraCampo(f), '30/10/2026 10:42');
      expect(leerFechaHoraCampo('30/10/2026 10:42'), f);
      expect(leerFechaHoraCampo(' 5/1/2026 9:05 '), DateTime(2026, 1, 5, 9, 5));
    });

    test('rechaza fechas que no existen o mal escritas', () {
      expect(leerFechaHoraCampo('31/02/2026 10:00'), isNull);
      expect(leerFechaHoraCampo('30/10/2026 25:00'), isNull);
      expect(leerFechaHoraCampo('30/10/2026 10:75'), isNull);
      expect(leerFechaHoraCampo('ayer'), isNull);
      expect(leerFechaHoraCampo(''), isNull);
    });
  });
}
