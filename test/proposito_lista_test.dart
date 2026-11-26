import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/access_control_service.dart';
import 'package:red_vitalys/tema/tema.dart';

import 'ayudas.dart';

class RecordingAudit implements AuditoriaRepositorio {
  final saved = <EventoAuditoria>[];

  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async => saved.add(evento);

  @override
  Future<List<EventoAuditoria>> listar() async => saved.reversed.toList();
}

const _listSubtitle =
    'Con alta en los últimos 30 días, de mayor a menor riesgo de reingreso.';

final _datos = DatosSimulados.porDefecto;
Usuario _user(String email) => _datos.usuarioPorCorreo(email)!;

Future<RecordingAudit> _open(WidgetTester t) async {
  final audit = RecordingAudit();
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: _datos, auditoria: audit, reloj: () => _datos.hoy),
    ),
  );
  return audit;
}

List<EventoAuditoria> _listEvents(RecordingAudit audit) => [
  for (final e in audit.saved)
    if (e.recurso == RecursoAuditoria.pacientesAltaReciente) e,
];

void main() {
  const access = AccessControlService();
  final camila = _user('camila.martinez@vitalys.co');
  final andres = _user('andres.ruiz@vitalys.co');
  final marcela = _user('marcela.ospina@vitalys.co');

  group('AccessControlService (T-11 · F-16)', () {
    test('CA-1 y CA-8: el médico puede declarar los 5 propósitos', () {
      expect(access.purposesFor(Rol.medico), Proposito.values);
    });

    test('CA-2: el administrativo solo Revisión de calidad', () {
      expect(access.purposesFor(Rol.administrativo), [
        Proposito.revisionCalidad,
      ]);
    });

    test('el auditor no declara ninguno', () {
      expect(access.purposesFor(Rol.auditor), isEmpty);
    });

    test('CA-10: al registrar solo Atención del paciente y Urgencia', () {
      expect(access.purposesFor(Rol.medico, registering: true), [
        Proposito.atencionPaciente,
        Proposito.urgencia,
      ]);
      expect(access.purposesFor(Rol.administrativo, registering: true), []);
    });

    test('CA-7: un propósito que el rol no tiene se rechaza', () {
      expect(
        access.decidePurpose(andres, Proposito.urgencia),
        ResultadoConsulta.rechazoProposito,
      );
      expect(
        access.decidePurpose(andres, Proposito.revisionCalidad),
        ResultadoConsulta.permitido,
      );
      expect(
        access.decidePurpose(marcela, Proposito.revisionCalidad),
        ResultadoConsulta.rechazoRol,
      );
      expect(
        access.decidePurpose(
          camila,
          Proposito.seguimientoReingreso,
          registering: true,
        ),
        ResultadoConsulta.rechazoProposito,
      );
      for (final p in Proposito.values) {
        expect(access.decidePurpose(camila, p), ResultadoConsulta.permitido);
      }
    });
  });

  group('Propósito y evento al abrir la lista (T-14 · F-06)', () {
    testWidgets('CA-12: sin propósito no se ve ningún paciente ni hay evento', (
      t,
    ) async {
      final audit = await _open(t);
      await entrarMedica(t);
      expect(find.text('Ver pacientes'), findsOneWidget);
      expect(find.text(_listSubtitle), findsNothing);
      expect(_listEvents(audit), isEmpty);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-13: el evento se guarda sin paciente y con el propósito', (
      t,
    ) async {
      final audit = await _open(t);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      final event = _listEvents(audit).single;
      expect(event.accion, AccionAuditoria.consultar);
      expect(event.resultado, ResultadoAuditoria.permitido);
      expect(event.proposito, Proposito.seguimientoReingreso);
      expect(event.pacienteId, isNull);
      expect(event.usuarioId, camila.id);
      expect(event.sedeId, 's1');
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-15: con Urgencia el evento es de emergencia', (t) async {
      final audit = await _open(t);
      await entrarMedica(t, proposito: 'Urgencia (acceso de emergencia)');
      final event = _listEvents(audit).single;
      expect(event.proposito, Proposito.urgencia);
      expect(event.resultado, ResultadoAuditoria.permitido);
      expect(eventosFiltrados([event], FiltroAuditoria.emergencia), [event]);
      await cerrarAppAyuda(t);
    });

    for (final perfil in ['Administrativo', 'Auditor']) {
      testWidgets('CA-9: el $perfil no ve la lista y queda su evento', (
        t,
      ) async {
        final audit = await _open(t);
        await entrarSedeUnica(t, perfil);
        final allowed = estadoApp(t).intentarAcceso(
          AccionPermitida.verHistoria,
          RecursoAuditoria.pacientesAltaReciente,
        ) as bool;
        await t.pumpAndSettle(const Duration(seconds: 6));
        expect(allowed, isFalse);
        expect(find.text(_listSubtitle), findsNothing);
        final event = _listEvents(audit).single;
        expect(event.accion, AccionAuditoria.consultar);
        expect(event.resultado, ResultadoAuditoria.denegado);
        expect(event.pacienteId, isNull);
        await cerrarAppAyuda(t);
      });
    }
  });
}
