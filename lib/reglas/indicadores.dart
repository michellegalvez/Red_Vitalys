/// Reglas de los indicadores de calidad, en un único lugar (AD-11): la tabla
/// de indicadores, el promedio de la red, la marca de cada sede, el cambio
/// frente al periodo anterior y las validaciones de una medición.
///
/// Son funciones puras: no guardan nada ni leen la pantalla.
library;

import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';

export 'package:red_vitalys/formato/formato.dart' show redondear1;

/// Cuántos meses cerrados muestran la tendencia y las mediciones (F-09).
const int mesesVisibles = 6;

/// Mensajes de rechazo de una medición (F-12).
const String mensajeMesAbierto = 'El mes todavía no ha terminado';
const String mensajeMedicionRepetida =
    'Ya existe una medición de este indicador para esta sede en ese mes';
const String mensajeNoAplica = 'Este indicador no aplica a esta sede';
const String mensajeUnDecimal = 'Use máximo 1 decimal';
const String mensajeValorVacio = 'Escriba el valor, por ejemplo 8,5';
const String mensajeSinMediciones = 'Sin mediciones';
const String mensajeSinMedicion = 'Sin medición';

/// La *Tabla de indicadores* de los requisitos.
const List<Indicador> indicadores = [
  Indicador(
    id: IdIndicador.reingreso,
    nombre: 'Reingreso hospitalario a 30 días',
    categoria: 'Resultado',
    descripcion:
        'Pacientes que vuelven a hospitalizarse en los 30 días siguientes al '
        'alta, sobre el total de egresos.',
    unidad: '%',
    unidadCambio: 'puntos',
    minimo: 0,
    maximo: 100,
    direccion: DireccionIndicador.masBajoEsMejor,
    tiposSede: {TipoSede.clinica},
  ),
  Indicador(
    id: IdIndicador.espera,
    nombre: 'Tiempo de espera promedio',
    categoria: 'Estructura',
    descripcion:
        'Minutos que tarda en atenderse un paciente desde que llega a la sede.',
    unidad: 'min',
    unidadCambio: 'min',
    minimo: 0,
    maximo: 1440,
    direccion: DireccionIndicador.masBajoEsMejor,
    tiposSede: {TipoSede.clinica, TipoSede.centroAmbulatorio},
  ),
  Indicador(
    id: IdIndicador.adherencia,
    nombre: 'Adherencia a protocolos clínicos',
    categoria: 'Proceso',
    descripcion:
        'Porcentaje de atenciones que cumplen el protocolo clínico definido.',
    unidad: '%',
    unidadCambio: 'puntos',
    minimo: 0,
    maximo: 100,
    direccion: DireccionIndicador.masAltoEsMejor,
    tiposSede: {TipoSede.clinica, TipoSede.centroAmbulatorio},
  ),
  Indicador(
    id: IdIndicador.eventos,
    nombre: 'Eventos adversos evitables',
    categoria: 'Resultado',
    descripcion:
        'Incidentes dañinos para el paciente que se pudieron prevenir, por '
        'cada 1.000 atenciones.',
    unidad: 'por 1.000',
    unidadCambio: 'por 1.000',
    minimo: 0,
    maximo: 1000,
    direccion: DireccionIndicador.masBajoEsMejor,
    tiposSede: {TipoSede.clinica, TipoSede.centroAmbulatorio},
  ),
];

Indicador indicadorDe(IdIndicador id) =>
    indicadores.firstWhere((i) => i.id == id);

bool aplica(Indicador indicador, TipoSede tipo) =>
    indicador.tiposSede.contains(tipo);

// ---------------------------------------------------------------------------
// Periodos
// ---------------------------------------------------------------------------

DateTime _mes(DateTime f) => DateTime(f.year, f.month);

/// Un mes cierra cuando termina: el de noviembre se puede registrar desde el
/// 1 de diciembre (RF-29).
bool mesCerrado(DateTime periodo, DateTime hoy) =>
    _mes(periodo).isBefore(_mes(hoy));

/// Los últimos [cantidad] meses cerrados, del más antiguo al más reciente.
List<DateTime> periodosCerrados(DateTime hoy, {int cantidad = mesesVisibles}) {
  final ultimo = DateTime(hoy.year, hoy.month - 1);
  return [
    for (var i = cantidad - 1; i >= 0; i--)
      DateTime(ultimo.year, ultimo.month - i),
  ];
}

/// El mes cerrado más reciente (F-08): el último periodo.
DateTime ultimoPeriodo(DateTime hoy) =>
    periodosCerrados(hoy, cantidad: 1).first;

// ---------------------------------------------------------------------------
// Promedio, marca y cambio
// ---------------------------------------------------------------------------

Iterable<Medicion> _de(
  Iterable<Medicion> todas,
  IdIndicador id,
  DateTime periodo,
) => todas.where((m) => m.indicador == id && _mes(m.periodo) == _mes(periodo));

/// El valor de la red: el promedio simple de las sedes que tienen medición
/// en ese periodo (RF-26). Vacío si ninguna la tiene.
double? valorRed(Iterable<Medicion> todas, IdIndicador id, DateTime periodo) {
  final mediciones = _de(todas, id, periodo).toList();
  if (mediciones.isEmpty) return null;
  final suma = mediciones.fold<double>(0, (a, m) => a + m.valor);
  return suma / mediciones.length;
}

/// Compara la sede con la red, ambos redondeados a 1 decimal, según la
/// dirección del indicador (RF-09).
MarcaSede marcaDe(double sede, double red, Indicador indicador) {
  final s = redondear1(sede);
  final r = redondear1(red);
  if (s == r) return MarcaSede.igual;
  final mejorEsBajo = indicador.direccion == DireccionIndicador.masBajoEsMejor;
  return (s < r) == mejorEsBajo ? MarcaSede.mejor : MarcaSede.peor;
}

/// Si pasar de [anterior] a [actual] es para mejor. `null` si no cambió.
bool? mejoro(Indicador indicador, double actual, double anterior) {
  final a = redondear1(actual);
  final b = redondear1(anterior);
  if (a == b) return null;
  final mejorEsBajo = indicador.direccion == DireccionIndicador.masBajoEsMejor;
  return (a < b) == mejorEsBajo;
}

/// El cambio frente al periodo anterior, con signo y en la unidad del
/// indicador: "−1,2 puntos", "+5 min" o "+0,3 por 1.000" (RF-27). Sin cambio
/// es "0,0" sin signo. Se calcula con los valores redondeados a 1 decimal.
String textoCambio(Indicador indicador, double actual, double anterior) {
  final d = redondear1(redondear1(actual) - redondear1(anterior));
  final signo = d > 0 ? '+' : (d < 0 ? '−' : '');
  final valor = formatoValor(d.abs());
  // En minutos se escribe entero ("+5 min"); el cero siempre es "0,0".
  final numero = indicador.unidadCambio == 'min' && d != 0
      ? valor.replaceFirst(RegExp(r',0$'), '')
      : valor;
  return '$signo$numero ${indicador.unidadCambio}';
}

// ---------------------------------------------------------------------------
// Lo que muestran el tablero y el detalle
// ---------------------------------------------------------------------------

/// El resumen de cada indicador en el tablero (F-08).
List<ResumenIndicador> resumenes(Iterable<Medicion> todas, DateTime hoy) {
  final periodos = periodosCerrados(hoy);
  return [
    for (final ind in indicadores)
      () {
        final actual = valorRed(todas, ind.id, periodos.last);
        final previo = valorRed(todas, ind.id, periodos[periodos.length - 2]);
        return ResumenIndicador(
          indicador: ind,
          valorRed: actual,
          cambio: actual != null && previo != null
              ? textoCambio(ind, actual, previo)
              : null,
          mejoro: actual != null && previo != null
              ? mejoro(ind, actual, previo)
              : null,
          tendencia: [for (final p in periodos) ?valorRed(todas, ind.id, p)],
        );
      }(),
  ];
}

/// Cuántos indicadores empeoraron frente al mes previo (Inicio del médico).
int indicadoresQueEmpeoraron(Iterable<ResumenIndicador> resumenes) =>
    resumenes.where((r) => r.mejoro == false).length;

/// La tendencia de los últimos meses de [id]: de toda la red o, con
/// [sedeId], de una sede. Los meses sin dato quedan sin valor (F-09).
List<PuntoTendencia> tendenciaDe(
  Iterable<Medicion> todas,
  IdIndicador id,
  DateTime hoy, {
  String? sedeId,
}) {
  return [
    for (final p in periodosCerrados(hoy))
      PuntoTendencia(
        periodo: p,
        valor: sedeId == null
            ? valorRed(todas, id, p)
            : _de(todas, id, p)
                  .where((m) => m.sedeId == sedeId)
                  .map((m) => m.valor)
                  .firstOrNull,
      ),
  ];
}

/// Las sedes a las que aplica [indicador], con su valor del último periodo,
/// ordenadas de la peor a la mejor según la dirección (F-08, F-10): del valor
/// más alto al más bajo cuando es mejor uno bajo, y al revés si es mejor uno
/// alto; con el mismo valor, por nombre. Las que no tienen medición
/// van al final y no entran en el promedio (F-10).
List<FilaSede> comparacionDe(
  Iterable<Medicion> todas,
  Indicador indicador,
  List<Sede> sedes,
  DateTime hoy,
) {
  final periodo = ultimoPeriodo(hoy);
  final red = valorRed(todas, indicador.id, periodo);
  final filas = [
    for (final s in sedes)
      if (aplica(indicador, s.tipo))
        () {
          final v = _de(
            todas,
            indicador.id,
            periodo,
          ).where((m) => m.sedeId == s.id).map((m) => m.valor).firstOrNull;
          return FilaSede(
            sedeId: s.id,
            nombre: s.nombreCorto,
            valor: v,
            marca: v != null && red != null ? marcaDe(v, red, indicador) : null,
          );
        }(),
  ];
  final mejorEsBajo = indicador.direccion == DireccionIndicador.masBajoEsMejor;
  filas.sort((a, b) {
    if (a.valor == null || b.valor == null) {
      if (a.valor == b.valor) return a.nombre.compareTo(b.nombre);
      return a.valor == null ? 1 : -1;
    }
    final porValor = mejorEsBajo
        ? b.valor!.compareTo(a.valor!)
        : a.valor!.compareTo(b.valor!);
    return porValor != 0 ? porValor : a.nombre.compareTo(b.nombre);
  });
  return filas;
}

/// Las mediciones de los últimos 6 meses cerrados: el periodo más reciente
/// primero y, dentro de él, las sedes por nombre (F-11).
List<FilaMedicion> medicionesRecientes(
  Iterable<Medicion> todas,
  Indicador indicador,
  List<Sede> sedes,
  DateTime hoy,
) {
  final filas = <FilaMedicion>[];
  for (final periodo in periodosCerrados(hoy).reversed) {
    final red = valorRed(todas, indicador.id, periodo);
    final delPeriodo = [
      for (final m in _de(todas, indicador.id, periodo))
        if (sedes.where((s) => s.id == m.sedeId).firstOrNull case final s?)
          if (aplica(indicador, s.tipo)) (s, m),
    ]..sort((a, b) => a.$1.nombreCorto.compareTo(b.$1.nombreCorto));
    for (final (sede, m) in delPeriodo) {
      filas.add(
        FilaMedicion(
          periodo: periodo,
          sedeId: sede.id,
          sedeNombre: sede.nombreCorto,
          valor: m.valor,
          marca: red == null
              ? MarcaSede.igual
              : marcaDe(m.valor, red, indicador),
        ),
      );
    }
  }
  return filas;
}

// ---------------------------------------------------------------------------
// Validar una medición (RF-13, RF-28, RF-29, RF-30)
// ---------------------------------------------------------------------------

/// Un número con coma decimal y, si quiere, punto de miles (RNF-05).
final _conMiles = RegExp(r'^-?\d{1,3}(\.\d{3})+(,\d+)?$');
final _sencillo = RegExp(r'^-?\d+([.,]\d+)?$');

/// Deja el texto como un número que Dart entiende: la coma es el separador
/// decimal y el punto solo es de miles con el patrón `1.440` o `1.440,5`;
/// en otro caso el punto es decimal ("8.5"). `null` si no es un número.
String? _normalizar(String texto) {
  final limpio = texto.trim();
  if (_conMiles.hasMatch(limpio)) {
    return limpio.replaceAll('.', '').replaceAll(',', '.');
  }
  if (_sencillo.hasMatch(limpio)) return limpio.replaceAll(',', '.');
  return null;
}

/// Lee un valor escrito con coma o con punto, con signo menos si lo tiene.
/// `null` si no es un número.
double? leerValor(String texto) {
  final normal = _normalizar(texto);
  return normal == null ? null : double.tryParse(normal);
}

/// Cuántos decimales escribió el usuario, sin contar ceros de más.
int _decimales(String texto) {
  final limpio = _normalizar(texto) ?? '';
  final i = limpio.indexOf('.');
  if (i < 0) return 0;
  // "8,50" vale como "8,5": los ceros al final no cuentan.
  return limpio.substring(i + 1).replaceFirst(RegExp(r'0+$'), '').length;
}

/// El rango de un indicador como se muestra en el mensaje (F-12 A1).
String textoRango(Indicador indicador) =>
    'El valor debe estar entre ${_entero(indicador.minimo)} y '
    '${_entero(indicador.maximo)}';

String _entero(double v) {
  final n = v.round().toString();
  final grupos = <String>[];
  for (var i = n.length; i > 0; i -= 3) {
    grupos.insert(0, n.substring(i - 3 < 0 ? 0 : i - 3, i));
  }
  return grupos.join('.');
}

/// Valida una medición antes de guardarla. Devuelve el mensaje de rechazo o
/// `null` si se puede guardar. Es el único lugar donde se valida (AD-11).
String? validarMedicion({
  required Indicador indicador,
  required Sede sede,
  required DateTime periodo,
  required String valorTexto,
  required DateTime hoy,
  required Iterable<Medicion> existentes,
}) {
  if (!aplica(indicador, sede.tipo)) return mensajeNoAplica;
  if (!mesCerrado(periodo, hoy)) return mensajeMesAbierto;
  final repetida = _de(
    existentes,
    indicador.id,
    periodo,
  ).any((m) => m.sedeId == sede.id);
  if (repetida) return mensajeMedicionRepetida;
  final valor = leerValor(valorTexto);
  if (valor == null) return mensajeValorVacio;
  if (_decimales(valorTexto) > 1) return mensajeUnDecimal;
  if (valor < indicador.minimo || valor > indicador.maximo) {
    return textoRango(indicador);
  }
  return null;
}
