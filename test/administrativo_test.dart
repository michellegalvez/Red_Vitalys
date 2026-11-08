import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/pages/registrar_medicion_page.dart';
import 'package:red_vitalys/reglas/busqueda.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/pacientes.dart';

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

Future<void> cerrarApp(WidgetTester t) => t.pumpWidget(const SizedBox());

/// Entra como el administrativo (una sola sede) y queda en el tablero.
Future<void> entrarComoAdministrativo(
  WidgetTester t, {
  Size tamano = celular,
}) async {
  await abrirApp(t, tamano: tamano);
  await tocar(t, find.text('Administrativo'));
  await tocar(t, find.text('Ingresar'));
  await tocar(t, find.text('Confirmar sede'));
}

/// Entra como la Dra. Camila y declara el propósito de la lista.
Future<void> entrarComoMedica(WidgetTester t) async {
  await abrirApp(t);
  await tocar(t, find.text('Médico'));
  await tocar(t, find.text('Ingresar'));
  await tocar(t, find.byType(DropdownButtonFormField<String>));
  await tocar(t, find.text('Clínica Vitalys Cali Norte').last);
  await tocar(t, find.text('Confirmar sede'));
  await tocar(t, find.text('Seguimiento de reingreso'));
  await tocar(t, find.text('Ver pacientes'));
}

Future<void> elegir<T>(WidgetTester t, String opcion) async {
  await tocar(t, find.byType(DropdownButtonFormField<T>));
  await tocar(t, find.text(opcion).last);
}

void main() {
  group('Tablero de indicadores con datos (RF-08, RF-09, RF-26, RF-27)', () {
    testWidgets('el administrativo entra al tablero y ve los 4 indicadores', (
      t,
    ) async {
      await entrarComoAdministrativo(t);
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      for (final i in indicadores) {
        expect(find.text(i.nombre), findsWidgets);
      }
      // Los valores de la red salen de las mediciones, con 1 decimal.
      expect(find.text('25,8'), findsOneWidget);
      expect(find.text('86,9'), findsOneWidget);
      expect(find.text('1,8'), findsOneWidget);
      expect(find.text('Mejora'), findsNWidgets(4));
      expect(find.text('Empeora'), findsNothing);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });

    testWidgets('el detalle cambia según el indicador que se toca', (t) async {
      await entrarComoAdministrativo(t);
      await tocar(t, find.text('Tiempo de espera promedio'));
      expect(find.text('ESTRUCTURA · min'), findsOneWidget);
      expect(find.text('Tendencia mensual'), findsOneWidget);
      expect(find.text('Comparación entre sedes'), findsOneWidget);
      expect(find.text('Mediciones recientes'), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();

      await tocar(t, find.text('Adherencia a protocolos clínicos'));
      expect(find.text('PROCESO · %'), findsOneWidget);
      expect(find.text('ESTRUCTURA · min'), findsNothing);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });

    testWidgets('una sede sin medición se ve como Sin medición', (t) async {
      await entrarComoAdministrativo(t);
      await tocar(t, find.text('Eventos adversos evitables'));
      expect(find.text(mensajeSinMedicion), findsWidgets);
      expect(find.text('Amb. Envigado'), findsWidgets);
      await cerrarApp(t);
    });

    testWidgets('la tendencia se puede ver por sede (RF-10)', (t) async {
      await entrarComoAdministrativo(t);
      await tocar(t, find.text('Reingreso hospitalario a 30 días'));
      expect(find.textContaining('Último periodo: 8,3 %'), findsOneWidget);

      await elegir<String?>(t, 'Cali Norte');
      expect(find.textContaining('Último periodo: 9,8 %'), findsOneWidget);

      await elegir<String?>(t, 'Toda la red');
      expect(find.textContaining('Último periodo: 8,3 %'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('el mes sin medición de una sede se avisa en la tendencia', (
      t,
    ) async {
      await entrarComoAdministrativo(t);
      await tocar(t, find.text('Eventos adversos evitables'));
      await elegir<String?>(t, 'Amb. Envigado');
      expect(find.text('Sin medición en oct 2026'), findsOneWidget);
      expect(find.textContaining('Último periodo:'), findsNothing);
      await cerrarApp(t);
    });

    testWidgets('el detalle no se desplaza hacia los lados (RNF-07)', (
      t,
    ) async {
      await entrarComoAdministrativo(t);
      await tocar(t, find.text('Reingreso hospitalario a 30 días'));
      expect(t.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final scroll = t.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.scrollDirection, Axis.vertical);
      await cerrarApp(t);
    });

    testWidgets('en escritorio el tablero y el detalle caben', (t) async {
      await entrarComoAdministrativo(t, tamano: escritorio);
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      await tocar(t, find.text('Tiempo de espera promedio'));
      expect(find.text('ESTRUCTURA · min'), findsOneWidget);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });
  });

  group('Registrar medición (F-12, RF-13, RF-28, RF-29, RF-30)', () {
    Future<void> irARegistrar(WidgetTester t) async {
      await entrarComoAdministrativo(t);
      await tocar(t, find.text('Mediciones'));
    }

    Future<void> escribirValor(WidgetTester t, String valor) async {
      await t.enterText(find.byType(TextField).first, valor);
      await t.pump();
    }

    Future<void> registrar(WidgetTester t) =>
        tocar(t, find.widgetWithText(BotonVitalys, 'Registrar medición'));

    testWidgets('el administrativo llega al formulario desde el menú', (
      t,
    ) async {
      await irARegistrar(t);
      expect(find.text('Registrar medición mensual'), findsOneWidget);
      expect(find.text('Indicador'), findsOneWidget);
      expect(find.text('Sede'), findsOneWidget);
      expect(find.text('Mes'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('rechaza una medición repetida de la sede y el mes', (t) async {
      await irARegistrar(t);
      // Por defecto: reingreso, Cali Norte, octubre, que ya existe.
      await escribirValor(t, '8,5');
      await registrar(t);
      expect(find.text(mensajeMedicionRepetida), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('rechaza un indicador que no aplica a la sede', (t) async {
      await irARegistrar(t);
      await elegir<String>(t, 'Centro Ambulatorio Cali Sur');
      await escribirValor(t, '8,5');
      await registrar(t);
      expect(find.text(mensajeNoAplica), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('rechaza un mes que todavía no termina', (t) async {
      await irARegistrar(t);
      await elegir<IdIndicador>(t, 'Eventos adversos evitables');
      await elegir<String>(t, 'Centro Ambulatorio Envigado');
      await elegir<DateTime>(t, 'nov 2026');
      await escribirValor(t, '1,6');
      await registrar(t);
      expect(find.text(mensajeMesAbierto), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('rechaza más de 1 decimal y un valor fuera de rango', (
      t,
    ) async {
      await irARegistrar(t);
      await elegir<IdIndicador>(t, 'Eventos adversos evitables');
      await elegir<String>(t, 'Centro Ambulatorio Envigado');
      await escribirValor(t, '1,66');
      await registrar(t);
      expect(find.text(mensajeUnDecimal), findsOneWidget);

      await escribirValor(t, '1001');
      await registrar(t);
      expect(find.text('El valor debe estar entre 0 y 1.000'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('una medición válida se guarda y entra al tablero', (t) async {
      await irARegistrar(t);
      await elegir<IdIndicador>(t, 'Eventos adversos evitables');
      await elegir<String>(t, 'Centro Ambulatorio Envigado');
      await escribirValor(t, '1,6');
      await registrar(t);
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();

      expect(find.text(mensajeMedicionRegistrada), findsOneWidget);
      expect(find.text('Registradas en esta sesión'), findsOneWidget);
      expect(find.textContaining('oct 2026'), findsWidgets);

      // En el detalle del indicador, la sede ya tiene su medición.
      await tocar(t, find.text('Indicadores'));
      await tocar(t, find.text('Eventos adversos evitables'));
      expect(find.text(mensajeSinMedicion), findsNothing);
      expect(find.text('8 mediciones'), findsNothing);
      await cerrarApp(t);
    });

    testWidgets('no se puede registrar la misma medición dos veces', (t) async {
      await irARegistrar(t);
      await elegir<IdIndicador>(t, 'Eventos adversos evitables');
      await elegir<String>(t, 'Centro Ambulatorio Envigado');
      await escribirValor(t, '1,6');
      await registrar(t);
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();

      await escribirValor(t, '1,7');
      await registrar(t);
      expect(find.text(mensajeMedicionRepetida), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('la medición registrada deja su evento en la auditoría', (
      t,
    ) async {
      await irARegistrar(t);
      await elegir<IdIndicador>(t, 'Eventos adversos evitables');
      await elegir<String>(t, 'Centro Ambulatorio Envigado');
      await escribirValor(t, '1,6');
      await registrar(t);
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();

      await tocar(t, find.byTooltip('Menú de usuario'));
      await tocar(t, find.text('Mi perfil'));
      await tocar(t, find.text('Cerrar sesión'));
      await tocar(t, find.text('Auditor'));
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      // 8 del Figma + ingreso de Andrés + medición + ingreso de Marcela.
      await t.ensureVisible(find.text('11 eventos'));
      expect(find.text('11 eventos'), findsOneWidget);
      expect(find.text('Medición de indicador'), findsWidgets);
      await cerrarApp(t);
    });

    testWidgets('se ve sin desbordes en celular y en escritorio', (t) async {
      await irARegistrar(t);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
      await entrarComoAdministrativo(t, tamano: escritorio);
      await tocar(t, find.text('Mediciones'));
      expect(find.text('Registrar medición mensual'), findsOneWidget);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });
  });

  group('Buscar pacientes y datos básicos (F-01, F-03, RF-01, RF-03)', () {
    Future<void> irABuscar(WidgetTester t) async {
      await entrarComoAdministrativo(t);
      await tocar(t, find.text('Buscar'));
    }

    Future<void> buscar(WidgetTester t, String texto) async {
      await t.enterText(find.byType(TextField).first, texto);
      await t.pump();
    }

    testWidgets('el administrativo ve la sección Buscar y no Pacientes', (
      t,
    ) async {
      await entrarComoAdministrativo(t);
      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Mediciones'), findsOneWidget);
      expect(find.text('Pacientes'), findsNothing);
      await cerrarApp(t);
    });

    testWidgets('con menos de 3 caracteres avisa y no busca', (t) async {
      await irABuscar(t);
      await buscar(t, 'he');
      expect(find.text(mensajeBusquedaCorta), findsOneWidget);
      // No hay contador de resultados todavía.
      expect(find.textContaining(RegExp(r'^\d+ pacientes?$')), findsNothing);
      await cerrarApp(t);
    });

    testWidgets(
      'busca por nombre sin tildes y muestra solo nombre y documento',
      (t) async {
        await irABuscar(t);
        await buscar(t, 'hernan');
        expect(find.text('1 paciente'), findsOneWidget);
        expect(find.text('Hernán Darío Quintero Salcedo'), findsOneWidget);
        expect(find.text('CC 72105531'), findsOneWidget);
        // Ningún dato clínico en el resultado.
        expect(find.textContaining('Hospitalización'), findsNothing);
        expect(find.byType(AnilloRiesgo), findsNothing);
        await cerrarApp(t);
      },
    );

    testWidgets(
      'busca por documento y encuentra a quien no tiene alta reciente',
      (t) async {
        await irABuscar(t);
        await buscar(t, '43217655');
        expect(find.text('Gloria Patricia Mejía Londoño'), findsOneWidget);
        await cerrarApp(t);
      },
    );

    testWidgets('sin resultados lo dice y el contador queda en 0', (t) async {
      await irABuscar(t);
      await buscar(t, 'zzzzzz');
      expect(find.text(mensajeSinResultados), findsOneWidget);
      expect(find.text('0 pacientes'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('los resultados van de la A a la Z', (t) async {
      await irABuscar(t);
      await buscar(t, 'mar');
      final nombres = find.textContaining(RegExp(r'^(María|Luz Marina)'));
      expect(nombres, findsWidgets);
      final primero = t.getTopLeft(find.text('Luz Marina Cardona Arias')).dy;
      final segundo = t
          .getTopLeft(find.text('María Fernanda Rojas Benítez'))
          .dy;
      expect(primero, lessThan(segundo));
      await cerrarApp(t);
    });

    testWidgets(
      'el administrativo declara Revisión de calidad y ve los datos',
      (t) async {
        await irABuscar(t);
        await buscar(t, 'hernan');
        await tocar(t, find.text('Hernán Darío Quintero Salcedo'));

        expect(find.text('ANTES DE VER LOS DATOS'), findsOneWidget);
        expect(find.text('Revisión de calidad'), findsOneWidget);
        expect(find.text('Seguimiento de reingreso'), findsNothing);
        // El pop-up no le muestra el riesgo.
        expect(find.byType(AnilloRiesgo), findsNothing);

        await tocar(t, find.text('Revisión de calidad'));
        await tocar(t, find.text('Ver datos básicos'));
        expect(find.text('DATOS BÁSICOS'), findsOneWidget);
        expect(find.text('Teléfono'.toUpperCase()), findsOneWidget);
        expect(find.text('312 555 0103'), findsOneWidget);
        // Sin historia, atenciones, riesgo ni identificadores de origen.
        expect(find.text('HISTORIA CLÍNICA UNIFICADA'), findsNothing);
        expect(find.text('Atenciones'), findsNothing);
        expect(find.text('Riesgo de reingreso'), findsNothing);
        expect(find.textContaining('HCE '), findsNothing);
        expect(find.byType(AnilloRiesgo), findsNothing);
        await cerrarApp(t);
      },
    );

    testWidgets('sin elegir el propósito pide elegirlo', (t) async {
      await irABuscar(t);
      await buscar(t, 'hernan');
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      await tocar(t, find.text('Ver datos básicos'));
      expect(find.text(mensajeElijaProposito), findsOneWidget);
      expect(find.text('DATOS BÁSICOS'), findsNothing);
      await cerrarApp(t);
    });

    testWidgets('Atrás vuelve de los datos básicos a la búsqueda', (t) async {
      await irABuscar(t);
      await buscar(t, 'hernan');
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      await tocar(t, find.text('Revisión de calidad'));
      await tocar(t, find.text('Ver datos básicos'));
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('DATOS BÁSICOS'), findsNothing);
      expect(find.text('Buscar pacientes'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('abrir los datos básicos deja su evento en la auditoría', (
      t,
    ) async {
      await irABuscar(t);
      await buscar(t, 'hernan');
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      await tocar(t, find.text('Revisión de calidad'));
      await tocar(t, find.text('Ver datos básicos'));

      await tocar(t, find.byTooltip('Menú de usuario'));
      await tocar(t, find.text('Mi perfil'));
      await tocar(t, find.text('Cerrar sesión'));
      await tocar(t, find.text('Auditor'));
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      // 8 del Figma + ingreso de Andrés + datos básicos + ingreso de Marcela.
      await t.ensureVisible(find.text('11 eventos'));
      expect(find.text('11 eventos'), findsOneWidget);
      expect(find.text('Datos básicos'), findsWidgets);
      await cerrarApp(t);
    });
  });

  group('El médico también busca (F-01, F-02, F-05)', () {
    testWidgets('encuentra a un paciente fuera de las altas recientes', (
      t,
    ) async {
      await entrarComoMedica(t);
      await tocar(t, find.text('Buscar'));
      await t.enterText(find.byType(TextField).first, 'gloria');
      await t.pump();
      expect(find.text('Gloria Patricia Mejía Londoño'), findsOneWidget);
      expect(find.text('1 paciente'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('sin relación se rechaza y con Urgencia abre la historia', (
      t,
    ) async {
      await entrarComoMedica(t);
      await tocar(t, find.text('Buscar'));
      await t.enterText(find.byType(TextField).first, 'gloria');
      await t.pump();
      await tocar(t, find.text('Gloria Patricia Mejía Londoño'));
      expect(find.text('ANTES DE ABRIR LA HISTORIA'), findsOneWidget);
      await tocar(t, find.text('Atención del paciente'));
      await tocar(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);

      await tocar(t, find.text('Declarar Urgencia'));
      // El pop-up vuelve sin propósito elegido: se elige Urgencia (F-16).
      await tocar(t, find.text('Urgencia (acceso de emergencia)'));
      await tocar(t, find.text('Abrir historia clínica'));
      expect(find.text('HISTORIA CLÍNICA UNIFICADA'), findsOneWidget);
      expect(find.text(avisoAccesoEmergencia), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('el médico no ve la sección Mediciones', (t) async {
      await entrarComoMedica(t);
      expect(find.text('Mediciones'), findsNothing);
      expect(find.text('Buscar'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('el auditor no tiene búsqueda de pacientes', (t) async {
      await abrirApp(t);
      await tocar(t, find.text('Auditor'));
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      expect(find.text('Buscar'), findsNothing);
      await cerrarApp(t);
    });
  });
}
