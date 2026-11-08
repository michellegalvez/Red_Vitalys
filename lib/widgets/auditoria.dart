import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';

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

/// Una columna de la tabla de celular, con su ancho fijo: la tabla se
/// desliza hacia los lados.
typedef _Columna = ({String titulo, double ancho});

const List<_Columna> _columnas = [
  (titulo: 'Fecha y hora', ancho: 142),
  (titulo: 'Usuario', ancho: 100),
  (titulo: 'Acción', ancho: 92),
  (titulo: 'Recurso', ancho: 150),
  (titulo: 'Paciente', ancho: 180),
  (titulo: 'Propósito', ancho: 170),
  (titulo: 'Resultado', ancho: 118),
  (titulo: 'Sede', ancho: 180),
  (titulo: 'IP', ancho: 120),
];

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

/// Margen a cada lado de las filas, que se suma al ancho de la tabla.
const double _margenFila = 4;

/// Tabla de eventos de la auditoría (F-21). En celular muestra la fecha y
/// hora, el usuario y la acción, y se desliza hacia los lados para ver el
/// resto; en computador se ve completa. Solo muestra: no ofrece ninguna
/// opción para editar ni borrar eventos (AD-08).
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColoresVitalys.tinta.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColoresVitalys.borde),
        ),
        child: Builder(
          builder: (context) {
            if (MediaQuery.sizeOf(context).width >= anchoEscritorio) {
              return _TablaCompleta(filas: filas, mensajeVacio: mensajeVacio);
            }
            final anchos = _Tabla.medirAnchos(context, filas);
            final tabla = _Tabla(
              filas: filas,
              anchos: anchos,
              mensajeVacio: mensajeVacio,
            );
            final anchoTotal = anchos.fold<double>(
              _margenFila * 2,
              (a, ancho) => a + ancho,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Text(
                    'Deslice la tabla hacia la derecha para ver recurso, '
                    'paciente, propósito, resultado, sede e IP.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: ColoresVitalys.textoSecundario,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: anchoTotal,
                    // El estado vacío se queda a la vista, sin deslizar.
                    child: filas.isEmpty
                        ? _Tabla(filas: [], anchos: anchos, mensajeVacio: null)
                        : tabla,
                  ),
                ),
                if (filas.isEmpty) _Vacio(mensaje: mensajeVacio),
              ],
            );
          },
        ),
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

/// La tabla de celular, con columnas de ancho fijo que solo crecen si una
/// palabra no cabe, por ejemplo el correo de un ingreso fallido.
class _Tabla extends StatelessWidget {
  const _Tabla({
    required this.filas,
    required this.anchos,
    required this.mensajeVacio,
  });

  final List<FilaEvento> filas;

  /// Ancho de cada columna, de [_Tabla.medirAnchos].
  final List<double> anchos;

  /// Sin mensaje, la tabla vacía muestra solo los títulos.
  final String? mensajeVacio;

  static const double _relleno = 12;

  static const _estiloCelda = TextStyle(
    fontSize: 13.5,
    height: 1.4,
    color: ColoresVitalys.tinta,
  );

  /// El ancho fijo de cada columna, o más si su palabra más larga no cabe.
  /// Las pastillas de propósito y resultado son de una palabra y caben en
  /// su ancho fijo.
  static List<double> medirAnchos(
    BuildContext context,
    List<FilaEvento> filas,
  ) {
    final medidor = _Medidor(context);
    final anchos = [for (final c in _columnas) c.ancho];
    void ajustar(int i, String texto) {
      final necesario =
          medidor.palabraMasLarga(texto, _estiloCelda) + _relleno * 2;
      if (necesario > anchos[i]) anchos[i] = necesario;
    }

    for (final e in filas) {
      ajustar(0, e.fechaHora);
      ajustar(1, e.usuario);
      ajustar(2, e.accion);
      ajustar(3, e.recurso);
      ajustar(4, e.paciente);
      if (!e.emergencia) ajustar(5, e.proposito);
      ajustar(7, e.sede);
      ajustar(8, e.ip);
    }
    return anchos;
  }

  Widget _celda(int i, Widget hijo) {
    return SizedBox(
      width: anchos[i],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _relleno),
        child: hijo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mensaje = mensajeVacio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: ColoresVitalys.fondo,
          padding: const EdgeInsets.symmetric(
            horizontal: _margenFila,
            vertical: 14,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _columnas.length; i++)
                _celda(
                  i,
                  Text(
                    _columnas[i].titulo.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: ColoresVitalys.textoSecundario,
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var f = 0; f < filas.length; f++)
          Container(
            decoration: BoxDecoration(
              border: f == filas.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: ColoresVitalys.borde),
                    ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: _margenFila,
              vertical: 20,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _celdasDe(filas[f]),
            ),
          ),
        if (filas.isEmpty && mensaje != null) _Vacio(mensaje: mensaje),
      ],
    );
  }

  List<Widget> _celdasDe(FilaEvento e) {
    final textos = [e.fechaHora, e.usuario, e.accion, e.recurso, e.paciente];
    return [
      for (var i = 0; i < textos.length; i++) _celda(i, _TextoCelda(textos[i])),
      _celda(
        5,
        e.emergencia
            ? Align(
                alignment: Alignment.centerLeft,
                child: _Pildora(
                  texto: e.proposito,
                  fondo: ColoresVitalys.advertenciaFondo,
                  color: ColoresVitalys.advertenciaTexto,
                ),
              )
            : _TextoCelda(e.proposito),
      ),
      _celda(
        6,
        Align(
          alignment: Alignment.centerLeft,
          child: e.resultado == ResultadoAuditoria.permitido
              ? _Pildora(
                  texto: e.resultado.nombre,
                  fondo: ColoresVitalys.exitoFondo,
                  color: ColoresVitalys.mentaTexto,
                )
              : _Pildora(
                  texto: e.resultado.nombre,
                  fondo: ColoresVitalys.alertaFondo,
                  color: ColoresVitalys.alertaTexto,
                ),
        ),
      ),
      _celda(7, _TextoCelda(e.sede)),
      _celda(8, _TextoCelda(e.ip)),
    ];
  }
}

/// La tabla de computador (Figma, pantalla 8), con celdas amplias y las
/// marcas de resultado y de emergencia con su ícono.
///
/// Ninguna palabra se parte: cada columna mide lo que necesita su palabra
/// más larga (la fecha y la pastilla de resultado, completas), y el espacio
/// que sobra se reparte según el peso de la columna. Si la ventana no
/// alcanza para todas, la tabla se desliza hacia los lados.
class _TablaCompleta extends StatelessWidget {
  const _TablaCompleta({required this.filas, required this.mensajeVacio});

  final List<FilaEvento> filas;
  final String mensajeVacio;

  static const double _relleno = 10;

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
            ? _Pildora.marco +
                  palabraMasLarga(e.propositoCompleto, _Pildora.estiloGrande)
            : palabraMasLarga(e.propositoCompleto, _estiloCelda),
      );
      // La pastilla de resultado nunca parte su texto.
      ajustar(
        6,
        _Pildora.marco + ancho(e.resultado.nombre, _Pildora.estiloGrande),
      );
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalMinimo,
                child: _cuerpo(minimos, conVacio: false),
              ),
            ),
            // El estado vacío se queda a la vista, sin deslizar.
            if (filas.isEmpty) _Vacio(mensaje: mensajeVacio),
          ],
        );
      },
    );
  }

  Widget _cuerpo(List<double> anchos, {bool conVacio = true}) {
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
        if (filas.isEmpty && conVacio) _Vacio(mensaje: mensajeVacio),
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
                child: _Pildora(
                  texto: e.propositoCompleto,
                  icono: Icons.warning_amber_rounded,
                  fondo: ColoresVitalys.alertaFondo,
                  color: ColoresVitalys.alertaTexto,
                  grande: true,
                ),
              )
            : Text(e.propositoCompleto, style: _estiloCelda),
      ),
      celda(
        6,
        Align(
          alignment: Alignment.centerLeft,
          child: _Pildora(
            texto: e.resultado.nombre,
            icono: permitido ? Icons.check_rounded : Icons.lock_outline_rounded,
            fondo: permitido
                ? ColoresVitalys.exitoFondo
                : ColoresVitalys.alertaFondo,
            color: permitido
                ? ColoresVitalys.mentaTexto
                : ColoresVitalys.alertaTexto,
            grande: true,
            unaLinea: true,
          ),
        ),
      ),
      celda(7, Text(e.sede, style: _estiloCelda)),
    ];
  }
}

class _TextoCelda extends StatelessWidget {
  const _TextoCelda(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.4,
        color: ColoresVitalys.tinta,
      ),
    );
  }
}

/// Pastilla de resultado o de emergencia. La de computador es más grande y
/// lleva ícono.
class _Pildora extends StatelessWidget {
  const _Pildora({
    required this.texto,
    required this.fondo,
    required this.color,
    this.icono,
    this.grande = false,
    this.unaLinea = false,
  });

  final String texto;
  final Color fondo;
  final Color color;
  final IconData? icono;
  final bool grande;

  /// El texto nunca se parte, por ejemplo en el resultado.
  final bool unaLinea;

  /// Texto de la pastilla grande, para medirla.
  static const estiloGrande = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  /// Lo que ocupa la pastilla grande además del texto: relleno e ícono.
  static const double marco = 14 * 2 + 17 + 8;

  @override
  Widget build(BuildContext context) {
    final etiqueta = Text(
      texto,
      softWrap: !unaLinea,
      style: grande
          ? estiloGrande.copyWith(color: color)
          : TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
    );
    final icono = this.icono;
    return Container(
      padding: grande
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(grande ? 18 : 999),
      ),
      child: icono == null
          ? etiqueta
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 17, color: color),
                const SizedBox(width: 8),
                if (unaLinea) etiqueta else Flexible(child: etiqueta),
              ],
            ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off_outlined,
            size: 36,
            color: ColoresVitalys.textoSuave,
          ),
          const SizedBox(height: 10),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ],
      ),
    );
  }
}
