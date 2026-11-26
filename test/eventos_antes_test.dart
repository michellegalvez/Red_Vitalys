import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/pages/registrar_medicion_page.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';

import 'ayudas.dart';

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

const _falla = 'No se pudo completar la acción';
const _jorge = 'Jorge Eliécer Pardo Villamizar';

Future<FlakyAudit> _open(WidgetTester t) async {
  final datos = DatosSimulados.porDefecto;
  final audit = FlakyAudit();
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: datos, auditoria: audit, reloj: () => datos.hoy),
    ),
  );
  return audit;
}

int _count(FlakyAudit audit, RecursoAuditoria resource) =>
    audit.saved.where((e) => e.recurso == resource).length;

Future<void> _openJorge(WidgetTester t) async {
  await tocarAyuda(t, find.text('Ver todos →'));
  await tocarAyuda(t, find.text(_jorge));
  await tocarAyuda(t, find.text('Atención del paciente'));
  await tocarAyuda(t, find.text('Abrir historia clínica'));
}

void main() {
  group(
    'Sin evento guardado no se muestra ni se guarda nada (F-20, AD-07)',
    () {
      testWidgets('F-06: la lista no se abre y al reintentar sí', (t) async {
        final audit = await _open(t);
        await entrarMedica(t);
        audit.fails = true;
        await tocarAyuda(t, find.text('Seguimiento de reingreso'));
        await tocarAyuda(t, find.text('Ver pacientes'));
        expect(find.text(_falla), findsOneWidget);
        expect(find.text('Ver pacientes'), findsOneWidget);
        expect(find.text('Ver todos →'), findsNothing);
        expect(_count(audit, RecursoAuditoria.pacientesAltaReciente), 0);

        audit.fails = false;
        await tocarAyuda(t, find.text('Ver pacientes'));
        expect(find.text('Ver todos →'), findsOneWidget);
        expect(_count(audit, RecursoAuditoria.pacientesAltaReciente), 1);
        await cerrarAppAyuda(t);
      });

      testWidgets('F-02: la historia no se abre si no se guardan sus eventos', (
        t,
      ) async {
        final audit = await _open(t);
        await entrarMedica(t, proposito: 'Seguimiento de reingreso');
        audit.fails = true;
        await _openJorge(t);
        expect(find.text(_falla), findsOneWidget);
        expect(find.text('Abrir historia clínica'), findsOneWidget);
        expect(find.text('Registrar atención'), findsNothing);
        expect(_count(audit, RecursoAuditoria.historiaClinica), 0);

        audit.fails = false;
        await tocarAyuda(t, find.text('Reintentar'));
        expect(find.text(_falla), findsNothing);
        expect(_count(audit, RecursoAuditoria.historiaClinica), 1);
        expect(_count(audit, RecursoAuditoria.riesgoReingreso), 1);
        await cerrarAppAyuda(t);
      });

      testWidgets('F-04: la atención no se guarda sin su evento', (t) async {
        final audit = await _open(t);
        await entrarMedica(t, proposito: 'Seguimiento de reingreso');
        await _openJorge(t);
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
        audit.fails = true;
        await tocarAyuda(
          t,
          find.widgetWithText(BotonVitalys, 'Guardar atención'),
        );
        expect(find.text(_falla), findsOneWidget);
        expect(
          find.text('Atención registrada en la historia unificada'),
          findsNothing,
        );
        expect(_count(audit, RecursoAuditoria.atencion), 0);
        await cerrarAppAyuda(t);
      });

      testWidgets('F-12: la medición no se guarda sin su evento', (t) async {
        final audit = await _open(t);
        await entrarSedeUnica(t, 'Administrativo');
        await tocarAyuda(t, find.text('Mediciones'));
        await tocarAyuda(t, find.byType(DropdownButtonFormField<IdIndicador>));
        await tocarAyuda(t, find.text('Eventos adversos evitables').last);
        await tocarAyuda(t, find.byType(DropdownButtonFormField<String>));
        await tocarAyuda(t, find.text('Centro Ambulatorio Envigado').last);
        await t.enterText(find.byType(TextField).first, '1,6');
        await t.pump();
        audit.fails = true;
        await tocarAyuda(
          t,
          find.widgetWithText(BotonVitalys, 'Registrar medición'),
        );
        expect(find.text(_falla), findsOneWidget);
        expect(find.text(mensajeMedicionRegistrada), findsNothing);
        expect(_count(audit, RecursoAuditoria.medicionIndicador), 0);
        await cerrarAppAyuda(t);
      });

      testWidgets('un rechazo sí se muestra aunque su evento no se guarde', (
        t,
      ) async {
        final audit = await _open(t);
        await entrarMedica(t, proposito: 'Seguimiento de reingreso');
        audit.fails = true;
        await tocarAyuda(t, find.text('Ver todos →'));
        await tocarAyuda(t, find.text('Hernán Darío Quintero Salcedo'));
        await tocarAyuda(t, find.text('Atención del paciente'));
        await tocarAyuda(t, find.text('Abrir historia clínica'));
        expect(find.text('No puede abrir este paciente'), findsOneWidget);
        await cerrarAppAyuda(t);
      });
    },
  );
}
