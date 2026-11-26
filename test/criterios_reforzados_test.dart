import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/pages/datos_basicos_page.dart';
import 'package:red_vitalys/pages/indicadores_page.dart';
import 'package:red_vitalys/pages/perfil_page.dart';
import 'package:red_vitalys/pages/proposito_lista_page.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/proposito.dart';

import 'ayudas.dart';

// Criterios que tenían una prueba débil o ninguna (revisión del 26 nov): cada
// prueba mira la pantalla y el evento que se guarda, no solo la decisión.

class RecordingAudit implements AuditoriaRepositorio {
  final saved = <EventoAuditoria>[];

  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async => saved.add(evento);

  @override
  Future<List<EventoAuditoria>> listar() async => saved.reversed.toList();
}

class ListedPatients implements PatientService {
  ListedPatients(this.patients);

  final List<PacienteEnSeguimiento> patients;

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async =>
      patients;
}

final _datos = DatosSimulados.porDefecto;
final _hoy = DateTime(_datos.hoy.year, _datos.hoy.month, _datos.hoy.day);
const _seguimiento = 'Seguimiento de reingreso';
const _urgencia = 'Urgencia (acceso de emergencia)';
const _jorge = 'Jorge Eliécer Pardo Villamizar';
const _hernan = 'Hernán Darío Quintero Salcedo';

PacienteEnSeguimiento _patient(
  String id,
  String name,
  int risk,
  int daysAgo, {
  String site = 's1',
}) => PacienteEnSeguimiento(
  id: id,
  nombre: name,
  iniciales: 'PR',
  edad: 50,
  sexo: 'F',
  tipoDocumento: 'CC',
  numeroDocumento: '9900$risk$daysAgo',
  sedeAltaId: site,
  tipoAtencion: TipoAtencion.hospitalizacion,
  fechaAlta: _hoy.subtract(Duration(days: daysAgo)),
  diasEstancia: 2,
  riesgo: risk,
);

Future<RecordingAudit> _open(
  WidgetTester t, {
  PatientService? patients,
  DateTime Function()? reloj,
}) async {
  final audit = RecordingAudit();
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: _datos,
        auditoria: audit,
        patients: patients,
        reloj: reloj ?? () => _datos.hoy,
      ),
    ),
  );
  return audit;
}

List<EventoAuditoria> _of(RecordingAudit audit, RecursoAuditoria resource) => [
  for (final e in audit.saved)
    if (e.recurso == resource) e,
];

Future<void> _signIn(WidgetTester t, String email, String password) async {
  await escribirAyuda(t, email, password);
  await tocarAyuda(t, find.text('Ingresar'));
}

Future<void> _openPatient(WidgetTester t, String name, String purpose) async {
  await tocarAyuda(t, find.text('Ver todos →'));
  await tocarAyuda(t, find.text(name));
  await tocarAyuda(t, find.text(purpose));
  await tocarAyuda(t, find.text('Abrir historia clínica'));
}

Future<void> _registerEncounter(WidgetTester t, String purpose) async {
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
  await tocarAyuda(t, find.text(purpose));
  await tocarAyuda(
    t,
    find.widgetWithText(BotonVitalys, 'Registrar atención').last,
  );
  await tocarAyuda(t, find.text('Urgencias'));
  await t.enterText(find.byType(TextField).at(0), '06/11/2026');
  await t.pump();
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Guardar atención'));
}

Finder _cardOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(TarjetaPaciente));

void main() {
  group('F-06 · alerta y ventana de 30 días en la pantalla', () {
    testWidgets('CA-2, CA-3 y CA-4: alerta con 70, sin alerta con 69 y fuera '
        'el alta de hace 31 días', (t) async {
      await _open(
        t,
        patients: ListedPatients([
          _patient('a', 'Paciente Setenta', 70, 10),
          _patient('b', 'Paciente Sesenta y nueve', 69, 10),
          _patient('c', 'Paciente Treinta días', 40, 30),
          _patient('d', 'Paciente Treinta y un días', 95, 31),
        ]),
      );
      await entrarMedica(t, proposito: _seguimiento);
      expect(
        find.descendant(
          of: _cardOf('Paciente Setenta'),
          matching: find.text('RIESGO ALTO'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cardOf('Paciente Sesenta y nueve'),
          matching: find.text('RIESGO ALTO'),
        ),
        findsNothing,
      );
      expect(find.text('Paciente Treinta días'), findsOneWidget);
      expect(find.text('Paciente Treinta y un días'), findsNothing);
      expect(find.text('3 pacientes'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('F-13 · los eventos del ingreso', () {
    testWidgets('CA-6: un ingreso fallido deja Ingresar, Sesión, el correo, la '
        'IP y Denegado', (t) async {
      final audit = await _open(t);
      await _signIn(t, 'camila.martinez@vitalys.co', 'equivocada');
      final e = _of(audit, RecursoAuditoria.sesion).single;
      expect(e.accion, AccionAuditoria.ingresar);
      expect(e.resultado, ResultadoAuditoria.denegado);
      expect(e.correoIntento, 'camila.martinez@vitalys.co');
      expect(e.ip, isNotNull);
      expect(e.usuarioId, isNull);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-7: sin sedes no entra y deja Denegado con el correo, la IP '
        'y sin sede', (t) async {
      final audit = await _open(t);
      await _signIn(t, 'tomas.herrera@vitalys.co', claveAyuda);
      expect(find.text(mensajeSinSedes), findsOneWidget);
      expect(find.text('Confirmar sede'), findsNothing);
      final e = _of(audit, RecursoAuditoria.sesion).single;
      expect(e.resultado, ResultadoAuditoria.denegado);
      expect(e.correoIntento, 'tomas.herrera@vitalys.co');
      expect(e.ip, isNotNull);
      expect(e.sedeId, isNull);
      await cerrarAppAyuda(t);
    });

    testWidgets(
      'CA-10: el ingreso deja su nombre, Ingresar, Sesión, No aplica, '
      'Permitido y la sede',
      (t) async {
        final audit = await _open(t);
        await entrarMedica(t);
        final e = _of(audit, RecursoAuditoria.sesion).single;
        expect(
          e.usuarioId,
          _datos.usuarioPorCorreo('camila.martinez@vitalys.co')!.id,
        );
        expect(e.accion, AccionAuditoria.ingresar);
        expect(e.proposito, isNull);
        expect(e.resultado, ResultadoAuditoria.permitido);
        expect(e.sedeId, 's1');
        await cerrarAppAyuda(t);
      },
    );

    testWidgets('CA-13: salir sin confirmar la sede no deja un Permitido', (
      t,
    ) async {
      final audit = await _open(t);
      await _signIn(t, 'camila.martinez@vitalys.co', claveAyuda);
      expect(find.text('Confirmar sede'), findsOneWidget);
      await tocarAyuda(t, find.text('Volver'));
      expect(find.text('Ingresar'), findsOneWidget);
      expect(audit.saved, isEmpty);
      await cerrarAppAyuda(t);
    });
  });

  group('F-14 · bloqueo', () {
    testWidgets('CA-10: la cuenta sin sedes no suma ni reinicia: el siguiente '
        'fallo es el quinto', (t) async {
      await _open(t);
      for (var i = 0; i < intentosParaBloqueo - 1; i++) {
        await _signIn(t, 'nadie@vitalys.co', 'mala$i');
        expect(find.text(mensajeDatosIncorrectos), findsOneWidget);
      }
      await _signIn(t, 'tomas.herrera@vitalys.co', claveAyuda);
      expect(find.text(mensajeSinSedes), findsOneWidget);
      await _signIn(t, 'nadie@vitalys.co', 'otra');
      expect(find.text(mensajeBloqueo), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    for (final perfil in ['Administrativo', 'Auditor']) {
      testWidgets('CA-8: el $perfil no encuentra cómo desbloquear', (t) async {
        await _open(t);
        await entrarSedeUnica(t, perfil);
        final desbloquear = find.textContaining(
          RegExp('desbloque', caseSensitive: false),
        );
        expect(desbloquear, findsNothing);
        for (final seccion in ['Indicadores', 'Mediciones', 'Auditoría']) {
          if (find.text(seccion).evaluate().isEmpty) continue;
          await tocarAyuda(t, find.text(seccion).last);
          expect(desbloquear, findsNothing);
        }
        await tocarAyuda(t, find.byTooltip('Menú de usuario'));
        expect(desbloquear, findsNothing);
        await tocarAyuda(t, find.text('Mi perfil'));
        expect(desbloquear, findsNothing);
        await cerrarAppAyuda(t);
      });
    }
  });

  testWidgets('F-15 CA-6: tras el cierre por inactividad la historia pide '
      'otra vez el propósito', (t) async {
    await _open(t);
    await entrarMedica(t, proposito: _seguimiento);
    await _openPatient(t, _jorge, 'Atención del paciente');
    expect(find.text('Registrar atención'), findsWidgets);
    await t.pump(limiteInactividad);
    await t.pumpAndSettle();
    expect(find.text(mensajeInactividad), findsOneWidget);

    await entrarMedica(t, proposito: _seguimiento);
    await tocarAyuda(t, find.text('Ver todos →'));
    await tocarAyuda(t, find.text(_jorge));
    final dialogo = t.widget<DialogoProposito>(find.byType(DialogoProposito));
    expect(dialogo.elegido, isNull);
    expect(find.text('Abrir historia clínica'), findsOneWidget);
    await cerrarAppAyuda(t);
  });

  group('F-16 · declaración del propósito', () {
    testWidgets('CA-5: cancelar vuelve a la lista sin evento', (t) async {
      final audit = await _open(t);
      await entrarMedica(t, proposito: _seguimiento);
      final antes = audit.saved.length;
      await tocarAyuda(t, find.text('Ver todos →'));
      await tocarAyuda(t, find.text(_jorge));
      await tocarAyuda(t, find.text('Cancelar'));
      expect(find.byType(DialogoProposito), findsNothing);
      expect(find.text('Pacientes con alta reciente'), findsWidgets);
      expect(audit.saved.length, antes);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-8: la lista pide los 5 propósitos, ninguno elegido, sin '
        'mostrar pacientes', (t) async {
      await _open(t);
      await entrarMedica(t);
      final page = t.widget<PropositoListaPage>(
        find.byType(PropositoListaPage),
      );
      expect(page.propositos, Proposito.values);
      expect(page.elegido, isNull);
      for (final p in Proposito.values) {
        expect(find.textContaining(p.nombre), findsWidgets);
      }
      expect(find.byType(TarjetaPaciente), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-10: registrar pide solo Atención del paciente y Urgencia, '
        'ninguno elegido', (t) async {
      await _open(t);
      await entrarMedica(t, proposito: _seguimiento);
      await _openPatient(t, _jorge, 'Atención del paciente');
      await tocarAyuda(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar atención'),
      );
      final dialogo = t.widget<DialogoProposito>(find.byType(DialogoProposito));
      expect(dialogo.propositos, [
        Proposito.atencionPaciente,
        Proposito.urgencia,
      ]);
      expect(dialogo.elegido, isNull);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-7 (y F-17 CA-6, F-18 CA-5): la consulta de un '
        'administrativo con Urgencia no muestra nada y deja Denegado', (
      t,
    ) async {
      final audit = await _open(t);
      await entrarSedeUnica(t, 'Administrativo');
      final hernan = _datos.pacientes.firstWhere((p) => p.nombre == _hernan);
      await estadoApp(t).consultarConProposito(hernan, Proposito.urgencia);
      await t.pumpAndSettle();
      expect(find.byType(DatosBasicosPage), findsNothing);
      expect(find.text(hernan.numeroDocumento), findsNothing);
      final e = _of(audit, RecursoAuditoria.datosBasicos).single;
      expect(e.resultado, ResultadoAuditoria.denegado);
      expect(e.proposito, Proposito.urgencia);
      expect(e.pacienteId, hernan.id);
      expect(e.esEmergencia, isFalse);
      await t.pumpAndSettle(const Duration(seconds: 6));
      await cerrarAppAyuda(t);
    });
  });

  group('F-17 y F-05 · registrar con Urgencia', () {
    testWidgets('F-17 CA-9 y CA-10, F-05 CA-6: sin relación se registra con '
        'Urgencia, es de emergencia y no da relación', (t) async {
      final audit = await _open(t);
      await entrarMedica(t, proposito: _seguimiento);
      await _openPatient(t, _hernan, _urgencia);
      await _registerEncounter(t, _urgencia);
      expect(find.textContaining(avisoAccesoEmergencia), findsWidgets);
      final registro = _of(audit, RecursoAuditoria.atencion).single;
      expect(registro.accion, AccionAuditoria.registrar);
      expect(registro.proposito, Proposito.urgencia);
      expect(registro.resultado, ResultadoAuditoria.permitido);
      expect(
        eventosFiltrados(audit.saved, FiltroAuditoria.emergencia),
        contains(registro),
      );

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      final antes = audit.saved.length;
      await tocarAyuda(t, find.text(_hernan));
      await tocarAyuda(t, find.text('Atención del paciente'));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);
      final nuevos = audit.saved.sublist(antes);
      expect(nuevos.map((e) => (e.recurso, e.resultado)), [
        (RecursoAuditoria.historiaClinica, ResultadoAuditoria.denegado),
        (RecursoAuditoria.riesgoReingreso, ResultadoAuditoria.denegado),
      ]);
      await cerrarAppAyuda(t);
    });

    testWidgets('F-17 CA-10: con relación también se avisa la emergencia', (
      t,
    ) async {
      await _open(t);
      await entrarMedica(t, proposito: _seguimiento);
      await _openPatient(t, _jorge, 'Atención del paciente');
      await _registerEncounter(t, _urgencia);
      expect(find.textContaining(avisoAccesoEmergencia), findsWidgets);
      await cerrarAppAyuda(t);
    });
  });

  group('F-05 · relación', () {
    testWidgets('CA-3: un alta de hace 40 días en su sede no da relación y '
        'deja los dos Denegado', (t) async {
      final cuarenta = _patient('x40', 'Paciente Cuarenta', 50, 40);
      final audit = await _open(
        t,
        patients: ListedPatients([..._datos.pacientes, cuarenta]),
      );
      await entrarMedica(t, proposito: _seguimiento);
      await tocarAyuda(t, find.text('Buscar'));
      await t.enterText(find.byType(TextField).first, 'Cuarenta');
      await t.pumpAndSettle();
      await tocarAyuda(t, find.text('Paciente Cuarenta'));
      await tocarAyuda(t, find.text('Atención del paciente'));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);
      expect(
        [
          for (final e in audit.saved)
            if (e.pacienteId == 'x40') (e.recurso, e.resultado),
        ],
        [
          (RecursoAuditoria.historiaClinica, ResultadoAuditoria.denegado),
          (RecursoAuditoria.riesgoReingreso, ResultadoAuditoria.denegado),
        ],
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-7: busca a un paciente de otra sede sin relación y ve su '
        'nombre y documento', (t) async {
      await _open(t);
      await entrarMedica(t, proposito: _seguimiento);
      await tocarAyuda(t, find.text('Buscar'));
      await t.enterText(find.byType(TextField).first, 'Quintero');
      await t.pumpAndSettle();
      expect(find.text(_hernan), findsOneWidget);
      expect(find.text('CC 72105531'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('F-18 · tabla de permisos', () {
    testWidgets('CA-6: el auditor ve el tablero y no queda ningún evento', (
      t,
    ) async {
      final audit = await _open(t);
      await entrarSedeUnica(t, 'Auditor');
      final antes = audit.saved.length;
      await tocarAyuda(t, find.text('Indicadores').last);
      expect(find.byType(IndicadoresPage), findsOneWidget);
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      expect(audit.saved.length, antes);
      await cerrarAppAyuda(t);
    });

    for (final perfil in ['Administrativo', 'Auditor', 'Médico']) {
      testWidgets('CA-8: lo que el perfil del $perfil muestra es lo que el '
          'sistema permite', (t) async {
        await _open(t);
        if (perfil == 'Médico') {
          await entrarMedica(t, proposito: _seguimiento);
        } else {
          await entrarSedeUnica(t, perfil);
        }
        await tocarAyuda(t, find.byTooltip('Menú de usuario'));
        await tocarAyuda(t, find.text('Mi perfil'));
        final permisos = t.widget<PerfilPage>(find.byType(PerfilPage)).permisos;
        expect(permisos, hasLength(AccionPermitida.values.length));
        for (final accion in AccionPermitida.values) {
          final fila = permisos.firstWhere((p) => p.accion == accion.nombre);
          final permitido = estadoApp(
            t,
          ).intentarAcceso(accion, RecursoAuditoria.sesion) as bool;
          expect(permitido, fila.permitido, reason: '$perfil ${accion.name}');
        }
        await t.pumpAndSettle(const Duration(seconds: 6));
        await cerrarAppAyuda(t);
      });
    }
  });
}
