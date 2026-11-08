import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/pages/indicadores_page.dart';
import 'package:red_vitalys/pages/perfil_page.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';

import 'ayudas.dart';

// Correcciones de la auditoría del código contra las specs: destino al alta
// (F-04), error de cierre en el perfil (F-23), conteo de fallos (F-14),
// cancelar el propósito (F-16), tablero sin mediciones (F-08), categorías
// (F-08) y quién registró la medición (F-12).

const _maria = 'María Fernanda Rojas Benítez';

Future<void> _abrirFormularioAtencion(WidgetTester t) async {
  await abrirAppCon(t);
  await entrarMedica(t, proposito: 'Seguimiento de reingreso');
  await tocarAyuda(t, find.text('Ver todos →'));
  await tocarAyuda(t, find.text(_maria));
  await tocarAyuda(t, find.text('Consulta de historia clínica'));
  await tocarAyuda(t, find.text('Abrir historia clínica'));
  await tocarAyuda(t, find.widgetWithText(BotonVitalys, 'Registrar atención'));
  await tocarAyuda(t, find.text('Atención del paciente'));
  await tocarAyuda(
    t,
    find.widgetWithText(BotonVitalys, 'Registrar atención').last,
  );
}

Future<void> _pintar(WidgetTester t, Widget pagina) async {
  t.view.physicalSize = celularAyuda;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: Scaffold(body: pagina),
    ),
  );
}

void main() {
  group('F-04 · Destino al alta', () {
    test('sin fecha de alta el destino queda Sin definir', () {
      final atencion = atencionDeFormulario(
        id: 'x',
        nueva: (
          tipo: EncounterType.values.first,
          sedeId: 's1',
          inicio: DateTime(2026, 11, 6),
          alta: null,
          destino: 'Domicilio',
        ),
        sede: 'Cali Norte',
        medico: 'Dra. Camila',
      );
      expect(atencion.dischargeDestination, destinoSinDefinir);
    });

    test('con fecha de alta se conserva el destino elegido', () {
      final atencion = atencionDeFormulario(
        id: 'x',
        nueva: (
          tipo: EncounterType.values.first,
          sedeId: 's1',
          inicio: DateTime(2026, 11, 5),
          alta: DateTime(2026, 11, 6),
          destino: 'Domicilio',
        ),
        sede: 'Cali Norte',
        medico: 'Dra. Camila',
      );
      expect(atencion.dischargeDestination, 'Domicilio');
    });

    testWidgets('el selector del destino espera la fecha de alta', (t) async {
      await _abrirFormularioAtencion(t);
      final destino = find.byType(DropdownButtonFormField<String>).last;
      bool habilitado() =>
          t.widget<DropdownButtonFormField<String>>(destino).onChanged != null;
      expect(habilitado(), isFalse);

      await t.enterText(find.byType(TextField).at(1), '06/11/2026');
      await t.pump();
      expect(habilitado(), isTrue);

      await t.enterText(find.byType(TextField).at(1), '');
      await t.pump();
      expect(habilitado(), isFalse);
      await cerrarAppAyuda(t);
    });
  });

  group('F-23 · Error de cierre en el perfil', () {
    for (final (estado, espera) in [
      ('cargando', Duration.zero),
      ('en error', const Duration(milliseconds: 900)),
    ]) {
      testWidgets('se ve con el perfil $estado', (t) async {
        await _pintar(
          t,
          PerfilPage(
            datos: const [],
            permisos: const [],
            propositos: const [],
            onCerrarSesion: () {},
            simularFallas: true,
            errorCierre: 'No se pudo cerrar la sesión. Intente de nuevo.',
          ),
        );
        await t.pump(espera);
        expect(
          find.text('No se pudo cerrar la sesión. Intente de nuevo.'),
          findsOneWidget,
        );
        await t.pumpWidget(const SizedBox());
      });
    }
  });

  group('F-14 · El conteo de fallos', () {
    testWidgets('validar las credenciales no reinicia el conteo', (t) async {
      await abrirAppCon(t);
      const correo = 'camila.martinez@vitalys.co';
      for (var i = 0; i < intentosParaBloqueo - 1; i++) {
        await escribirAyuda(t, correo, 'mala');
        await tocarAyuda(t, find.text('Ingresar'));
      }
      // Credenciales correctas, pero sale sin confirmar la sede.
      await escribirAyuda(t, correo, claveAyuda);
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text('Confirmar sede'), findsOneWidget);
      await tocarAyuda(t, find.text('Volver'));

      // Un fallo más es el quinto y bloquea.
      await escribirAyuda(t, correo, 'mala');
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text(mensajeBloqueo), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('F-16 · Cancelar el propósito de la lista', () {
    testWidgets('recién iniciada la sesión queda en el tablero', (t) async {
      await abrirAppCon(t);
      await entrarMedica(t);
      await tocarAyuda(t, find.text('Ahora no'));
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('vuelve a la sección donde estaba', (t) async {
      await abrirAppCon(t);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      await tocarAyuda(t, find.text('Buscar'));
      expect(find.text('Buscar pacientes'), findsOneWidget);

      await tocarAyuda(t, find.text('Inicio'));
      expect(find.text('ÚLTIMO PASO ANTES DE ENTRAR'), findsOneWidget);
      await tocarAyuda(t, find.text('Ahora no'));
      expect(find.text('Buscar pacientes'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('F-08 · Tablero sin mediciones', () {
    const sedes = [
      FilaSede(sedeId: 's1', nombre: 'Cali Norte'),
      FilaSede(sedeId: 's2', nombre: 'Bogotá Usaquén'),
    ];
    final indicador = indicadores.first;

    Future<void> pintarTablero(
      WidgetTester t, {
      required ResumenIndicador resumen,
      required List<FilaSede> filas,
    }) => _pintar(
      t,
      IndicadoresPage(
        resumenes: [resumen],
        sedesPorIndicador: {indicador.id: filas},
        promedios: {indicador.id: resumen.valorRed},
        periodo: DateTime(2026, 10),
        onAbrirDetalle: (_) {},
      ),
    );

    testWidgets('sin ninguna medición solo dice Sin mediciones', (t) async {
      await pintarTablero(
        t,
        resumen: ResumenIndicador(indicador: indicador, tendencia: const []),
        filas: sedes,
      );
      expect(find.text(mensajeSinMediciones), findsNWidgets(2));
      expect(find.text('Sin periodo anterior'), findsNothing);
      expect(find.text(mensajeSinMedicion), findsNothing);
      expect(find.text('Cali Norte'), findsNothing);
    });

    testWidgets('con valor y sin mes previo sí dice Sin periodo anterior', (
      t,
    ) async {
      await pintarTablero(
        t,
        resumen: ResumenIndicador(
          indicador: indicador,
          valorRed: 8.5,
          tendencia: const [8.5],
        ),
        filas: const [FilaSede(sedeId: 's1', nombre: 'Cali Norte', valor: 8.5)],
      );
      expect(find.text('Sin periodo anterior'), findsOneWidget);
    });
  });

  group('F-08 · Categoría', () {
    test('el modelo guarda Resultado, Estructura y Proceso', () {
      expect(indicadores.map((i) => i.categoria).toSet(), {
        'Resultado',
        'Estructura',
        'Proceso',
      });
    });
  });

  group('F-12 · Quién registró la medición', () {
    testWidgets('cada fila muestra el administrativo, la fecha y la hora', (
      t,
    ) async {
      await abrirAppCon(t);
      await entrarSedeUnica(t, 'Administrativo');
      await tocarAyuda(t, find.text('Mediciones'));
      await tocarAyuda(t, find.byType(DropdownButtonFormField<IdIndicador>));
      await tocarAyuda(t, find.text('Eventos adversos evitables').last);
      await tocarAyuda(t, find.byType(DropdownButtonFormField<String>).first);
      await tocarAyuda(t, find.text('Centro Ambulatorio Envigado').last);
      await t.enterText(find.byType(TextField).first, '1,6');
      await t.pump();
      await tocarAyuda(
        t,
        find.widgetWithText(BotonVitalys, 'Registrar medición'),
      );
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpAndSettle();

      final hoy = DatosSimulados.porDefecto.hoy;
      expect(
        find.text('Registró Andrés Felipe Ruiz · ${formatoFechaHora(hoy)}'),
        findsOneWidget,
      );
      await cerrarAppAyuda(t);
    });
  });
}
