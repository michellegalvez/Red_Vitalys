import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/indicadores/barras_por_sede.dart';
import 'package:red_vitalys/widgets/indicadores/estilo_marca.dart';
import 'package:red_vitalys/widgets/indicadores/grafica_tendencia.dart';
import 'package:red_vitalys/widgets/indicadores/resumen_sede.dart';
import 'package:red_vitalys/widgets/indicadores/selector_indicador.dart';
import 'package:red_vitalys/widgets/indicadores/tabla_mediciones.dart';
import 'package:red_vitalys/widgets/indicadores/tarjeta_indicador.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

const _anchoDosColumnas = 700.0;
const _anchoCuatroColumnas = 1000.0;
const _estiloSecundario = TextStyle(
  color: ColoresVitalys.textoSecundario,
  height: 1.4,
  fontSize: 14,
);

Widget _titulo(BuildContext context, String texto) => Semantics(
  header: true,
  child: Text(texto, style: Theme.of(context).textTheme.headlineSmall),
);

/// Tablero de indicadores de calidad (F-08): el valor de la red de cada
/// indicador, su cambio frente al mes previo y las sedes donde actuar primero.
/// Solo muestra y avisa: abrir el detalle lo decide la Screen anfitriona.
class IndicadoresPage extends StatelessWidget {
  const IndicadoresPage({
    super.key,
    required this.resumenes,
    required this.destacado,
    required this.comparacionDestacada,
    required this.promedioDestacado,
    required this.periodo,
    required this.onElegirDestacado,
    required this.onAbrirDetalle,
  });

  final List<ResumenIndicador> resumenes;

  /// El indicador que se explica abajo, con las sedes frente al promedio.
  final Indicador destacado;

  /// Las sedes del indicador destacado, de la mejor a la peor.
  final List<FilaSede> comparacionDestacada;
  final double? promedioDestacado;

  /// El último mes cerrado, al que corresponden los valores.
  final DateTime periodo;
  final ValueChanged<IdIndicador> onElegirDestacado;
  final ValueChanged<IdIndicador> onAbrirDetalle;

  String get _descripcionSedes {
    final base =
        '${destacado.nombre} por sede en el último periodo '
        '(${formatoPeriodo(periodo)})';
    final media = promedioDestacado;
    final frente = media == null
        ? ''
        : ', frente al promedio de la red '
              '(${formatoValor(media)} ${destacado.unidad})';
    return '$base$frente. ${textoDireccion(destacado.direccion)}.';
  }

  @override
  Widget build(BuildContext context) {
    final dePeorAMejor = comparacionDestacada.reversed.toList();
    final ordenadas = [
      ...dePeorAMejor.where((f) => f.valor != null),
      ...dePeorAMejor.where((f) => f.valor == null),
    ];
    return ContenidoPagina(
      children: [
        const EncabezadoPagina(
          sobretitulo: 'Calidad clínica · toda la red',
          titulo: 'Tablero de indicadores',
          subtitulo:
              'Cuatro indicadores de estructura, proceso y resultado, '
              'calculados con las mediciones de cada sede.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final columnas = c.maxWidth >= _anchoCuatroColumnas
                ? 4
                : (c.maxWidth >= _anchoDosColumnas ? 2 : 1);
            const separacion = 16.0;
            final ancho = (c.maxWidth - separacion * (columnas - 1)) / columnas;
            return Wrap(
              spacing: separacion,
              runSpacing: separacion,
              children: [
                for (final r in resumenes)
                  SizedBox(
                    width: ancho,
                    child: TarjetaIndicador(
                      resumen: r,
                      periodo: periodo,
                      onTap: () => onAbrirDetalle(r.indicador.id),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        TarjetaVitalys(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo(context, 'Dónde actuar primero'),
              const SizedBox(height: 12),
              SelectorIndicador(
                indicadores: [for (final r in resumenes) r.indicador],
                seleccionado: destacado.id,
                onElegir: onElegirDestacado,
              ),
              const SizedBox(height: 12),
              Text(_descripcionSedes, style: _estiloSecundario),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onAbrirDetalle(destacado.id),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Ver detalle'),
                  style: TextButton.styleFrom(
                    foregroundColor: ColoresVitalys.primario,
                    minimumSize: const Size(48, 44),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, c) {
                  final ancha = c.maxWidth >= _anchoDosColumnas;
                  final ancho = ancha ? (c.maxWidth - 20) / 2 : c.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      for (final fila in ordenadas)
                        SizedBox(
                          width: ancho,
                          child: ResumenSede(fila: fila),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TarjetaVitalys(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo(context, '${destacado.nombre} por sede, de peor a mejor'),
              const SizedBox(height: 5),
              const Text(
                'La línea punteada marca el promedio de la red.',
                style: _estiloSecundario,
              ),
              const SizedBox(height: 18),
              BarrasPorSede(
                filas: ordenadas,
                promedio: promedioDestacado,
                unidad: destacado.unidad,
              ),
              const SizedBox(height: 16),
              const LeyendaDesempeno(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Detalle de un indicador (F-09, F-10, F-11): la tendencia de la red o de
/// una sede, la comparación entre sedes y las mediciones recientes. Solo
/// muestra y avisa: elegir la sede y volver lo decide la Screen anfitriona.
class DetalleIndicadorPage extends StatelessWidget {
  const DetalleIndicadorPage({
    super.key,
    required this.indicador,
    required this.sedesDisponibles,
    required this.sedeTendencia,
    required this.tendencia,
    required this.comparacion,
    required this.promedio,
    required this.mediciones,
    required this.onElegirSede,
    required this.onVolver,
  });

  final Indicador indicador;

  /// Las sedes a las que aplica el indicador, para el selector.
  final List<Sede> sedesDisponibles;

  /// La sede de la tendencia. `null` es *Toda la red* (F-09).
  final String? sedeTendencia;
  final List<PuntoTendencia> tendencia;
  final List<FilaSede> comparacion;

  /// El valor de la red del último periodo.
  final double? promedio;
  final List<FilaMedicion> mediciones;
  final ValueChanged<String?> onElegirSede;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final conDato = tendencia.where((p) => p.valor != null).toList();
    final ultimo = conDato.isEmpty ? null : conDato.last.valor;
    final sinMedicion = [
      for (final p in tendencia)
        if (p.valor == null) formatoPeriodo(p.periodo),
    ];
    final hayComparables = comparacion.any((f) => f.valor != null);
    final tema = Theme.of(context).textTheme;
    return ContenidoPagina(
      children: [
        _MigasDePan(nombre: indicador.nombre, onVolver: onVolver),
        const SizedBox(height: 18),
        Text(
          '${indicador.categoria} · ${indicador.unidad}',
          style: const TextStyle(
            color: ColoresVitalys.primario,
            fontSize: 12.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(indicador.nombre, style: tema.displaySmall),
        ),
        const SizedBox(height: 12),
        Text(
          indicador.descripcion,
          style: const TextStyle(
            fontSize: 16,
            height: 1.45,
            color: ColoresVitalys.textoSecundario,
          ),
        ),
        const SizedBox(height: 6),
        Text(textoDireccion(indicador.direccion), style: _estiloSecundario),
        const SizedBox(height: 22),
        TarjetaVitalys(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo(context, 'Tendencia mensual'),
              const SizedBox(height: 4),
              Text(
                ultimo == null
                    ? 'Sin mediciones en los últimos $mesesVisibles meses'
                    : 'Último periodo: ${formatoValor(ultimo)} '
                          '${indicador.unidad}',
                style: _estiloSecundario,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                child: SelectorVitalys<String?>(
                  valor: sedeTendencia,
                  hint: 'Toda la red',
                  opciones: [
                    (null, 'Toda la red'),
                    for (final s in sedesDisponibles) (s.id, s.nombreCorto),
                  ],
                  onChanged: onElegirSede,
                ),
              ),
              const SizedBox(height: 18),
              if (conDato.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No hay mediciones en los últimos 6 meses',
                    style: _estiloSecundario,
                  ),
                )
              else ...[
                SizedBox(
                  height: 205,
                  width: double.infinity,
                  child: GraficaTendencia(
                    valores: [for (final p in tendencia) p.valor],
                    rotulos: [for (final p in tendencia) mesCorto(p.periodo)],
                    unidad: indicador.unidad,
                    relleno: true,
                  ),
                ),
                if (sinMedicion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sin medición: ${sinMedicion.join(', ')}',
                    style: const TextStyle(
                      color: ColoresVitalys.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        TarjetaVitalys(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo(context, 'Comparación entre sedes'),
              const SizedBox(height: 7),
              const Text(
                'Último periodo · línea punteada: promedio de la red',
                style: _estiloSecundario,
              ),
              const SizedBox(height: 16),
              if (!hayComparables)
                const Text(
                  'No hay mediciones en el último periodo',
                  style: _estiloSecundario,
                )
              else ...[
                BarrasPorSede(
                  filas: comparacion,
                  promedio: promedio,
                  unidad: indicador.unidad,
                  compacta: true,
                ),
                const SizedBox(height: 14),
                const LeyendaDesempeno(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _titulo(context, 'Mediciones recientes'),
        const SizedBox(height: 6),
        Text(
          mediciones.length == 1
              ? '1 medición'
              : '${mediciones.length} mediciones',
          style: _estiloSecundario,
        ),
        const SizedBox(height: 10),
        TablaMediciones(indicador: indicador, filas: mediciones),
      ],
    );
  }
}

/// "Indicadores / Nombre": vuelve al tablero desde el detalle.
class _MigasDePan extends StatelessWidget {
  const _MigasDePan({required this.nombre, required this.onVolver});

  final String nombre;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onVolver,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 17,
                    color: ColoresVitalys.textoSecundario,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Indicadores',
                    style: TextStyle(
                      color: ColoresVitalys.textoSecundario,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '/',
            style: TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ),
        Expanded(
          child: Text(
            nombre,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ),
      ],
    );
  }
}
