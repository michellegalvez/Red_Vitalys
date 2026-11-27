import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/audit_event_not_saved.dart';
import 'package:red_vitalys/services/history_service.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';

import 'ayudas.dart';

// Lo que pedía la tarea T-04 de Gabriela, sobre el código de main: la
// historia solo aplica la última respuesta, y si no se puede guardar una
// atención se conserva lo escrito y no se puede salir a medias.

const _jorge = 'Jorge Eliécer Pardo Villamizar';
const _falla = 'No se pudo completar la acción';
const _fallaGuardar = 'No se pudo registrar la atención';

class QueuedHistory implements HistoryService {
  var riskFails = false;
  var riskCalls = 0;
  final loads = <Completer<Patient>>[];
  Completer<void>? saving;
  var failsSaving = false;
  var failsEvent = false;
  final saved = <NuevaAtencion>[];

  @override
  bool get isRemote => true;

  @override
  Future<Patient> historyOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  }) {
    final load = Completer<Patient>();
    loads.add(load);
    return load.future;
  }

  @override
  Future<ReadmissionRisk?> riskOf(
    PacienteEnSeguimiento patient, {
    required String siteName,
    required DateTime today,
  }) async {
    riskCalls++;
    if (riskFails) throw StateError('sin red');
    return historiaDe(patient, sedeAlta: siteName, hoy: today).readmissionRisk;
  }

  @override
  Future<String?> addEncounter(
    PacienteEnSeguimiento patient,
    NuevaAtencion encounter, {
    required String siteName,
    required Proposito purpose,
    required String? sessionSiteName,
  }) async {
    await saving?.future;
    if (failsEvent) throw const AuditEventNotSaved();
    if (failsSaving) throw StateError('sin red');
    saved.add(encounter);

    return null;
  }
}

class FlakyAudit implements AuditoriaRepositorio {
  var fails = false;
  final saved = <EventoAuditoria>[];

  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async {
    if (fails) throw StateError('sin red');
    saved.add(evento);
  }

  @override
  Future<List<EventoAuditoria>> listar() async => saved.reversed.toList();
}

final _datos = DatosSimulados.porDefecto;

Patient _historyOf(String site) {
  final jorge = _datos.pacientes.firstWhere((p) => p.nombre == _jorge);
  return historiaDe(jorge, sedeAlta: site, hoy: _datos.hoy);
}

Future<void> _open(
  WidgetTester t,
  QueuedHistory history, {
  AuditoriaRepositorio? audit,
}) async {
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: _datos,
        history: history,
        auditoria: audit,
        reloj: () => _datos.hoy,
      ),
    ),
  );
  await entrarMedica(t, proposito: 'Seguimiento de reingreso');
  await tocarAyuda(t, find.text('Ver todos →'));
}

Future<void> _openJorge(WidgetTester t) async {
  await tocarAyuda(t, find.text(_jorge));
  await tocarAyuda(t, find.text('Atención del paciente'));
  await t.tap(find.text('Abrir historia clínica'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> _fillForm(WidgetTester t) async {
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
  await tocarAyuda(t, find.text('Atención del paciente'));
  await tocarAyuda(
    t,
    find.widgetWithText(BotonVitalys, 'Registrar atención').last,
  );
  await tocarAyuda(t, find.text('Urgencias'));
  await t.enterText(find.byType(TextField).at(0), '05/11/2026');
  await t.enterText(find.byType(TextField).at(1), '06/11/2026');
  await t.pump();
}

Future<void> _tapSave(WidgetTester t) async {
  final save = find.widgetWithText(BotonVitalys, 'Guardar atención');
  await t.ensureVisible(save);
  await t.pump();
  await t.tap(save);
  await t.pump();
}

void _expectFormKept(WidgetTester t) {
  expect(find.text('Guardar atención'), findsOneWidget);
  expect(find.text('05/11/2026'), findsOneWidget);
  expect(find.text('06/11/2026'), findsOneWidget);
}

void main() {
  testWidgets('la historia solo aplica la respuesta del último pedido', (
    t,
  ) async {
    final history = QueuedHistory();
    await _open(t, history);
    await _openJorge(t);
    expect(history.loads, hasLength(1));
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    await _openJorge(t);
    expect(history.loads, hasLength(2));

    history.loads[1].complete(_historyOf('Sede nueva'));
    await t.pumpAndSettle();
    history.loads[0].completeError(StateError('respuesta vieja'));
    await t.pumpAndSettle();

    expect(find.text('No se pudo cargar la historia'), findsNothing);
    expect(find.textContaining('Sede nueva'), findsWidgets);
    await cerrarAppAyuda(t);
  });

  group('Si no se puede guardar la atención se conserva lo escrito (F-04)', () {
    testWidgets('sin el evento de auditoría no se guarda y queda lo escrito', (
      t,
    ) async {
      final history = QueuedHistory();
      final audit = FlakyAudit();
      await _open(t, history, audit: audit);
      await _openJorge(t);
      history.loads.single.complete(_historyOf('Sede de la base'));
      await t.pumpAndSettle();
      await _fillForm(t);
      history.failsEvent = true;
      await tocarAyuda(
        t,
        find.widgetWithText(BotonVitalys, 'Guardar atención'),
      );
      expect(find.text(_falla), findsOneWidget);
      expect(history.saved, isEmpty);
      _expectFormKept(t);
      await cerrarAppAyuda(t);
    });

    testWidgets('con Supabase el evento va con la atención: si el guardado '
        'falla no queda un evento suelto, ni uno por reintento', (t) async {
      final history = QueuedHistory()..failsSaving = true;
      final audit = FlakyAudit();
      await _open(t, history, audit: audit);
      await _openJorge(t);
      history.loads.single.complete(_historyOf('Sede de la base'));
      await t.pumpAndSettle();
      await _fillForm(t);
      for (var i = 0; i < 2; i++) {
        await _tapSave(t);
        await t.pumpAndSettle();
        expect(find.text(_fallaGuardar), findsOneWidget);
      }
      expect(
        audit.saved.where((e) => e.accion == AccionAuditoria.registrar),
        isEmpty,
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('si falla el guardado avisa, queda lo escrito y al '
        'reintentar se guarda', (t) async {
      final history = QueuedHistory()..failsSaving = true;
      await _open(t, history);
      await _openJorge(t);
      history.loads.single.complete(_historyOf('Sede de la base'));
      await t.pumpAndSettle();
      await _fillForm(t);
      await tocarAyuda(
        t,
        find.widgetWithText(BotonVitalys, 'Guardar atención'),
      );
      expect(find.text(_fallaGuardar), findsOneWidget);
      _expectFormKept(t);

      history.failsSaving = false;
      await _tapSave(t);
      await t.pump();
      history.loads.last.complete(_historyOf('Sede de la base'));
      await t.pumpAndSettle();
      expect(history.saved.single.tipo, EncounterType.urgencias);
      expect(find.text('Guardar atención'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('mientras se guarda no se puede salir del formulario', (
      t,
    ) async {
      final history = QueuedHistory()
        ..saving = Completer<void>()
        ..failsSaving = true;
      await _open(t, history);
      await _openJorge(t);
      history.loads.single.complete(_historyOf('Sede de la base'));
      await t.pumpAndSettle();
      await _fillForm(t);
      await _tapSave(t);
      await t.pump();
      expect(find.text('Guardando atención…'), findsOneWidget);

      await t.tap(find.textContaining('Nueva atención').first);
      await t.pump();
      await t.binding.handlePopRoute();
      await t.pump();
      expect(find.text('Guardando atención…'), findsOneWidget);

      history.saving!.complete();
      await t.pumpAndSettle();
      expect(find.text(_fallaGuardar), findsOneWidget);
      _expectFormKept(t);
      await cerrarAppAyuda(t);
    });
  });
}
