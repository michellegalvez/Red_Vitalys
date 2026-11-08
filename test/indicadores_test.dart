import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/busqueda.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/reglas/reglas.dart';

void main() {
  final datos = DatosSimulados.porDefecto;
  final hoy = datos.hoy;
  final mediciones = datos.mediciones;
  Sede sede(String id) => datos.sede(id);

  group('Periodos (F-08, F-09, RF-29)', () {
    test('hoy es el 6 de noviembre y el último periodo es octubre', () {
      expect(hoy, DateTime(2026, 11, 6, 10, 42));
      expect(ultimoPeriodo(hoy), DateTime(2026, 10));
    });

    test('los 6 meses cerrados van del más antiguo al más reciente', () {
      expect(periodosCerrados(hoy), [
        DateTime(2026, 5),
        DateTime(2026, 6),
        DateTime(2026, 7),
        DateTime(2026, 8),
        DateTime(2026, 9),
        DateTime(2026, 10),
      ]);
    });

    test('un mes cierra cuando termina', () {
      expect(mesCerrado(DateTime(2026, 10), hoy), isTrue);
      expect(mesCerrado(DateTime(2026, 11), hoy), isFalse);
      expect(mesCerrado(DateTime(2026, 12), hoy), isFalse);
      // El de noviembre se puede registrar desde el 1 de diciembre.
      expect(mesCerrado(DateTime(2026, 11), DateTime(2026, 12, 1)), isTrue);
    });

    test('cruza el año: enero mira diciembre', () {
      final enero = DateTime(2027, 1, 15);
      expect(ultimoPeriodo(enero), DateTime(2026, 12));
      expect(periodosCerrados(enero).first, DateTime(2026, 7));
    });
  });

  group('Promedio, marca y cambio (RF-09, RF-26, RF-27)', () {
    final reingreso = indicadorDe(IdIndicador.reingreso);
    final adherencia = indicadorDe(IdIndicador.adherencia);

    test('la marca depende de la dirección del indicador', () {
      // En el reingreso es mejor un valor bajo.
      expect(marcaDe(6.8, 8.3, reingreso), MarcaSede.mejor);
      expect(marcaDe(9.8, 8.3, reingreso), MarcaSede.peor);
      // En la adherencia es mejor un valor alto.
      expect(marcaDe(91, 86.9, adherencia), MarcaSede.mejor);
      expect(marcaDe(82.6, 86.9, adherencia), MarcaSede.peor);
    });

    test('compara los valores redondeados a 1 decimal', () {
      expect(marcaDe(8.34, 8.3, reingreso), MarcaSede.igual);
      expect(marcaDe(8.26, 8.3, reingreso), MarcaSede.igual);
      expect(marcaDe(8.4, 8.3, reingreso), MarcaSede.peor);
    });

    test('el cambio lleva signo y la unidad del indicador', () {
      expect(textoCambio(reingreso, 8.3, 8.6), '−0,3 puntos');
      expect(textoCambio(adherencia, 86.9, 85.8), '+1,1 puntos');
      expect(textoCambio(indicadorDe(IdIndicador.espera), 30, 25), '+5 min');
      expect(textoCambio(indicadorDe(IdIndicador.espera), 37, 32), '+5 min');
      expect(textoCambio(reingreso, 8.6, 8.6), '0,0 puntos');
      expect(textoCambio(reingreso, 8.04, 8.0), '0,0 puntos');
      expect(
        textoCambio(indicadorDe(IdIndicador.eventos), 2.1, 1.8),
        '+0,3 por 1.000',
      );
    });

    test('mejoro respeta la dirección y es nulo si no cambió', () {
      expect(mejoro(reingreso, 8.3, 8.6), isTrue);
      expect(mejoro(reingreso, 8.9, 8.6), isFalse);
      expect(mejoro(adherencia, 90, 85), isTrue);
      expect(mejoro(adherencia, 80, 85), isFalse);
      expect(mejoro(reingreso, 8.6, 8.6), isNull);
      expect(mejoro(reingreso, 8.04, 8.0), isNull);
    });

    test('el promedio de la red no cuenta las sedes sin medición', () {
      // Eventos adversos de octubre: Amb. Envigado no tiene medición.
      final octubre = DateTime(2026, 10);
      final sinMedicion = mediciones.where(
        (m) =>
            m.indicador == IdIndicador.eventos &&
            m.periodo == octubre &&
            m.sedeId == 's8',
      );
      expect(sinMedicion, isEmpty);
      final conMedicion = mediciones
          .where(
            (m) => m.indicador == IdIndicador.eventos && m.periodo == octubre,
          )
          .toList();
      expect(conMedicion.length, 7);
      final esperado =
          conMedicion.fold<double>(0, (a, m) => a + m.valor) /
          conMedicion.length;
      expect(valorRed(mediciones, IdIndicador.eventos, octubre), esperado);
    });

    test('sin ninguna medición el valor de la red es nulo', () {
      expect(
        valorRed(const [], IdIndicador.espera, DateTime(2026, 10)),
        isNull,
      );
    });
  });

  group('Datos simulados (RNF-04)', () {
    test(
      'cada indicador solo tiene mediciones en las sedes que le aplican',
      () {
        for (final m in mediciones) {
          final ind = indicadorDe(m.indicador);
          expect(aplica(ind, sede(m.sedeId).tipo), isTrue, reason: '$m');
        }
        // Los laboratorios no tienen indicadores.
        expect(
          mediciones.where((m) => sede(m.sedeId).tipo == TipoSede.laboratorio),
          isEmpty,
        );
      },
    );

    test('el reingreso solo se mide en las 6 clínicas', () {
      final sedes = mediciones
          .where((m) => m.indicador == IdIndicador.reingreso)
          .map((m) => m.sedeId)
          .toSet();
      expect(sedes, {'s1', 's2', 's3', 's4', 's5', 's6'});
    });

    test('los 4 indicadores tienen valor y mejoraron frente al mes previo', () {
      final lista = resumenes(mediciones, hoy);
      expect(lista, hasLength(4));
      for (final r in lista) {
        expect(r.valorRed, isNotNull);
        expect(r.cambio, isNotNull);
        expect(r.mejoro, isTrue, reason: r.indicador.nombre);
        expect(r.tendencia, hasLength(6));
      }
      expect(indicadoresQueEmpeoraron(lista), 0);
    });

    test('los valores de la red coinciden con los del diseño', () {
      final porId = {
        for (final r in resumenes(mediciones, hoy)) r.indicador.id: r,
      };
      expect(porId[IdIndicador.espera]!.valorRed!.toStringAsFixed(1), '25.8');
      expect(
        porId[IdIndicador.adherencia]!.valorRed!.toStringAsFixed(1),
        '86.9',
      );
      expect(porId[IdIndicador.eventos]!.valorRed!.toStringAsFixed(1), '1.8');
    });

    test('hay mediciones de los últimos 6 meses de cada sede', () {
      for (final p in periodosCerrados(hoy)) {
        expect(
          mediciones.where((m) => m.periodo == p && m.sedeId == 's1'),
          isNotEmpty,
        );
      }
    });
  });

  group('Comparación, tendencia y mediciones recientes (F-09 a F-11)', () {
    test('la comparación solo trae las sedes a las que aplica', () {
      final filas = comparacionDe(
        mediciones,
        indicadorDe(IdIndicador.reingreso),
        datos.sedes,
        hoy,
      );
      expect(filas, hasLength(6));
      expect(filas.first.nombre, 'Cali Norte');
      expect(filas.last.nombre, 'Bogotá Usaquén');
      expect(filas.first.marca, MarcaSede.peor);
      expect(filas.last.marca, MarcaSede.mejor);
    });

    test(
      'en la adherencia va primero la sede con el valor más bajo (la peor)',
      () {
        final filas = comparacionDe(
          mediciones,
          indicadorDe(IdIndicador.adherencia),
          datos.sedes,
          hoy,
        );
        expect(filas, hasLength(8));
        expect(filas.first.valor, lessThan(filas.last.valor!));
      },
    );

    test('la sede sin medición va al final con Sin medición', () {
      final filas = comparacionDe(
        mediciones,
        indicadorDe(IdIndicador.eventos),
        datos.sedes,
        hoy,
      );
      expect(filas, hasLength(8));
      expect(filas.last.nombre, 'Amb. Envigado');
      expect(filas.last.valor, isNull);
      expect(filas.last.marca, isNull);
    });

    test('la tendencia de una sede deja el mes sin medición sin valor', () {
      final puntos = tendenciaDe(
        mediciones,
        IdIndicador.eventos,
        hoy,
        sedeId: 's8',
      );
      expect(puntos, hasLength(6));
      expect(puntos.last.valor, isNull);
      expect(puntos.first.valor, isNotNull);
    });

    test('la tendencia de toda la red tiene los 6 meses', () {
      final puntos = tendenciaDe(mediciones, IdIndicador.reingreso, hoy);
      expect(puntos.map((p) => p.valor), everyElement(isNotNull));
      // Mejora mes a mes: el reingreso baja.
      final valores = puntos.map((p) => p.valor!).toList();
      expect(valores, [...valores]..sort((a, b) => b.compareTo(a)));
    });

    test('las mediciones recientes van del periodo más nuevo y por sede', () {
      final filas = medicionesRecientes(
        mediciones,
        indicadorDe(IdIndicador.reingreso),
        datos.sedes,
        hoy,
      );
      expect(filas, hasLength(6 * 6));
      expect(filas.first.periodo, DateTime(2026, 10));
      expect(filas.last.periodo, DateTime(2026, 5));
      final octubre = filas.where((f) => f.periodo == DateTime(2026, 10));
      final nombres = octubre.map((f) => f.sedeNombre).toList();
      expect(nombres, [...nombres]..sort());
    });
  });

  group('Validar una medición (F-12, RF-28, RF-29, RF-30)', () {
    String? validar(
      IdIndicador id,
      String sedeId,
      DateTime periodo,
      String valor,
    ) => validarMedicion(
      indicador: indicadorDe(id),
      sede: sede(sedeId),
      periodo: periodo,
      valorTexto: valor,
      hoy: hoy,
      existentes: mediciones,
    );
    final octubre = DateTime(2026, 10);

    test('una medición válida se puede guardar', () {
      // Eventos adversos de Amb. Envigado en octubre: la que falta.
      expect(validar(IdIndicador.eventos, 's8', octubre, '1,6'), isNull);
      expect(validar(IdIndicador.eventos, 's8', octubre, '1.6'), isNull);
      expect(validar(IdIndicador.eventos, 's8', octubre, '2'), isNull);
    });

    test('rechaza un indicador que no aplica al tipo de sede', () {
      // El reingreso no se mide en un centro ambulatorio.
      expect(
        validar(IdIndicador.reingreso, 's7', octubre, '8'),
        mensajeNoAplica,
      );
      // Los laboratorios no tienen indicadores.
      expect(validar(IdIndicador.espera, 'l1', octubre, '20'), mensajeNoAplica);
    });

    test('rechaza un mes que todavía no termina', () {
      expect(
        validar(IdIndicador.eventos, 's8', DateTime(2026, 11), '1,6'),
        mensajeMesAbierto,
      );
      expect(
        validar(IdIndicador.eventos, 's8', DateTime(2026, 12), '1,6'),
        mensajeMesAbierto,
      );
    });

    test('rechaza una medición repetida de la misma sede y mes', () {
      expect(
        validar(IdIndicador.reingreso, 's1', octubre, '8'),
        mensajeMedicionRepetida,
      );
    });

    test('rechaza más de 1 decimal', () {
      expect(
        validar(IdIndicador.eventos, 's8', octubre, '1,66'),
        mensajeUnDecimal,
      );
    });

    test('rechaza un valor fuera del rango, con el rango en el mensaje', () {
      expect(
        validar(IdIndicador.eventos, 's8', octubre, '1001'),
        'El valor debe estar entre 0 y 1.000',
      );
      // Adherencia: de 0 a 100. Una medición nueva en otro mes y sede libres.
      final sinAdherencia = DatosSimulados.porDefecto.mediciones.where(
        (m) => m.indicador != IdIndicador.adherencia,
      );
      expect(
        validarMedicion(
          indicador: indicadorDe(IdIndicador.adherencia),
          sede: sede('s1'),
          periodo: octubre,
          valorTexto: '100,1',
          hoy: hoy,
          existentes: sinAdherencia,
        ),
        'El valor debe estar entre 0 y 100',
      );
    });

    test('rechaza un valor vacío o que no es un número', () {
      expect(
        validar(IdIndicador.eventos, 's8', octubre, ''),
        mensajeValorVacio,
      );
      expect(
        validar(IdIndicador.eventos, 's8', octubre, 'abc'),
        mensajeValorVacio,
      );
    });

    test('un valor negativo es de rango y no de vacío (F-12 A1)', () {
      expect(
        validar(IdIndicador.eventos, 's8', octubre, '-1'),
        'El valor debe estar entre 0 y 1.000',
      );
    });

    test('leerValor acepta coma o punto', () {
      expect(leerValor('8,5'), 8.5);
      expect(leerValor(' 8.5 '), 8.5);
      expect(leerValor('12'), 12);
      expect(leerValor('8,5,1'), isNull);
      expect(leerValor(''), isNull);
    });
  });

  group('Búsqueda de pacientes (F-01)', () {
    final todos = datos.pacientes;

    test('con menos de 3 caracteres no se busca', () {
      expect(busquedaValida('he'), isFalse);
      expect(busquedaValida('  he '), isFalse);
      expect(buscarPacientes(todos, 'he'), isEmpty);
      expect(busquedaValida('hen'), isTrue);
    });

    test('busca por cualquier parte del nombre, sin tildes ni mayúsculas', () {
      expect(buscarPacientes(todos, 'HERNAN').single.id, 'p3');
      expect(buscarPacientes(todos, 'munoz').single.id, 'p9');
      expect(buscarPacientes(todos, 'quintero').single.id, 'p3');
      expect(buscarPacientes(todos, 'Darío').single.id, 'p3');
    });

    test('busca por el número de documento completo', () {
      expect(buscarPacientes(todos, '79457654').single.id, 'p1');
      // Un pedazo del documento no cuenta.
      expect(buscarPacientes(todos, '7945'), isEmpty);
    });

    test('encuentra pacientes que no están en la lista de altas recientes', () {
      expect(buscarPacientes(todos, 'gloria').single.id, 'p11');
      final recientes = pacientesConAltaReciente(todos, hoy).map((p) => p.id);
      expect(recientes, isNot(contains('p11')));
    });

    test('los resultados van de la A a la Z y no se repiten', () {
      final res = buscarPacientes([...todos, ...todos], 'mar');
      final ids = res.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      final nombres = res.map((p) => p.nombre).toList();
      expect(nombres.length, greaterThan(1));
      final ordenados = [...nombres]..sort((a, b) => a.compareTo(b));
      expect(nombres.first, ordenados.first);
    });

    test('sin coincidencias devuelve una lista vacía', () {
      expect(buscarPacientes(todos, 'zzzzzz'), isEmpty);
    });
  });

  group('Datos básicos del administrativo (F-03, F-18)', () {
    final u = datos.usuarios;
    final admin = u.firstWhere((x) => x.rol == Rol.administrativo);
    final auditor = u.firstWhere((x) => x.rol == Rol.auditor);

    test('el administrativo ve los datos con Revisión de calidad', () {
      expect(
        evaluarDatosBasicos(
          usuario: admin,
          proposito: Proposito.revisionCalidad,
        ),
        ResultadoConsulta.permitido,
      );
    });

    test('otro propósito se rechaza por el propósito', () {
      expect(
        evaluarDatosBasicos(usuario: admin, proposito: Proposito.urgencia),
        ResultadoConsulta.rechazoProposito,
      );
    });

    test('el auditor no consulta pacientes', () {
      expect(
        evaluarDatosBasicos(
          usuario: auditor,
          proposito: Proposito.revisionCalidad,
        ),
        ResultadoConsulta.rechazoRol,
      );
    });
  });
}
