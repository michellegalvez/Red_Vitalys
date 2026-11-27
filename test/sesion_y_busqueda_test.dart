import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/busqueda.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/services/patient_supabase.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ayudas.dart';

// Arreglos de la revisión del 26 nov: relación por una atención en curso,
// lo que queda al cerrar sesión, *Volver* al confirmar la sede y la carga y
// el error de la búsqueda.

final _datos = DatosSimulados.porDefecto;
final _hernan = _datos.pacientes.firstWhere(
  (p) => p.nombre == 'Hernán Darío Quintero Salcedo',
);

class QueuedPatients implements PatientService {
  final calls = <Completer<List<PacienteEnSeguimiento>>>[];
  bool fails = false;

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async {
    if (fails) throw StateError('sin red');
    final call = Completer<List<PacienteEnSeguimiento>>();
    calls.add(call);
    return call.future;
  }
}

class ListedPatients implements PatientService {
  ListedPatients(this.patients);

  final List<PacienteEnSeguimiento> patients;
  bool fails = false;

  @override
  bool get isRemote => true;

  @override
  Future<List<PacienteEnSeguimiento>> listPatients(DateTime today) async {
    if (fails) throw StateError('sin red');
    return patients;
  }
}

class HeldAudit implements AuditoriaRepositorio {
  final saved = <EventoAuditoria>[];
  Completer<void>? hold;

  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async {
    await hold?.future;
    saved.add(evento);
  }

  @override
  Future<List<EventoAuditoria>> listar() async => saved.reversed.toList();
}

Future<void> _open(
  WidgetTester t, {
  PatientService? patients,
  AuditoriaRepositorio? auditoria,
}) async {
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: _datos,
        patients: patients,
        auditoria: auditoria,
        reloj: () => _datos.hoy,
      ),
    ),
  );
}

Future<void> _search(WidgetTester t, String text) async {
  await tocarAyuda(t, find.text('Buscar'));
  await t.enterText(find.byType(TextField).first, text);
  await t.pumpAndSettle();
}

Map<String, Object?> _encounter({
  required String start,
  String? end,
  required String purpose,
  String? predictedAt,
}) {
  final cali = _datos.sede('s1').nombre;
  return {
    'id_paciente': 7,
    'fecha_inicio': start,
    'fecha_fin': end,
    'tipo_atencion': 'hospitalizacion',
    'proposito': purpose,
    'sede': {'nombre': cali},
    'usuario': {'correo': 'camila.martinez@vitalys.co'},
    'prediccion_reingreso': [
      if (predictedAt != null)
        {'score_riesgo': 50, 'fecha_prediccion': predictedAt},
    ],
    'paciente': {
      'primer_nombre': 'Rosa',
      'segundo_nombre': null,
      'primer_apellido': 'Lema',
      'segundo_apellido': null,
      'fecha_nacimiento': '1960-01-01',
      'sexo': 'F',
      'identificador_paciente': [
        {
          'tipo_documento': 'CC',
          'numero_identificacion': '555',
          'es_principal': true,
        },
      ],
    },
  };
}

PatientSupabase _serviceAnswering(
  List<Map<String, Object?>> rows, {
  List<Map<String, Object?>> extraPeople = const [],
}) {
  final client = MockClient((request) async {
    final Object filtered;
    if (request.url.path.endsWith('/paciente')) {
      filtered = [
        for (final r in rows) {...r['paciente'] as Map, 'id_paciente': 7},
        ...extraPeople,
      ];
    } else {
      filtered = request.url.query.contains('fecha_fin=not.is.null')
          ? rows.where((r) => r['fecha_fin'] != null).toList()
          : rows;
    }
    return http.Response(
      jsonEncode(filtered),
      200,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  return PatientSupabase(
    client: SupabaseClient(
      'https://ejemplo.supabase.co',
      'clave-publica',
      httpClient: client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
    sitesByName: {for (final s in _datos.sedes) s.nombre: s.id},
    usersByEmail: {for (final u in _datos.usuarios) u.correo: u.id},
    patientIdsByDocument: const {},
  );
}

void main() {
  group('F-05 · una atención en curso con Atención del paciente', () {
    test('da relación aunque el alta ya no cuente', () async {
      final service = _serviceAnswering([
        _encounter(start: '2026-11-05T08:00:00Z', purpose: 'atencion_paciente'),
        _encounter(
          start: '2026-09-20T08:00:00Z',
          end: '2026-09-27T08:00:00Z',
          purpose: 'seguimiento_reingreso',
          predictedAt: '2026-10-04',
        ),
      ]);
      final patients = await service.listPatients(_datos.hoy);
      final rosa = patients.single;
      final camila = _datos.usuarioPorCorreo('camila.martinez@vitalys.co')!;
      expect(rosa.fechaAlta, DateTime(2026, 9, 27));
      expect(rosa.medicosConAtencion, [camila.id]);
      expect(tieneRelacion(camila, rosa, _datos.hoy), isTrue);
    });

    test('F-01 y F-02: un paciente sin ningún alta se encuentra, pero no '
        'entra en la lista de altas recientes', () async {
      final camila = _datos.usuarioPorCorreo('camila.martinez@vitalys.co')!;
      final service = _serviceAnswering(
        [
          _encounter(
            start: '2026-11-05T08:00:00Z',
            purpose: 'atencion_paciente',
          ),
        ],
        extraPeople: [
          {
            'id_paciente': 8,
            'primer_nombre': 'Luis',
            'segundo_nombre': null,
            'primer_apellido': 'Mora',
            'segundo_apellido': null,
            'fecha_nacimiento': '1970-03-01',
            'sexo': 'M',
            'identificador_paciente': [
              {
                'tipo_documento': 'CC',
                'numero_identificacion': '777',
                'es_principal': true,
              },
            ],
          },
        ],
      );
      final patients = await service.listPatients(_datos.hoy);
      expect(
        patients.map((p) => p.nombre),
        unorderedEquals(['Rosa Lema', 'Luis Mora']),
      );
      expect(buscarPacientes(patients, '777').single.nombre, 'Luis Mora');
      expect(pacientesConAltaReciente(patients, _datos.hoy), isEmpty);
      final rosa = patients.firstWhere((p) => p.nombre == 'Rosa Lema');
      expect(tieneRelacion(camila, rosa, _datos.hoy), isTrue);
      final luis = patients.firstWhere((p) => p.nombre == 'Luis Mora');
      expect(tieneRelacion(camila, luis, _datos.hoy), isFalse);
    });
  });

  testWidgets('al cerrar sesión, la lista que llega tarde no pasa al '
      'siguiente usuario y el siguiente la vuelve a pedir', (t) async {
    final patients = QueuedPatients();
    await _open(t, patients: patients);
    await entrarSedeUnica(t, 'Administrativo');
    expect(patients.calls, hasLength(1));
    await cerrarSesionDelMenu(t);

    await entrarSedeUnica(t, 'Administrativo');
    expect(patients.calls, hasLength(2));
    patients.calls[1].complete([_hernan]);
    await t.pumpAndSettle();
    patients.calls[0].complete(const []);
    await t.pumpAndSettle();

    await _search(t, 'Quintero');
    expect(find.text(_hernan.nombre), findsOneWidget);
    await cerrarAppAyuda(t);
  });

  testWidgets('Volver mientras se guarda el ingreso no deja la app abierta '
      'sin sesión', (t) async {
    final audit = HeldAudit()..hold = Completer<void>();
    await _open(t, auditoria: audit);
    await tocarAyuda(t, find.text('Administrativo'));
    await tocarAyuda(t, find.text('Ingresar'));
    await t.tap(find.text('Confirmar sede'));
    await t.pump();
    await t.tap(find.text('Volver'));
    await t.pump();
    expect(find.text('Confirmar sede'), findsOneWidget);

    audit.hold!.complete();
    await t.pumpAndSettle();
    expect(find.text('Confirmar sede'), findsNothing);
    expect(find.text('Ingresar'), findsNothing);
    expect(audit.saved.single.resultado, ResultadoAuditoria.permitido);
    await cerrarAppAyuda(t);
  });

  group('F-01 CA-7 · la búsqueda con la lista de la base', () {
    testWidgets('si la lista no llega, se ve el error y Reintentar busca '
        'otra vez', (t) async {
      final patients = ListedPatients([_hernan])..fails = true;
      await _open(t, patients: patients);
      await entrarSedeUnica(t, 'Administrativo');
      await _search(t, 'Quintero');
      expect(find.text('No se pudo buscar. Intente de nuevo.'), findsOneWidget);
      expect(find.text('0 pacientes'), findsNothing);

      patients.fails = false;
      await tocarAyuda(t, find.text('Reintentar'));
      expect(find.text(_hernan.nombre), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('mientras llega la lista se ve Buscando…', (t) async {
      final patients = QueuedPatients();
      await _open(t, patients: patients);
      await entrarSedeUnica(t, 'Administrativo');
      await tocarAyuda(t, find.text('Buscar'));
      await t.enterText(find.byType(TextField).first, 'Quintero');
      await t.pump();
      expect(find.text('Buscando…'), findsOneWidget);
      expect(find.text('0 pacientes'), findsNothing);

      patients.calls.single.complete([_hernan]);
      await t.pumpAndSettle();
      expect(find.text(_hernan.nombre), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });
}
