import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/reglas/busqueda.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/proposito.dart';

import 'integracion_test.dart'
    show
        abrirApp,
        abrirPaciente,
        celular,
        entrarComoMedica,
        escritorio,
        pedirRegistro,
        tocar;

final _datos = DatosSimulados.porDefecto;
final _hoy = _datos.hoy;
Usuario _usuario(String correo) => _datos.usuarioPorCorreo(correo)!;
PacienteEnSeguimiento _paciente(String nombre) =>
    _datos.pacientes.firstWhere((p) => p.nombre == nombre);

Future<void> cerrarApp(WidgetTester t) => t.pumpWidget(const SizedBox());

/// Entra con una cuenta de una sola sede, con los botones de prueba.
Future<void> entrarCon(
  WidgetTester t,
  String perfil, {
  Size tamano = celular,
}) async {
  await abrirApp(t, tamano: tamano);
  await tocar(t, find.text(perfil));
  await tocar(t, find.text('Ingresar'));
  await tocar(t, find.text('Confirmar sede'));
}

Future<void> cerrarSesionDesdeElMenu(WidgetTester t) async {
  await tocar(t, find.byTooltip('Menú de usuario'));
  await tocar(t, find.text('Mi perfil'));
  await tocar(t, find.text('Cerrar sesión'));
}

void main() {
  group('Reglas nuevas de la entrega', () {
    final camila = _usuario('camila.martinez@vitalys.co');
    final andres = _usuario('andres.ruiz@vitalys.co');
    final jorge = _paciente('Jorge Eliécer Pardo Villamizar');

    test('al registrar solo sirven Atención del paciente y Urgencia', () {
      expect(propositosParaRegistrar(Rol.medico), [
        Proposito.atencionPaciente,
        Proposito.urgencia,
      ]);
      expect(propositosParaRegistrar(Rol.administrativo), isEmpty);
      expect(propositosParaRegistrar(Rol.auditor), isEmpty);
    });

    test('registrar una atención se decide en las reglas (F-04, F-18)', () {
      ResultadoConsulta registrar(Usuario u, Proposito p) =>
          evaluarRegistro(usuario: u, paciente: jorge, proposito: p, hoy: _hoy);
      expect(
        registrar(andres, Proposito.revisionCalidad),
        ResultadoConsulta.rechazoRol,
      );
      expect(
        registrar(camila, Proposito.consultaHistoria),
        ResultadoConsulta.rechazoProposito,
      );
      expect(
        registrar(camila, Proposito.atencionPaciente),
        ResultadoConsulta.permitido,
      );
      expect(
        registrar(camila, Proposito.urgencia),
        ResultadoConsulta.permitido,
      );
    });

    test('el documento se busca completo, con o sin puntos (F-01)', () {
      final doc = jorge.numeroDocumento;
      final conPuntos =
          '${doc.substring(0, 2)}.${doc.substring(2, 5)}.${doc.substring(5)}';
      expect(coincideBusqueda(jorge, doc), isTrue);
      expect(coincideBusqueda(jorge, conPuntos), isTrue);
      expect(coincideBusqueda(jorge, doc.substring(0, 4)), isFalse);
      expect(coincideBusqueda(jorge, 'eliecer'), isTrue);
    });

    test('8,50 vale como 8,5: los ceros al final no cuentan (F-12)', () {
      String? validar(String valor) => validarMedicion(
        indicador: indicadorDe(IdIndicador.reingreso),
        sede: _datos.sede('s1'),
        periodo: DateTime(2026, 9),
        valorTexto: valor,
        hoy: _hoy,
        existentes: const [],
      );
      expect(validar('8,50'), isNull);
      expect(validar('8,55'), isNotNull);
    });

    test('validarAtencion pide motivo y diagnóstico y revisa la fecha', () {
      ({String? error, DateTime? fecha}) validar({
        String motivo = 'Dolor',
        String diagnostico = 'R07.4',
        String fecha = '30/10/2026 10:42',
      }) => validarAtencion(
        motivo: motivo,
        diagnostico: diagnostico,
        fechaTexto: fecha,
        ahora: _hoy,
      );
      expect(validar().error, isNull);
      expect(validar().fecha, DateTime(2026, 10, 30, 10, 42));
      expect(validar(motivo: '  ').error, mensajeCompleteAtencion);
      expect(validar(fecha: '01/12/2026 10:00').error, mensajeFechaFutura);
      expect(validar(fecha: '01/01/1800 10:00').error, mensajeFechaAntigua);
      expect(validar(motivo: 'x' * 201).error, mensajeMotivoLargo);
    });
  });

  group('Datos simulados de la historia (RNF-04, F-02, F-03)', () {
    final recientes = pacientesConAltaReciente(_datos.pacientes, _hoy);
    String sedeDe(PacienteEnSeguimiento p) =>
        _datos.sede(p.sedeAltaId).nombreCorto;

    test('al menos 3 pacientes tienen atenciones en 2 sedes o más', () {
      final conVariasSedes = recientes.where((p) {
        final h = historiaDe(p, sedeAlta: sedeDe(p), hoy: _hoy);
        return h.encounters.map((e) => e.facilityName).toSet().length >= 2;
      });
      expect(conVariasSedes.length, greaterThanOrEqualTo(3));
    });

    test('cada sistema tiene su propio identificador y hay teléfono', () {
      for (final p in recientes) {
        final h = historiaDe(p, sedeAlta: sedeDe(p), hoy: _hoy);
        final ids = h.systemIdentifiers.map((s) => s.identifier).toSet();
        expect(ids.length, h.systemIdentifiers.length);
        expect(h.phone, isNotEmpty);
      }
    });
  });

  group('Pantallas sin desbordes (RNF-07)', () {
    testWidgets('el pop-up del propósito en escritorio cabe y se cancela', (
      t,
    ) async {
      await entrarComoMedica(t, tamano: escritorio);
      await tocar(t, find.text('Ver todos →'));
      await tocar(t, find.text('Jorge Eliécer Pardo Villamizar'));
      expect(find.text('Declare el propósito de uso'), findsWidgets);
      // El riesgo no se muestra antes de declarar el propósito.
      expect(
        find.descendant(
          of: find.byType(DialogoProposito),
          matching: find.byType(AnilloRiesgo),
        ),
        findsNothing,
      );
      expect(t.takeException(), isNull);
      await tocar(t, find.widgetWithText(BotonVitalys, 'Cancelar'));
      expect(find.text('Declare el propósito de uso'), findsNothing);
      await cerrarApp(t);
    });

    for (final (nombre, tamano) in [
      ('celular', celular),
      ('escritorio', escritorio),
    ]) {
      testWidgets('buscar y datos básicos caben en $nombre', (t) async {
        await entrarCon(t, 'Administrativo', tamano: tamano);
        await tocar(t, find.text('Buscar'));
        await t.enterText(find.byType(TextField).first, 'hernan');
        await t.pump();
        expect(t.takeException(), isNull);
        await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
        await tocar(t, find.text('Revisión de calidad'));
        await tocar(t, find.text('Ver datos básicos'));
        expect(find.text('DATOS BÁSICOS'), findsOneWidget);
        expect(find.text('TELÉFONO'), findsOneWidget);
        expect(t.takeException(), isNull);
        await cerrarApp(t);
      });

      testWidgets('registrar atención con errores cabe en $nombre', (t) async {
        await entrarComoMedica(t, tamano: tamano);
        await abrirPaciente(
          t,
          'Jorge Eliécer Pardo Villamizar',
          'Consulta de historia clínica',
        );
        expect(t.takeException(), isNull);
        await pedirRegistro(t, 'Atención del paciente');
        await tocar(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
        expect(find.text(mensajeCompleteAtencion), findsOneWidget);
        expect(t.takeException(), isNull);
        await cerrarApp(t);
      });

      testWidgets('el acceso con error y el paso de la sede caben en $nombre', (
        t,
      ) async {
        await abrirApp(t, tamano: tamano);
        await t.enterText(find.byType(TextField).at(0), 'nadie@vitalys.co');
        await t.enterText(find.byType(TextField).at(1), 'equivocada');
        await tocar(t, find.text('Ingresar'));
        expect(find.text(mensajeDatosIncorrectos), findsOneWidget);
        expect(t.takeException(), isNull);
        await tocar(t, find.text('Médico'));
        await tocar(t, find.text('Ingresar'));
        expect(find.text('Confirmar sede'), findsOneWidget);
        expect(t.takeException(), isNull);
        await cerrarApp(t);
      });

      testWidgets('el perfil de la médica cabe en $nombre', (t) async {
        await entrarComoMedica(t, tamano: tamano);
        await tocar(t, find.byTooltip('Menú de usuario'));
        await tocar(t, find.text('Mi perfil'));
        expect(find.text('Cerrar sesión'), findsWidgets);
        expect(t.takeException(), isNull);
        await cerrarApp(t);
      });
    }
  });

  group('Eventos y sesión', () {
    testWidgets('abrir la historia deja también el evento del riesgo (F-07)', (
      t,
    ) async {
      await entrarComoMedica(t);
      await abrirPaciente(
        t,
        'Jorge Eliécer Pardo Villamizar',
        'Consulta de historia clínica',
      );
      await tocar(t, find.textContaining('Pacientes  /'));
      await cerrarSesionDesdeElMenu(t);
      await tocar(t, find.text('Auditor'));
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      // El del Figma (e1) + el de esta consulta.
      expect(find.text('Riesgo de reingreso'), findsNWidgets(2));
      await cerrarApp(t);
    });

    testWidgets('la cuenta sin sedes deja un evento denegado (F-13 A3)', (
      t,
    ) async {
      await abrirApp(t);
      await t.enterText(
        find.byType(TextField).at(0),
        'tomas.herrera@vitalys.co',
      );
      await t.enterText(
        find.byType(TextField).at(1),
        _datos.contrasenaPrototipo,
      );
      await tocar(t, find.text('Ingresar'));
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();
      expect(find.text(mensajeSinSedes), findsOneWidget);
      await tocar(t, find.text('Auditor'));
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      expect(find.text('tomas.herrera@vitalys.co'), findsWidgets);
      await cerrarApp(t);
    });

    testWidgets('lo buscado no pasa al siguiente usuario (F-15)', (t) async {
      await entrarCon(t, 'Administrativo');
      await tocar(t, find.text('Buscar'));
      await t.enterText(find.byType(TextField).first, 'hernan');
      await t.pump();
      await cerrarSesionDesdeElMenu(t);
      await entrarCon(t, 'Administrativo');
      await tocar(t, find.text('Buscar'));
      expect(find.text('hernan'), findsNothing);
      expect(find.text('Hernán Darío Quintero Salcedo'), findsNothing);
      await cerrarApp(t);
    });
  });
}
