import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/pages/indicadores_page.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/carga.dart';

const _celular = Size(360, 780);
const _escritorio = Size(1280, 800);

final _datos = DatosSimulados.porDefecto;
final _periodo = ultimoPeriodo(_datos.hoy);

IndicadoresPage _tablero({
  bool simularFallas = false,
  void Function(IdIndicador)? onAbrir,
}) {
  return IndicadoresPage(
    resumenes: resumenes(_datos.mediciones, _datos.hoy),
    sedesPorIndicador: {
      for (final i in indicadores)
        i.id: comparacionDe(_datos.mediciones, i, _datos.sedes, _datos.hoy),
    },
    promedios: {
      for (final i in indicadores)
        i.id: valorRed(_datos.mediciones, i.id, _periodo),
    },
    periodo: _periodo,
    simularFallas: simularFallas,
    onAbrirDetalle: onAbrir ?? (_) {},
  );
}

DetalleIndicadorPage _detalle(
  IdIndicador id, {
  String? sedeId,
  bool simularFallas = false,
}) {
  final indicador = indicadorDe(id);
  return DetalleIndicadorPage(
    indicador: indicador,
    sedesDisponibles: [
      for (final s in _datos.sedes)
        if (aplica(indicador, s.tipo)) s,
    ],
    sedeTendencia: sedeId,
    tendencia: tendenciaDe(_datos.mediciones, id, _datos.hoy, sedeId: sedeId),
    comparacion: comparacionDe(
      _datos.mediciones,
      indicador,
      _datos.sedes,
      _datos.hoy,
    ),
    promedio: valorRed(_datos.mediciones, id, _periodo),
    mediciones: medicionesRecientes(
      _datos.mediciones,
      indicador,
      _datos.sedes,
      _datos.hoy,
    ),
    onElegirSede: (_) {},
    onVolver: () {},
    simularFallas: simularFallas,
  );
}

Future<void> _mostrar(WidgetTester t, Widget pagina, Size tamano) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: Scaffold(body: pagina),
    ),
  );
}

Future<void> _pasarCarga(WidgetTester t) async {
  await t.pump(duracionCargaSimulada + const Duration(milliseconds: 50));
  await t.pump();
}

Future<void> _reintentar(WidgetTester t) async {
  final boton = find.text(textoReintentar).first;
  await t.ensureVisible(boton);
  await t.pump();
  await t.tap(boton);
  await t.pump();
}

void main() {
  group('Tablero: sedes de cada indicador (F-08 paso 3, CA-1)', () {
    for (final tamano in [_celular, _escritorio]) {
      testWidgets('muestra las sedes de los 4 indicadores con valor y marca '
          '(${tamano.width.toInt()} px)', (t) async {
        await _mostrar(t, _tablero(), tamano);
        expect(find.text('Dónde actuar primero'), findsOneWidget);
        for (final i in indicadores) {
          expect(find.text(i.nombre), findsWidgets);
          final filas = comparacionDe(
            _datos.mediciones,
            i,
            _datos.sedes,
            _datos.hoy,
          );
          for (final f in filas) {
            if (f.valor != null) {
              expect(
                find.text('${formatoValor(f.valor!)} ${i.unidad}'),
                findsWidgets,
                reason: '${f.nombre} en ${i.nombre}',
              );
            }
          }
        }
        expect(find.text('9,8 %'), findsWidgets);
        expect(find.text(MarcaSede.mejor.nombre), findsWidgets);
        expect(find.text(MarcaSede.peor.nombre), findsWidgets);
        expect(find.text('Sin medición'), findsWidgets);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }

    testWidgets('cada bloque va de la peor sede a la mejor', (t) async {
      await _mostrar(t, _tablero(), _escritorio);
      final reingreso = indicadorDe(IdIndicador.reingreso);
      final filas = comparacionDe(
        _datos.mediciones,
        reingreso,
        _datos.sedes,
        _datos.hoy,
      );
      final peor = filas.first; // el valor más alto (más bajo es mejor)
      final mejor = filas.last;
      final yPeor = t.getTopLeft(find.text(peor.nombre).first).dy;
      final yMejor = t.getTopLeft(find.text(mejor.nombre).first).dy;
      expect(yPeor, lessThan(yMejor));
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Ver detalle abre el indicador de su bloque', (t) async {
      IdIndicador? abierto;
      await _mostrar(t, _tablero(onAbrir: (id) => abierto = id), _escritorio);
      final boton = find.text('Ver detalle').first;
      await t.ensureVisible(boton);
      await t.pump();
      await t.tap(boton);
      expect(abierto, indicadores.first.id);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Detalle: valores mensuales, promedio y marcas (F-09, F-10)', () {
    for (final tamano in [_celular, _escritorio]) {
      testWidgets('muestra el valor de cada uno de los 6 meses '
          '(${tamano.width.toInt()} px)', (t) async {
        await _mostrar(t, _detalle(IdIndicador.reingreso), tamano);
        final puntos = tendenciaDe(
          _datos.mediciones,
          IdIndicador.reingreso,
          _datos.hoy,
        );
        expect(puntos, hasLength(6));
        for (final p in puntos) {
          expect(find.text(formatoPeriodo(p.periodo)), findsWidgets);
          expect(find.text('${formatoValor(p.valor!)} %'), findsWidgets);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }

    testWidgets(
      'el promedio de la red lleva número, periodo y marca en texto',
      (t) async {
        await _mostrar(t, _detalle(IdIndicador.reingreso), _celular);
        final media = valorRed(
          _datos.mediciones,
          IdIndicador.reingreso,
          _periodo,
        )!;
        expect(
          find.text('oct 2026 · Promedio de la red: ${formatoValor(media)} %'),
          findsOneWidget,
        );
        expect(find.text('8,3 %'), findsWidgets);
        // Cali Norte (9,8 %) está peor que el promedio.
        final barras = find.bySemanticsLabel(RegExp('Peor que el promedio'));
        expect(barras, findsWidgets);
        expect(
          find.textContaining('9,8 % · Peor que el promedio'),
          findsOneWidget,
        );
        expect(find.textContaining('· Mejor que el promedio'), findsWidgets);
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets('sin medición en el último periodo no se muestra el anterior', (
      t,
    ) async {
      await _mostrar(t, _detalle(IdIndicador.eventos, sedeId: 's8'), _celular);
      expect(find.text('Sin medición en oct 2026'), findsOneWidget);
      expect(find.textContaining('Último periodo:'), findsNothing);
      expect(find.text('Sin medición'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('con medición dice cuál es el último periodo', (t) async {
      await _mostrar(t, _detalle(IdIndicador.reingreso), _celular);
      expect(find.text('Último periodo: 8,3 % (oct 2026)'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Valores escritos (F-12, RNF-05)', () {
    final eventos = indicadorDe(IdIndicador.eventos);
    final sede = _datos.sedes.firstWhere((s) => s.id == 's8');
    String? validar(String texto) => validarMedicion(
      indicador: eventos,
      sede: sede,
      periodo: _periodo,
      valorTexto: texto,
      hoy: _datos.hoy,
      existentes: const [],
    );

    test('un valor negativo da el mensaje de rango, no el de vacío', () {
      expect(validar('-5'), textoRango(eventos));
      expect(validar('-5'), isNot(mensajeValorVacio));
      expect(leerValor('-5'), -5);
      expect(validar(''), mensajeValorVacio);
      expect(validar('abc'), mensajeValorVacio);
    });

    test('1.440 es mil cuatrocientos cuarenta', () {
      expect(leerValor('1.440'), 1440);
      expect(leerValor('1.440,5'), 1440.5);
      expect(leerValor('1.234.567'), 1234567);
      expect(validar('1.440'), textoRango(eventos));
      expect(
        validarMedicion(
          indicador: indicadorDe(IdIndicador.espera),
          sede: sede,
          periodo: _periodo,
          valorTexto: '1.440',
          hoy: _datos.hoy,
          existentes: const [],
        ),
        isNull,
      );
    });

    test('el punto es decimal si no sigue el patrón de miles', () {
      expect(leerValor('8.5'), 8.5);
      expect(leerValor('8,5'), 8.5);
      expect(leerValor('12.34'), 12.34);
      expect(validar('1.25'), mensajeUnDecimal);
      expect(validar('1,50'), isNull);
      expect(leerValor('1.44.0'), isNull);
    });
  });

  group('Redondeo a 1 decimal (RNF-05)', () {
    test('el valor mostrado y la marca usan la misma regla', () {
      expect(formatoValor(8.25), '8,3');
      expect(redondear1(8.25), 8.3);
      expect(formatoValor(0.45), formatoValor(redondear1(0.45)));
      final reingreso = indicadorDe(IdIndicador.reingreso);
      // 8,25 se muestra "8,3": frente a un 8,3 de la red es igual.
      expect(marcaDe(8.25, 8.3, reingreso), MarcaSede.igual);
      for (final v in [0.05, 1.15, 2.35, 8.25, 8.35, 9.95, 84.45]) {
        expect(
          formatoValor(v),
          redondear1(v).toStringAsFixed(1).replaceAll('.', ','),
        );
      }
    });
  });

  group('Simular fallas de red', () {
    testWidgets('el tablero carga, falla y se recupera con Reintentar', (
      t,
    ) async {
      await _mostrar(t, _tablero(simularFallas: true), _celular);
      expect(find.text('Cargando indicadores…'), findsOneWidget);
      expect(find.text('Dónde actuar primero'), findsNothing);
      await _pasarCarga(t);
      expect(find.text('No se pudo cargar el tablero'), findsOneWidget);
      expect(find.text(textoReintentar), findsOneWidget);
      await _reintentar(t);
      expect(find.text('Cargando indicadores…'), findsOneWidget);
      await _pasarCarga(t);
      expect(find.text('Dónde actuar primero'), findsOneWidget);
      expect(find.text('No se pudo cargar el tablero'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('las 3 secciones del detalle fallan y se recuperan solas', (
      t,
    ) async {
      await _mostrar(
        t,
        _detalle(IdIndicador.reingreso, simularFallas: true),
        _escritorio,
      );
      expect(find.text('Cargando tendencia…'), findsOneWidget);
      expect(find.text('Cargando comparación…'), findsOneWidget);
      expect(find.text('Cargando mediciones…'), findsOneWidget);
      await _pasarCarga(t);
      expect(find.text('No se pudo cargar la tendencia'), findsOneWidget);
      expect(find.text('No se pudo cargar la comparación'), findsOneWidget);
      expect(find.text('No se pudieron cargar las mediciones'), findsOneWidget);
      expect(find.text(textoReintentar), findsNWidgets(3));

      // Reintentar solo la tendencia no toca las otras dos.
      await _reintentar(t);
      await _pasarCarga(t);
      expect(find.text('No se pudo cargar la tendencia'), findsNothing);
      expect(find.text('Último periodo: 8,3 % (oct 2026)'), findsOneWidget);
      expect(find.text('No se pudo cargar la comparación'), findsOneWidget);
      expect(find.text(textoReintentar), findsNWidgets(2));

      await _reintentar(t);
      await _pasarCarga(t);
      await _reintentar(t);
      await _pasarCarga(t);
      expect(find.text(textoReintentar), findsNothing);
      expect(find.text('Mediciones recientes'), findsOneWidget);
      expect(find.textContaining(' mediciones'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  });

  group(
    'Cambio, marca y orden con datos propios (F-08 CA-12 a CA-14, F-10)',
    () {
      final oct = DateTime(2026, 10);
      final sep = DateTime(2026, 9);

      Medicion med(IdIndicador i, String sede, DateTime p, double v) =>
          Medicion(indicador: i, sedeId: sede, periodo: p, valor: v);

      Widget tablero(List<Medicion> ms) => IndicadoresPage(
        resumenes: resumenes(ms, _datos.hoy),
        sedesPorIndicador: {
          for (final i in indicadores)
            i.id: comparacionDe(ms, i, _datos.sedes, _datos.hoy),
        },
        promedios: {for (final i in indicadores) i.id: valorRed(ms, i.id, oct)},
        periodo: oct,
        onAbrirDetalle: (_) {},
      );

      for (final tamano in [_celular, _escritorio]) {
        testWidgets('CA-12: espera 32 a 37 muestra +5 min y Empeora '
            '(${tamano.width.toInt()} px)', (t) async {
          final ms = [
            med(IdIndicador.espera, 's1', sep, 32),
            med(IdIndicador.espera, 's1', oct, 37),
          ];
          await _mostrar(t, tablero(ms), tamano);
          expect(find.text('+5 min vs. mes previo'), findsOneWidget);
          expect(find.text('Empeora'), findsOneWidget);
          expect(find.text('ESTRUCTURA'), findsOneWidget);
          expect(find.text('RESULTADO'), findsNWidgets(2));
          expect(find.text('PROCESO'), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        });
      }

      testWidgets('CA-13: sin cambio muestra 0,0 y Sin cambio', (t) async {
        final ms = [
          med(IdIndicador.reingreso, 's1', sep, 8),
          med(IdIndicador.reingreso, 's1', oct, 8),
        ];
        await _mostrar(t, tablero(ms), _escritorio);
        expect(find.text('0,0 puntos vs. mes previo'), findsOneWidget);
        expect(find.text('Sin cambio'), findsOneWidget);
        await t.pumpWidget(const SizedBox());
      });

      testWidgets('CA-7: sin periodo anterior no hay marca de cambio', (
        t,
      ) async {
        final ms = [med(IdIndicador.reingreso, 's1', oct, 8)];
        await _mostrar(t, tablero(ms), _escritorio);
        expect(find.text('Sin periodo anterior'), findsWidgets);
        expect(find.text('Sin cambio'), findsNothing);
        await t.pumpWidget(const SizedBox());
      });

      testWidgets('CA-14: reingreso 6,0 / 8,0 / 10,0 va de 10,0 a 6,0', (
        t,
      ) async {
        final ms = [
          med(IdIndicador.reingreso, 's1', oct, 6),
          med(IdIndicador.reingreso, 's2', oct, 8),
          med(IdIndicador.reingreso, 's3', oct, 10),
        ];
        await _mostrar(t, tablero(ms), _escritorio);
        final y10 = t.getTopLeft(find.text('10,0 %').first).dy;
        final y6 = t.getTopLeft(find.text('6,0 %').first).dy;
        expect(y10, lessThan(y6));
        await t.pumpWidget(const SizedBox());
      });

      test('F-10 CA-2: reingreso 6,0 / 8,0 / 10,0 empieza en 10,0', () {
        final ms = [
          med(IdIndicador.reingreso, 's1', oct, 6),
          med(IdIndicador.reingreso, 's2', oct, 8),
          med(IdIndicador.reingreso, 's3', oct, 10),
        ];
        final filas = comparacionDe(
          ms,
          indicadorDe(IdIndicador.reingreso),
          _datos.sedes,
          _datos.hoy,
        ).where((f) => f.valor != null).toList();
        expect([for (final f in filas) f.valor], [10, 8, 6]);
      });

      test('F-10 CA-3: adherencia 85 / 90 / 95 empieza en 85', () {
        final ms = [
          med(IdIndicador.adherencia, 's1', oct, 95),
          med(IdIndicador.adherencia, 's2', oct, 85),
          med(IdIndicador.adherencia, 's3', oct, 90),
        ];
        final filas = comparacionDe(
          ms,
          indicadorDe(IdIndicador.adherencia),
          _datos.sedes,
          _datos.hoy,
        );
        expect([for (final f in filas.take(3)) f.valor], [85, 90, 95]);
        // Las sedes sin medición van al final.
        expect(filas.skip(3).every((f) => f.valor == null), isTrue);
      });

      test('mismo valor: por nombre', () {
        final ms = [
          med(IdIndicador.reingreso, 's2', oct, 8),
          med(IdIndicador.reingreso, 's1', oct, 8),
        ];
        final filas = comparacionDe(
          ms,
          indicadorDe(IdIndicador.reingreso),
          _datos.sedes,
          _datos.hoy,
        );
        expect(filas[0].nombre.compareTo(filas[1].nombre), lessThan(0));
      });

      test('CA-4: red 8,04 y sede 8,0 es Igual al promedio', () {
        expect(
          marcaDe(8.0, 8.04, indicadorDe(IdIndicador.reingreso)),
          MarcaSede.igual,
        );
      });
    },
  );
}
