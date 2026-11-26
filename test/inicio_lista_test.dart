import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/pacientes.dart';

import 'ayudas.dart';

class EmptyPatients implements PatientService {
  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async =>
      const [];
}

Future<void> _open(WidgetTester t, {PatientService? patients}) async {
  final datos = DatosSimulados.porDefecto;
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: datos, patients: patients, reloj: () => datos.hoy),
    ),
  );
  await entrarMedica(t, proposito: 'Seguimiento de reingreso');
}

void main() {
  group('El Inicio es la lista de altas recientes (F-06)', () {
    testWidgets('CA-1: las 8 altas, de mayor a menor riesgo, con su contador', (
      t,
    ) async {
      await _open(t);
      final datos = DatosSimulados.porDefecto;
      final esperadas = pacientesConAltaReciente(datos.pacientes, datos.hoy);
      final tarjetas = t
          .widgetList<TarjetaPaciente>(find.byType(TarjetaPaciente))
          .map((w) => w.paciente.nombre)
          .toList();
      expect(tarjetas, esperadas.map((p) => p.nombre).toList());
      expect(tarjetas, hasLength(8));
      expect(find.text('8 pacientes'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-7: sin altas se ve el mensaje de A1 y "0 pacientes"', (
      t,
    ) async {
      await _open(t, patients: EmptyPatients());
      expect(find.text(mensajeSinAltas), findsOneWidget);
      expect(find.text('0 pacientes'), findsOneWidget);
      expect(find.byType(TarjetaPaciente), findsNothing);

      await tocarAyuda(t, find.text('Pacientes').last);
      expect(find.text(mensajeSinAltas), findsOneWidget);
      expect(find.text('0 pacientes'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });
}
