import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/history_service.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

class FakeHistory implements HistoryService {
  var fails = false;
  var calls = 0;

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
}
