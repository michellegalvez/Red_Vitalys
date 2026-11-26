import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/screens/secciones.dart';
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

final _datos = DatosSimulados.porDefecto;
final _hoy = _datos.hoy;
Usuario _user(String email) => _datos.usuarioPorCorreo(email)!;
PacienteEnSeguimiento _patient(String id) =>
    _datos.pacientes.firstWhere((p) => p.id == id);

PacienteEnSeguimiento _with({
  required String site,
  required int daysAgo,
  List<String> doctors = const [],
}) => PacienteEnSeguimiento(
  id: 'x',
  nombre: 'Prueba',
  iniciales: 'PR',
  edad: 40,
  sexo: 'F',
  tipoDocumento: 'CC',
  numeroDocumento: '123456',
  sedeAltaId: site,
  tipoAtencion: TipoAtencion.hospitalizacion,
  fechaAlta: _hoy.subtract(Duration(days: daysAgo)),
  diasEstancia: 2,
  riesgo: 50,
  medicosConAtencion: doctors,
);

Future<RecordingAudit> _open(WidgetTester t) async {
  final audit = RecordingAudit();
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: _datos, auditoria: audit, reloj: () => _hoy),
    ),
  );
  return audit;
}

void main() {
  const access = AccessControlService();
  final camila = _user('camila.martinez@vitalys.co');
  final andres = _user('andres.ruiz@vitalys.co');
  final marcela = _user('marcela.ospina@vitalys.co');

  group('Relación médico-paciente (T-16 · F-05)', () {
    test('CA-1: alta de hace 10 días en una sede suya da relación', () {
      expect(
        access.hasRelationship(camila, _with(site: 's1', daysAgo: 10), _hoy),
        isTrue,
      );
    });

    test('CA-2: alta reciente en otra sede, sin atención suya, no', () {
      expect(
        access.hasRelationship(camila, _with(site: 's5', daysAgo: 5), _hoy),
        isFalse,
      );
    });

    test('CA-3: un alta de hace 40 días en su sede ya no da relación', () {
      expect(
        access.hasRelationship(camila, _with(site: 's1', daysAgo: 40), _hoy),
        isFalse,
      );
    });

    test('CA-4: una atención suya con Atención del paciente sí, aunque sea '
        'vieja y de otra sede', () {
      final patient = _with(site: 's5', daysAgo: 60, doctors: [camila.id]);
      expect(access.hasRelationship(camila, patient, _hoy), isTrue);
    });

    test('CA-5: sin relación se rechaza con su causa', () {
      expect(
        access.decideConsultation(
          user: camila,
          patient: _with(site: 's5', daysAgo: 5),
          purpose: Proposito.atencionPaciente,
          today: _hoy,
        ),
        ResultadoConsulta.rechazoRelacion,
      );
      expect(rechazoRelacion, contains('Urgencia'));
    });

    test('CA-6: con Urgencia se abre aunque no haya relación', () {
      expect(
        access.decideConsultation(
          user: camila,
          patient: _with(site: 's5', daysAgo: 5),
          purpose: Proposito.urgencia,
          today: _hoy,
        ),
        ResultadoConsulta.permitido,
      );
    });

    test('Urgencia no deja relación para la siguiente consulta', () {
      final hernan = _patient('p3');
      expect(hernan.medicosConAtencion, isNot(contains(camila.id)));
      expect(access.hasRelationship(camila, hernan, _hoy), isFalse);
    });

    test('el administrativo y el auditor nunca tienen relación', () {
      final own = _with(site: 's2', daysAgo: 3);
      expect(access.hasRelationship(andres, own, _hoy), isFalse);
      expect(access.hasRelationship(marcela, own, _hoy), isFalse);
    });
  });

  group('Emergencia (T-12 · F-17)', () {
    test(
      'CA-8: los datos simulados traen al menos un evento de emergencia',
      () {
        expect(_datos.eventos.where((e) => e.esEmergencia), isNotEmpty);
      },
    );

    test('CA-9: registrar con Urgencia sin relación se permite', () {
      expect(
        access.decideConsultation(
          user: camila,
          patient: _patient('p3'),
          purpose: Proposito.urgencia,
          today: _hoy,
          registering: true,
        ),
        ResultadoConsulta.permitido,
      );
    });

    test('CA-6: un administrativo con Urgencia queda rechazado', () {
      expect(
        access.decideConsultation(
          user: andres,
          patient: _patient('p3'),
          purpose: Proposito.urgencia,
          today: _hoy,
        ),
        ResultadoConsulta.rechazoProposito,
      );
    });

    testWidgets('CA-1, CA-2 y CA-7: sin relación y con Urgencia ve la '
        'historia con el aviso, sin justificación, y el evento se guarda', (
      t,
    ) async {
      final audit = await _open(t);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      await tocarAyuda(t, find.text('Ver todos →'));
      await tocarAyuda(t, find.text(_patient('p3').nombre));
      await tocarAyuda(t, find.text('Urgencia (acceso de emergencia)'));
      expect(find.textContaining('ustifica'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(avisoAccesoEmergencia), findsWidgets);
      expect(find.text(rechazoRelacion), findsNothing);

      final history = audit.saved.firstWhere(
        (e) => e.recurso == RecursoAuditoria.historiaClinica,
      );
      expect(history.accion, AccionAuditoria.consultar);
      expect(history.pacienteId, 'p3');
      expect(history.proposito, Proposito.urgencia);
      expect(history.resultado, ResultadoAuditoria.permitido);
      expect(history.esEmergencia, isTrue);
      await cerrarAppAyuda(t);
    });
  });

  group('Tabla de permisos (T-17 · F-18)', () {
    test('CA-10: cada sección que ve un rol está permitida en la tabla', () {
      for (final role in Rol.values) {
        for (final section in seccionesDe(role)) {
          expect(
            access.canDo(role, accionDeSeccion(section)),
            isTrue,
            reason: '$role $section',
          );
        }
      }
    });

    test('CA-1 a CA-3: la tabla de cada rol', () {
      expect(
        access.canDo(Rol.administrativo, AccionPermitida.registrarAtencion),
        isFalse,
      );
      expect(
        access.canDo(Rol.auditor, AccionPermitida.buscarPaciente),
        isFalse,
      );
      expect(
        access.canDo(Rol.medico, AccionPermitida.registrarMedicion),
        isFalse,
      );
      expect(access.canDo(Rol.medico, AccionPermitida.verAuditoria), isFalse);
      for (final role in Rol.values) {
        expect(access.canDo(role, AccionPermitida.verPerfil), isTrue);
        expect(access.canDo(role, AccionPermitida.verTablero), isTrue);
      }
    });

    for (final perfil in ['Administrativo', 'Auditor']) {
      testWidgets('CA-4 y CA-11: el $perfil abre el tablero y el perfil sin '
          'evento, y lo No incluido se rechaza con evento', (t) async {
        final audit = await _open(t);
        await entrarSedeUnica(t, perfil);
        final before = audit.saved.length;
        await tocarAyuda(t, find.text('Indicadores').last);
        await tocarAyuda(t, find.byTooltip('Menú de usuario'));
        await tocarAyuda(t, find.text('Mi perfil'));
        expect(audit.saved.length, before);

        final allowed = estadoApp(t).intentarAcceso(
          AccionPermitida.registrarAtencion,
          RecursoAuditoria.atencion,
        ) as bool;
        await t.pumpAndSettle(const Duration(seconds: 6));
        expect(allowed, isFalse);
        final denied = audit.saved.last;
        expect(denied.resultado, ResultadoAuditoria.denegado);
        expect(denied.recurso, RecursoAuditoria.atencion);
        expect(denied.pacienteId, isNull);
        await cerrarAppAyuda(t);
      });
    }
  });
}
