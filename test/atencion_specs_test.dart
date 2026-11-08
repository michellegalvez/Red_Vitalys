import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/reglas/enmascarado.dart';
import 'package:red_vitalys/widgets/boton.dart';

import 'integracion_test.dart';

// Pruebas de los criterios de aceptación de F-02 (historia), F-04 (registro
// de una atención) y F-07 (factores del riesgo).

const _jorge = 'Jorge Eliécer Pardo Villamizar';
const _maria = 'María Fernanda Rojas Benítez';
const _guardar = 'Guardar atención';

Future<void> _abrirJorge(WidgetTester t, {Size tamano = celular}) async {
  await entrarComoMedica(t, tamano: tamano);
  await abrirPaciente(t, _jorge, 'Seguimiento de reingreso');
}

Future<void> _guardarAtencion(WidgetTester t) async {
  await tocar(t, find.widgetWithText(BotonVitalys, _guardar));
  await t.pump(const Duration(milliseconds: 500));
  await t.pumpAndSettle();
}

void main() {
  group('F-04 · Formulario de la atención', () {
    testWidgets('CA-2: tipo y fecha de hoy dejan la atención primera', (
      t,
    ) async {
      await entrarComoMedica(t);
      await abrirPaciente(t, _maria, 'Consulta de historia clínica');
      await pedirRegistro(t, 'Atención del paciente');
      await llenarAtencion(t, tipo: 'Urgencias');
      await _guardarAtencion(t);

      expect(find.text('3 registros'), findsOneWidget);
      expect(find.text('6 nov 2026'), findsOneWidget);
      expect(find.text('En curso'), findsOneWidget);
      expect(arriba(t, '6 nov 2026'), lessThan(arriba(t, 'Hospitalización')));
      expect(find.text('Cali Norte'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('CA-4: sin tipo ni fecha de inicio muestra los 2 errores', (
      t,
    ) async {
      await entrarComoMedica(t);
      await abrirPaciente(t, _maria, 'Consulta de historia clínica');
      await pedirRegistro(t, 'Atención del paciente');
      // No hay tipo elegido por defecto y la fecha de inicio está vacía.
      await tocar(t, find.widgetWithText(BotonVitalys, _guardar));
      expect(find.text('Revise estos 2 datos para continuar'), findsOneWidget);
      expect(find.text('•  Elija el tipo de atención.'), findsOneWidget);
      expect(find.text('•  Indique la fecha de inicio.'), findsOneWidget);
      expect(find.text('Sin definir'), findsOneWidget);
      expect(find.text('NUEVA ATENCIÓN'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('CA-5 y A6: fecha futura y alta anterior al inicio', (t) async {
      await entrarComoMedica(t);
      await abrirPaciente(t, _maria, 'Consulta de historia clínica');
      await pedirRegistro(t, 'Atención del paciente');

      await llenarAtencion(t, inicio: '07/11/2026');
      await tocar(t, find.widgetWithText(BotonVitalys, _guardar));
      expect(find.text('La fecha no puede ser futura'), findsOneWidget);

      await llenarAtencion(
        t,
        tipo: null,
        inicio: '10/10/2026',
        alta: '07/11/2026',
      );
      await tocar(t, find.widgetWithText(BotonVitalys, _guardar));
      expect(find.text('La fecha no puede ser futura'), findsOneWidget);

      await llenarAtencion(
        t,
        tipo: null,
        inicio: '10/10/2026',
        alta: '09/10/2026',
      );
      await tocar(t, find.widgetWithText(BotonVitalys, _guardar));
      expect(
        find.text('La fecha de alta no puede ser anterior a la de inicio'),
        findsOneWidget,
      );
      // Lo escrito se conserva.
      expect(find.text('10/10/2026'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('CA-14: Hospitalización con alta queda Finalizada, 15 d', (
      t,
    ) async {
      await _abrirJorge(t);
      expect(find.text('29 sep 2026 – 14 oct 2026'), findsOneWidget);
      await pedirRegistro(t, 'Atención del paciente');
      await llenarAtencion(
        t,
        tipo: 'Hospitalización',
        inicio: '29 sep 2026',
        alta: '14 oct 2026',
      );
      await _guardarAtencion(t);

      expect(find.text('4 registros'), findsOneWidget);
      expect(find.text('29 sep 2026 – 14 oct 2026'), findsNWidgets(2));
      expect(find.text('Finalizada'), findsNWidgets(4));
      expect(find.text('15 d'), findsNWidgets(2));
      await t.pumpWidget(const SizedBox());
    });

    test('la duración y el estado salen de las fechas', () {
      expect(duracionEnDias(DateTime(2026, 9, 29), DateTime(2026, 10, 14)), 15);
      expect(formatoEstancia(15), '15 d');
      expect(formatoEstancia(0), 'Mismo día');
      NuevaAtencion nueva(DateTime? alta) => (
        tipo: EncounterType.hospitalizacion,
        sedeId: 's1',
        inicio: DateTime(2026, 9, 29),
        alta: alta,
        destino: 'Domicilio',
      );
      final con = atencionDeFormulario(
        id: 'x',
        nueva: nueva(DateTime(2026, 10, 14)),
        sede: 'Cali Norte',
        medico: 'Dra. Camila Martínez',
      );
      expect(con.status, EncounterStatus.finalizada);
      expect(con.lengthOfStayDays, 15);
      final sin = atencionDeFormulario(
        id: 'y',
        nueva: nueva(null),
        sede: 'Cali Norte',
        medico: 'Dra. Camila Martínez',
      );
      expect(sin.status, EncounterStatus.enCurso);
      expect(sin.lengthOfStayDays, isNull);
      expect(ordenarAtenciones([con, sin]).first.id, 'x');
    });
  });

  group('F-02 · Historia', () {
    testWidgets('CA-10: la atención muestra todos sus datos', (t) async {
      await _abrirJorge(t);
      expect(find.text('Hospitalización'), findsOneWidget);
      expect(find.text('Finalizada'), findsWidgets);
      expect(find.text('Bogotá Usaquén'), findsWidgets);
      expect(find.text('29 sep 2026 – 14 oct 2026'), findsOneWidget);
      expect(find.text('15 d'), findsOneWidget);
      expect(find.text('Mismo día'), findsWidgets);
      expect(find.text('Domicilio'), findsWidgets);
      expect(find.text('Dra. Camila Martínez'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('CA-12: el documento va enmascarado hasta Mostrar documentos', (
      t,
    ) async {
      await _abrirJorge(t);
      expect(find.text('CC ··· 7654'), findsOneWidget);
      expect(find.text('CC 79457654'), findsNothing);
      expect(find.text('HCE-457654'), findsNothing);
      await tocar(t, find.text('Mostrar documentos'));
      expect(find.text('CC 79457654'), findsOneWidget);
      expect(find.text('HCE-457654'), findsOneWidget);
      expect(find.text('Ocultar documentos'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('muestra dirección y teléfono, y sin etiqueta SIN ALERTA', (
      t,
    ) async {
      await _abrirJorge(t);
      expect(find.text('Dirección'.toUpperCase()), findsOneWidget);
      expect(find.text('Cra 24 # 5-60, Cali'), findsOneWidget);
      expect(find.text('SIN ALERTA'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    test('el enmascarado deja los últimos 4', () {
      expect(documentoEnmascarado('CC', '79457654'), 'CC ··· 7654');
      expect(identificadorEnmascarado('HCE-457654'), 'HCE-···7654');
    });

    for (final (nombre, tamano) in [
      ('celular', celular),
      ('escritorio', escritorio),
    ]) {
      testWidgets('la historia y el formulario con errores caben en $nombre', (
        t,
      ) async {
        await _abrirJorge(t, tamano: tamano);
        await tocar(t, find.text('Mostrar documentos'));
        await tocar(t, find.text('Cómo se calcula'));
        expect(t.takeException(), isNull);
        await pedirRegistro(t, 'Atención del paciente');
        await tocar(t, find.widgetWithText(BotonVitalys, _guardar));
        await llenarAtencion(t, inicio: '07/11/2026', alta: '01/01/2026');
        await tocar(t, find.widgetWithText(BotonVitalys, _guardar));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }
  });

  group('F-07 · Factores del riesgo', () {
    ReadmissionRisk riesgo(int score, List<int> puntos) => ReadmissionRisk(
      score: score,
      calculatedDate: DateTime(2026, 11, 1),
      periodDescription: '',
      factors: [
        for (final (i, p) in puntos.indexed) RiskFactor(name: 'F$i', points: p),
      ],
    );

    test('CA-3: se ordenan por magnitud, sin importar el signo', () {
      final r = riesgo(50, [3, -12, 10]);
      expect([for (final f in r.orderedFactors) f.points], [-12, 10, 3]);
    });

    test('con la misma magnitud va primero el que sube', () {
      final r = riesgo(50, [-5, 5, 2]);
      expect([for (final f in r.orderedFactors) f.points], [5, -5, 2]);
    });

    test('CA-9: la base es el puntaje menos la suma de los factores', () {
      expect(riesgo(91, [20, 16, 14, 7, 5, -8]).basePoints, 37);
    });

    testWidgets('CA-9 y CA-10: la base y Cómo se calcula', (t) async {
      await _abrirJorge(t);
      expect(find.text('Base del modelo: 37 puntos'), findsOneWidget);
      expect(find.textContaining('son simulados'), findsNothing);
      await tocar(t, find.text('Cómo se calcula'));
      expect(find.textContaining('son simulados'), findsOneWidget);
      expect(find.textContaining('La app no los calcula'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });
}
