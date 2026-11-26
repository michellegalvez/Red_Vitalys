import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/history_service.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';

import 'ayudas.dart';

class FakeHistory implements HistoryService {
  var fails = false;
  var failsSaving = false;
  var calls = 0;
  final saved = <(NuevaAtencion, Proposito, String)>[];

  @override
  bool get isRemote => true;

  @override
  Future<Patient> historyOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  }) async {
    calls++;
    if (fails) throw StateError('sin red');
    return historiaDe(patient, sedeAlta: 'Sede de la base', hoy: today);
  }

  @override
  Future<void> addEncounter(
    PacienteEnSeguimiento patient,
    NuevaAtencion encounter, {
    required String siteName,
    required Proposito purpose,
  }) async {
    if (failsSaving) throw StateError('sin red');
    saved.add((encounter, purpose, siteName));
  }
}

Future<void> _openJorge(WidgetTester t, FakeHistory history) async {
  final datos = DatosSimulados.porDefecto;
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: datos, history: history, reloj: () => datos.hoy),
    ),
  );
  await entrarMedica(t, proposito: 'Seguimiento de reingreso');
  await tocarAyuda(t, find.text('Ver todos →'));
  await tocarAyuda(t, find.text('Jorge Eliécer Pardo Villamizar'));
  await tocarAyuda(t, find.text('Atención del paciente'));
  await tocarAyuda(t, find.text('Abrir historia clínica'));
}

void main() {
  group('La historia desde el servicio (T-20 · F-02)', () {
    testWidgets('muestra lo que entrega el servicio', (t) async {
      final history = FakeHistory();
      await _openJorge(t, history);
      expect(history.calls, 1);
      expect(find.textContaining('Sede de la base'), findsWidgets);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-7: si falla avisa y Reintentar la carga', (t) async {
      final history = FakeHistory()..fails = true;
      await _openJorge(t, history);
      expect(find.text('No se pudo cargar la historia'), findsOneWidget);
      expect(find.textContaining('Sede de la base'), findsNothing);

      history.fails = false;
      await tocarAyuda(t, find.text('Reintentar'));
      expect(history.calls, 2);
      expect(find.text('No se pudo cargar la historia'), findsNothing);
      expect(find.textContaining('Sede de la base'), findsWidgets);
      await cerrarAppAyuda(t);
    });
  });

  group('Registrar una atención en el servicio (T-21 · F-04)', () {
    Future<void> register(WidgetTester t) async {
      await tocarAyuda(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar atención'),
      );
      await tocarAyuda(t, find.text('Atención del paciente'));
      await tocarAyuda(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar atención').last,
      );
      await tocarAyuda(t, find.text('Urgencias'));
      await t.enterText(find.byType(TextField).at(0), '06/11/2026');
      await t.pump();
      await tocarAyuda(
        t,
        find.widgetWithText(BotonVitalys, 'Guardar atención'),
      );
    }

    testWidgets('la atención se guarda con su sede y su propósito y la '
        'historia se vuelve a traer', (t) async {
      final history = FakeHistory();
      await _openJorge(t, history);
      await register(t);
      final (encounter, purpose, site) = history.saved.single;
      expect(encounter.tipo, EncounterType.urgencias);
      expect(purpose, Proposito.atencionPaciente);
      expect(site, isNotEmpty);
      expect(history.calls, 2);
      expect(
        find.text('Atención registrada en la historia unificada'),
        findsOneWidget,
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('si no se puede guardar avisa y no deja evento', (t) async {
      final history = FakeHistory()..failsSaving = true;
      await _openJorge(t, history);
      await register(t);
      expect(history.saved, isEmpty);
      expect(find.text('No se pudo registrar la atención'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });
}
