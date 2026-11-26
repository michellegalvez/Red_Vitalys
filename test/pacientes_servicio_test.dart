import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/patient_memory.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

class FakePatients implements PatientService {
  FakePatients(this.patients, {this.fails = false});

  final List<PacienteEnSeguimiento> patients;
  bool fails;
  Completer<void>? hold;
  final todays = <DateTime>[];

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async {
    todays.add(today);
    await hold?.future;
    if (fails) throw StateError('sin red');
    return patients;
  }
}

final _datos = DatosSimulados.porDefecto;

PacienteEnSeguimiento _patient(int risk, DateTime discharge, String name) =>
    PacienteEnSeguimiento(
      id: 'x$risk',
      nombre: name,
      iniciales: 'ZZ',
      edad: 50,
      sexo: 'F',
      tipoDocumento: 'CC',
      numeroDocumento: '1000$risk',
      sedeAltaId: 's1',
      tipoAtencion: TipoAtencion.hospitalizacion,
      fechaAlta: discharge,
      diasEstancia: 2,
      riesgo: risk,
    );

Future<void> _enterAsCamila(WidgetTester t, PatientService patients) async {
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: _datos,
        patients: patients,
        reloj: () => _datos.hoy,
      ),
    ),
  );
  await escribirAyuda(t, 'camila.martinez@vitalys.co', claveAyuda);
  await tocarAyuda(t, find.text('Ingresar'));
  await tocarAyuda(t, find.byType(DropdownButtonFormField<String>));
  await tocarAyuda(t, find.text('Clínica Vitalys Cali Norte').last);
  await tocarAyuda(t, find.text('Confirmar sede'));
}

void main() {
  group('PatientMemory (T-13)', () {
    test('entrega los pacientes simulados', () async {
      final patients = await PatientMemory(_datos).listPatients(_datos.hoy);
      expect(patients.length, _datos.pacientes.length);
      expect(PatientMemory(_datos).isRemote, isFalse);
    });

    test('las altas recientes salen por riesgo, alta y nombre', () async {
      final today = DateTime(2026, 11, 6);
      final list = pacientesConAltaReciente([
        _patient(69, DateTime(2026, 10, 20), 'Beatriz'),
        _patient(70, DateTime(2026, 10, 20), 'Zoe'),
        _patient(70, DateTime(2026, 10, 20), 'Ana'),
        _patient(95, DateTime(2026, 10, 6), 'Vieja'),
      ], today);
      expect(list.map((p) => p.nombre), ['Ana', 'Zoe', 'Beatriz']);
      expect(conAlerta(list[0].riesgo), isTrue);
      expect(conAlerta(list[2].riesgo), isFalse);
    });
  });

  group('La Screen con el servicio de pacientes (T-13)', () {
    testWidgets('al abrir la sesión pide los pacientes con la fecha de hoy', (
      t,
    ) async {
      final fake = FakePatients([_patient(88, DateTime(2026, 10, 30), 'Zoe')]);
      await _enterAsCamila(t, fake);
      expect(fake.todays, [_datos.hoy]);
      await tocarAyuda(t, find.text('Seguimiento de reingreso'));
      await tocarAyuda(t, find.text('Ver pacientes'));
      expect(find.textContaining('Zoe'), findsWidgets);
      expect(find.textContaining('Pardo'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('T-15 CA-8: si falla, la lista avisa y Reintentar la carga', (
      t,
    ) async {
      final fake = FakePatients([
        _patient(88, DateTime(2026, 10, 30), 'Zoe'),
      ], fails: true);
      await _enterAsCamila(t, fake);
      await tocarAyuda(t, find.text('Seguimiento de reingreso'));
      await tocarAyuda(t, find.text('Ver pacientes'));
      expect(find.text('No se pudo cargar la lista'), findsOneWidget);
      await tocarAyuda(t, find.text('Pacientes'));
      expect(find.text('Pacientes con alta reciente'), findsOneWidget);
      expect(find.text('No se pudo cargar la lista'), findsOneWidget);
      expect(find.textContaining('Zoe'), findsNothing);

      fake.fails = false;
      await tocarAyuda(t, find.text('Reintentar'));
      expect(fake.todays.length, 2);
      expect(find.text('No se pudo cargar la lista'), findsNothing);
      expect(find.textContaining('Zoe'), findsWidgets);
      expect(find.text('1 paciente'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('T-15: mientras el servicio responde se ve la carga', (
      t,
    ) async {
      final fake = FakePatients([_patient(88, DateTime(2026, 10, 30), 'Zoe')])
        ..hold = Completer<void>();
      await _enterAsCamila(t, fake);
      await tocarAyuda(t, find.text('Seguimiento de reingreso'));
      await t.tap(find.text('Ver pacientes'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Cargando pacientes…'), findsOneWidget);

      fake.hold!.complete();
      await t.pumpAndSettle();
      expect(find.text('Cargando pacientes…'), findsNothing);
      expect(find.textContaining('Zoe'), findsWidgets);
      await cerrarAppAyuda(t);
    });
  });
}
