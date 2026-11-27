import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/fuente_de_datos.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/pages/paciente_page.dart';
import 'package:red_vitalys/pages/registrar_atencion_page.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/repositorios/historia_memoria.dart';
import 'package:red_vitalys/repositorios/historia_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/widgets/boton.dart';

class _AuditoriaFallaAlRegistrarAtencion implements AuditoriaRepositorio {
  @override
  bool get esRemoto => true;

  @override
  Future<void> agregar(EventoAuditoria evento) async {
    // Permite el ingreso, pero falla al registrar la atención
    if (evento.recurso == RecursoAuditoria.atencion) {
      throw StateError('Error simulado al guardar auditoría de atención');
    }
  }

  @override
  Future<List<EventoAuditoria>> listar() async => [];
}

class _HistoriaFallaMock implements HistoriaRepositorio {
  bool falloUnaVez = false;

  @override
  Future<Patient> obtenerHistoria(String pacienteId) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!falloUnaVez) {
      falloUnaVez = true;
      throw StateError('Error simulado al cargar historia');
    }
    return Patient(
      id: pacienteId,
      fullName: 'Jorge Eliecer Gomez',
      age: 63,
      sex: 'M',
      documentType: 'CC',
      documentNumber: '79457654',
      birthDate: DateTime(1963, 5, 12),
      phone: '310 456 7890',
      address: 'Calle 10 # 45-20',
      systemIdentifiers: const [
        SystemIdentifier(
          systemName: 'HCE Cali Norte',
          identifier: 'HCE-0007654',
        ),
      ],
      encounters: const [],
    );
  }

  @override
  Future<Encounter> registrarAtencion({
    required String pacienteId,
    required NuevaAtencion nueva,
    required String medicoId,
    required String medicoNombre,
    required Proposito proposito,
  }) async {
    throw StateError('Error simulado al registrar atención');
  }
}

void main() {
  final datos = DatosSimulados.porDefecto;

  group('P-04 · Repositorio de historia en memoria y fuente de datos', () {
    test('elegirHistoria devuelve HistoriaMemoria cuando cliente es null', () {
      final repo = elegirHistoria(datos: datos, cliente: null);
      expect(repo, isA<HistoriaMemoria>());
    });

    test(
      'HistoriaMemoria obtiene historia clínica con identificadores y riesgo',
      () async {
        final repo = HistoriaMemoria(datos: datos);
        final paciente = datos.pacientes.first;
        final historia = await repo.obtenerHistoria(paciente.id);

        expect(historia.fullName, paciente.nombre);
        expect(historia.systemIdentifiers, isNotEmpty);
        expect(historia.readmissionRisk, isNotNull);
        expect(historia.readmissionRisk!.factors, isNotEmpty);
      },
    );

    test(
      'HistoriaMemoria registra una nueva atención y queda agregada',
      () async {
        final repo = HistoriaMemoria(datos: datos);
        final paciente = datos.pacientes.first;

        final atencion = await repo.registrarAtencion(
          pacienteId: paciente.id,
          nueva: (
            tipo: EncounterType.hospitalizacion,
            sedeId: datos.sedes.first.id,
            inicio: DateTime(2026, 11, 1),
            alta: DateTime(2026, 11, 5),
            destino: 'Domicilio',
          ),
          medicoId: 'u1',
          medicoNombre: 'Dra. Camila Martinez',
          proposito: Proposito.atencionPaciente,
        );

        expect(atencion.type, EncounterType.hospitalizacion);
        expect(atencion.status, EncounterStatus.finalizada);

        final actualizada = await repo.obtenerHistoria(paciente.id);
        expect(actualizada.encounters.any((e) => e.id == atencion.id), isTrue);
      },
    );
  });

  group('P-04 · Auditoría previa obligatoria (AD-07) y estados en UI', () {
    testWidgets(
      'Si la auditoría previa falla al registrar atención, no se guarda y conserva formulario',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final auditoriaFalla = _AuditoriaFallaAlRegistrarAtencion();
        final historiaRepo = HistoriaMemoria(datos: datos);

        await tester.pumpWidget(
          MaterialApp(
            home: AppScreen(
              datos: datos,
              auditoria: auditoriaFalla,
              historia: historiaRepo,
            ),
          ),
        );

        // Iniciar sesión usando chip de prueba Médico
        await tester.tap(find.text('Médico'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ingresar'));
        await tester.pumpAndSettle();

        // Confirmar sede
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clínica Vitalys Cali Norte').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmar sede'));
        await tester.pumpAndSettle();

        // Propósito inicial de la lista
        await tester.tap(find.text('Seguimiento de reingreso'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver pacientes'));
        await tester.pumpAndSettle();

        // Ir a ver todos y abrir paciente
        await tester.tap(find.text('Ver todos →'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('María Fernanda Rojas Benítez').first);
        await tester.pumpAndSettle();

        // Elegir propósito Consulta de historia clínica y abrir
        await tester.tap(find.text('Consulta de historia clínica'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abrir historia clínica'));
        await tester.pumpAndSettle();

        // En la historia, presionar Registrar atención
        expect(find.byType(PacientePage), findsOneWidget);
        await tester.tap(
          find.widgetWithText(BotonVitalys, 'Registrar atención'),
        );
        await tester.pumpAndSettle();

        // Declarar propósito para registrar
        await tester.tap(find.text('Atención del paciente'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(BotonVitalys, 'Registrar atención').last,
        );
        await tester.pumpAndSettle();

        expect(find.byType(RegistrarAtencionPage), findsOneWidget);

        // Llenar formulario
        await tester.tap(find.text('Hospitalización'));
        final campos = find.byType(TextField);
        await tester.enterText(campos.at(0), '30 oct 2026');
        await tester.pumpAndSettle();

        // Scroll para asegurar visibilidad del botón de guardado
        await tester.ensureVisible(
          find.widgetWithText(BotonVitalys, 'Guardar atención'),
        );
        await tester.pumpAndSettle();

        // Confirmar guardado
        await tester.tap(find.widgetWithText(BotonVitalys, 'Guardar atención'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Verifica que no se guardó debido a que la auditoría remota falló (AD-07)
        // y el formulario sigue presente conservando lo digitado (F-04 CA-6)
        expect(find.byType(RegistrarAtencionPage), findsOneWidget);
        expect(find.text('30 oct 2026'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Error al cargar historia muestra mensaje y permite Reintentar (CA-7)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final mockRepo = _HistoriaFallaMock();

        await tester.pumpWidget(
          MaterialApp(
            home: AppScreen(datos: datos, historia: mockRepo),
          ),
        );

        // Iniciar sesión con chip
        await tester.tap(find.text('Médico'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ingresar'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clínica Vitalys Cali Norte').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmar sede'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Seguimiento de reingreso'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver pacientes'));
        await tester.pumpAndSettle();

        // Abrir paciente
        await tester.tap(find.text('Ver todos →'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('María Fernanda Rojas Benítez').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Consulta de historia clínica'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abrir historia clínica'));
        await tester.pumpAndSettle();

        // Debe mostrar mensaje de error con botón Reintentar
        expect(find.text('No se pudo cargar la historia'), findsOneWidget);
        expect(find.text('Reintentar'), findsOneWidget);

        // Al pulsar Reintentar se recarga con éxito
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();

        expect(find.byType(PacientePage), findsOneWidget);
        expect(find.text('Jorge Eliecer Gomez'), findsAtLeastNWidgets(1));
      },
    );
  });
}
