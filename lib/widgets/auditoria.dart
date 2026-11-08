import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/campo_dato.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Una fila de la tabla de eventos, ya con los textos que se muestran.
typedef FilaEvento = ({
  String fechaHora,
  String usuario,
  String accion,
  String recurso,
  String paciente,
  String proposito,

  /// El propósito con su aclaración, por ejemplo "Urgencia (acceso de
  /// emergencia)", para la tabla de computador.
  String propositoCompleto,
  bool emergencia,
  ResultadoAuditoria resultado,
  String sede,
  String ip,
});

/// Columnas de la tabla de computador. El peso reparte el espacio que sobra
/// después de darle a cada columna su ancho mínimo. La IP va debajo del usuario y la sede al
/// final, para no perder ninguno de los datos de F-21.
typedef _ColumnaCompleta = ({String titulo, int peso});

const List<_ColumnaCompleta> _columnasCompletas = [
  (titulo: 'Fecha y hora', peso: 13),
  (titulo: 'Usuario', peso: 13),
  (titulo: 'Acción', peso: 8),
  (titulo: 'Recurso', peso: 12),
  (titulo: 'Paciente', peso: 16),
  (titulo: 'Propósito', peso: 21),
  (titulo: 'Resultado', peso: 12),
  (titulo: 'Sede', peso: 12),
];

/// Eventos de la auditoría (F-21). En computador es una tabla; en celular
/// (menos de [anchoEscritorio]) cada evento es una tarjeta vertical, sin
/// desplazamiento lateral (RNF-07). Solo muestra: no ofrece ninguna opción
/// para editar ni borrar eventos (AD-08).
class TablaEventos extends StatelessWidget {
  const TablaEventos({
    super.key,
    required this.filas,
    required this.mensajeVacio,
  });

  final List<FilaEvento> filas;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return EstadoVacio(
        titulo: mensajeVacio,
        icono: Icons.filter_alt_off_outlined,
      );
    }
    if (MediaQuery.sizeOf(context).width < anchoEscritorio) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final f in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TarjetaEvento(fila: f),
            ),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TarjetaVitalys.radioTarjeta),
        boxShadow: [
          BoxShadow(
            color: ColoresVitalys.tinta.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TarjetaVitalys(
        relleno: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TarjetaVitalys.radioTarjeta - 1),
          child: _TablaCompleta(filas: filas),
        ),
      ),
    );
  }
}

/// Un evento de la auditoría como tarjeta vertical, para celular. Cada campo
/// es "Etiqueta: valor" y se lee como un solo texto.
class TarjetaEvento extends StatelessWidget {
  const TarjetaEvento({super.key, required this.fila});

  final FilaEvento fila;

  @override
  Widget build(BuildContext context) {
    final e = fila;
    final permitido = e.resultado == ResultadoAuditoria.permitido;
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(16),
      radio: TarjetaVitalys.radioFila,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                e.fechaHora,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ColoresVitalys.tinta,
                ),
              ),
              ChipVitalys(
                texto: e.resultado.nombre,
                icono: permitido
                    ? Icons.check_rounded
                    : Icons.lock_outline_rounded,
                tamanoTexto: 12.5,
                colorFondo: permitido
                    ? ColoresVitalys.exitoFondo
                    : ColoresVitalys.alertaFondo,
                colorTexto: permitido
                    ? ColoresVitalys.mentaTexto
                    : ColoresVitalys.alertaTexto,
              ),
            ],
          ),
          const SizedBox(height: 6),
          DatoEnLinea(etiqueta: 'Usuario', valor: e.usuario, sinPartir: true),
          DatoEnLinea(etiqueta: 'Acción', valor: e.accion),
          DatoEnLinea(etiqueta: 'Recurso', valor: e.recurso),
          DatoEnLinea(etiqueta: 'Paciente', valor: e.paciente),
          DatoEnLinea(etiqueta: 'Propósito', valor: e.proposito),
          DatoEnLinea(etiqueta: 'Sede', valor: e.sede),
          if (e.ip != '—')
            DatoEnLinea(etiqueta: 'IP', valor: e.ip, sinPartir: true),
        ],
      ),
    );
  }
}

/// Mide textos con la fuente y la escala de texto de la pantalla, para que
/// las columnas de la tabla nunca partan una palabra.
class _Medidor {
  _Medidor(BuildContext context)
    : _base = DefaultTextStyle.of(context).style,
      _escala = MediaQuery.textScalerOf(context);

  final TextStyle _base;
  final TextScaler _escala;

  /// Ancho del texto en una sola línea.
  double ancho(String texto, TextStyle estilo) {
    final pintor = TextPainter(
      text: TextSpan(text: texto, style: _base.merge(estilo)),
      textDirection: TextDirection.ltr,
      textScaler: _escala,
      maxLines: 1,
    )..layout();
    final medida = pintor.width;
    pintor.dispose();
    return medida.ceilToDouble() + 2;
  }

  /// Ancho de la palabra más larga del texto.
  double palabraMasLarga(String texto, TextStyle estilo) => texto
      .split(RegExp(r'\s+'))
      .fold(0, (a, p) => a > ancho(p, estilo) ? a : ancho(p, estilo));
}

/// La tabla de computador (Figma, pantalla 8), con celdas amplias y las
/// marcas de resultado y de emergencia con su ícono.
///
/// Ninguna palabra se parte: cada columna mide lo que necesita su palabra
/// más larga (la fecha y la pastilla de resultado, completas), y el espacio
/// que sobra se reparte según el peso de la columna. Si la ventana no
/// alcanza para todas, la tabla se desliza hacia los lados.
class _TablaCompleta extends StatelessWidget {
  const _TablaCompleta({required this.filas});

  final List<FilaEvento> filas;

  static const double _relleno = 10;

  /// Lo que ocupa la pastilla además del texto: relleno e ícono.
  static const double _marcoPastilla = 12 * 2 + 16 + 6;
  static const double _tamanoPastilla = 15;
  static const _estiloPastilla = TextStyle(
    fontSize: _tamanoPastilla,
    fontWeight: FontWeight.w700,
  );

  static const _estiloTitulo = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    color: ColoresVitalys.textoSecundario,
  );
  static const _estiloCelda = TextStyle(
    fontSize: 15.5,
    height: 1.5,
    color: ColoresVitalys.tinta,
  );
  static const _estiloIp = TextStyle(
    fontSize: 13,
    color: ColoresVitalys.textoSecundario,
  );

  /// Ancho mínimo de cada columna, con su relleno, medido con la fuente y
  /// la escala de texto de la pantalla.
  List<double> _minimos(BuildContext context) {
    final medidor = _Medidor(context);
    final ancho = medidor.ancho;
    final palabraMasLarga = medidor.palabraMasLarga;

    final minimos = [
      for (final c in _columnasCompletas)
        palabraMasLarga(c.titulo.toUpperCase(), _estiloTitulo),
    ];
    void ajustar(int i, double medida) {
      if (medida > minimos[i]) minimos[i] = medida;
    }

    for (final e in filas) {
      // La fecha y la hora van en una sola línea, como en el Figma.
      ajustar(0, ancho(e.fechaHora, _estiloCelda));
      ajustar(1, palabraMasLarga(e.usuario, _estiloCelda));
      if (e.ip != '—') ajustar(1, palabraMasLarga('IP ${e.ip}', _estiloIp));
      ajustar(2, palabraMasLarga(e.accion, _estiloCelda));
      ajustar(3, palabraMasLarga(e.recurso, _estiloCelda));
      ajustar(4, palabraMasLarga(e.paciente, _estiloCelda));
      ajustar(
        5,
        e.emergencia
            ? _AvisoEmergencia.marco +
                  palabraMasLarga(e.propositoCompleto, _AvisoEmergencia.estilo)
            : palabraMasLarga(e.propositoCompleto, _estiloCelda),
      );
      // La pastilla de resultado nunca parte su texto.
      ajustar(6, _marcoPastilla + ancho(e.resultado.nombre, _estiloPastilla));
      ajustar(7, palabraMasLarga(e.sede, _estiloCelda));
    }
    return [for (final m in minimos) m + _relleno * 2];
  }

  @override
  Widget build(BuildContext context) {
    final minimos = _minimos(context);
    final totalMinimo = minimos.fold<double>(_relleno * 2, (a, m) => a + m);
    final pesoTotal = _columnasCompletas.fold<int>(0, (a, c) => a + c.peso);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= totalMinimo) {
          final sobra = c.maxWidth - totalMinimo;
          return _cuerpo([
            for (var i = 0; i < minimos.length; i++)
              minimos[i] + sobra * _columnasCompletas[i].peso / pesoTotal,
          ]);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: totalMinimo, child: _cuerpo(minimos)),
        );
      },
    );
  }

  Widget _cuerpo(List<double> anchos) {
    Widget celda(int i, Widget hijo) => SizedBox(
      width: anchos[i],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _relleno),
        child: hijo,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: ColoresVitalys.fondo,
          padding: const EdgeInsets.symmetric(
            horizontal: _relleno,
            vertical: 22,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _columnasCompletas.length; i++)
                celda(
                  i,
                  Text(
                    _columnasCompletas[i].titulo.toUpperCase(),
                    style: _estiloTitulo,
                  ),
                ),
            ],
          ),
        ),
        for (var f = 0; f < filas.length; f++)
          Container(
            constraints: const BoxConstraints(minHeight: 78),
            decoration: BoxDecoration(
              border: f == filas.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: ColoresVitalys.borde),
                    ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: _relleno,
              vertical: 14,
            ),
            child: Row(children: _celdasDe(filas[f], celda)),
          ),
      ],
    );
  }

  List<Widget> _celdasDe(FilaEvento e, Widget Function(int, Widget) celda) {
    final permitido = e.resultado == ResultadoAuditoria.permitido;
    return [
      celda(0, Text(e.fechaHora, style: _estiloCelda, softWrap: false)),
      celda(
        1,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.usuario, style: _estiloCelda),
            // La IP solo existe en los inicios de sesión fallidos.
            if (e.ip != '—') Text('IP ${e.ip}', style: _estiloIp),
          ],
        ),
      ),
      celda(2, Text(e.accion, style: _estiloCelda)),
      celda(3, Text(e.recurso, style: _estiloCelda)),
      celda(4, Text(e.paciente, style: _estiloCelda)),
      celda(
        5,
        e.emergencia
            ? Align(
                alignment: Alignment.centerLeft,
                child: _AvisoEmergencia(texto: e.propositoCompleto),
              )
            : Text(e.propositoCompleto, style: _estiloCelda),
      ),
      celda(
        6,
        Align(
          alignment: Alignment.centerLeft,
          child: ChipVitalys(
            texto: e.resultado.nombre,
            icono: permitido ? Icons.check_rounded : Icons.lock_outline_rounded,
            tamanoTexto: _tamanoPastilla,
            colorFondo: permitido
                ? ColoresVitalys.exitoFondo
                : ColoresVitalys.alertaFondo,
            colorTexto: permitido
                ? ColoresVitalys.mentaTexto
                : ColoresVitalys.alertaTexto,
          ),
        ),
      ),
      celda(7, Text(e.sede, style: _estiloCelda)),
    ];
  }
}

/// El propósito de un acceso de emergencia en la tabla: sobre la superficie
/// de la galería, con un ícono, y que parte el texto en líneas si hace falta.
class _AvisoEmergencia extends StatelessWidget {
  const _AvisoEmergencia({required this.texto});

  final String texto;

  static const estilo = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ColoresVitalys.alertaTexto,
  );

  /// Lo que ocupa además del texto: relleno e ícono.
  static const double marco = 12 * 2 + 18 + 8;

  @override
  Widget build(BuildContext context) {
    return TarjetaVitalys(
      relleno: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radio: TarjetaVitalys.radioFila,
      color: ColoresVitalys.alertaFondo,
      colorBorde: ColoresVitalys.alertaFondo,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: ColoresVitalys.alertaTexto,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(texto, style: estilo)),
        ],
      ),
    );
  }
}
