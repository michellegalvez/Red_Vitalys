import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Fondo y texto de los avatares, en el orden del diseño (JP, MR, HQ, CG).
const _coloresAvatar = [
  (Color(0xFFC7F5E4), Color(0xFF0B6B4D)),
  (Color(0xFFFCE0C2), Color(0xFF9A4A0E)),
  (Color(0xFFDCE6FD), Color(0xFF3B37C8)),
  (Color(0xFFFBDDE6), Color(0xFFA0204F)),
];

/// Color estable del avatar de un paciente: sale de su id ("p1", "p2"...),
/// no de su posición en la lista, así no cambia al buscar ni entre pantallas.
int indiceColorDe(String id) {
  final numero = int.tryParse(id.replaceAll(RegExp(r'\D'), ''));
  return numero == null ? id.codeUnits.fold(0, (a, c) => a + c) : numero - 1;
}

/// Avatar con las iniciales de una persona.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({
    super.key,
    required this.iniciales,
    this.indiceColor = 0,
    this.tamano = 44,
    this.fondo,
    this.colorTexto,
  });

  final String iniciales;
  final int indiceColor;
  final double tamano;
  final Color? fondo;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final (f, t) = _coloresAvatar[indiceColor % _coloresAvatar.length];
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fondo ?? f, shape: BoxShape.circle),
      child: Text(
        iniciales,
        style: TextStyle(
          fontSize: tamano * 0.3,
          fontWeight: FontWeight.w800,
          color: colorTexto ?? t,
        ),
      ),
    );
  }
}

/// Anillo de riesgo de la galería: el puntaje de 0 a 100 dentro de un
/// círculo rojo si tiene alerta (70 o más) o verde si no.
class AnilloRiesgo extends StatelessWidget {
  const AnilloRiesgo({super.key, required this.riesgo, this.tamano = 62});

  final int riesgo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final alerta = conAlerta(riesgo);
    return Semantics(
      label:
          'Riesgo $riesgo de 100'
          '${alerta ? ', con alerta' : ', sin alerta'}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: tamano,
        child: CustomPaint(
          painter: _AnilloPainter(
            fraccion: (riesgo / 100).clamp(0.0, 1.0),
            color: alerta ? ColoresVitalys.alerta : ColoresVitalys.exito,
            grosor: tamano * 0.1,
          ),
          child: Center(
            child: Text(
              '$riesgo',
              style: TextStyle(
                fontSize: tamano * 0.3,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  _AnilloPainter({
    required this.fraccion,
    required this.color,
    required this.grosor,
  });

  final double fraccion;
  final Color color;
  final double grosor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(grosor / 2);
    final fondo = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;
    final arco = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = grosor;
    canvas.drawArc(rect, 0, math.pi * 2, false, fondo);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraccion, false, arco);
  }

  @override
  bool shouldRepaint(covariant _AnilloPainter old) =>
      old.fraccion != fraccion || old.color != color;
}

/// Texto de alerta junto al anillo: "CON ALERTA" en rojo o "SIN ALERTA"
/// en verde.
class TextoAlerta extends StatelessWidget {
  const TextoAlerta({super.key, required this.riesgo});

  final int riesgo;

  @override
  Widget build(BuildContext context) {
    final alerta = conAlerta(riesgo);
    return Text(
      alerta ? 'CON ALERTA' : 'SIN ALERTA',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: alerta ? ColoresVitalys.alertaTexto : ColoresVitalys.mentaTexto,
      ),
    );
  }
}

/// Etiqueta de riesgo de la galería: "Con alerta 91" o "Sin alerta 23".
class EtiquetaRiesgo extends StatelessWidget {
  const EtiquetaRiesgo({super.key, required this.riesgo});

  final int riesgo;

  @override
  Widget build(BuildContext context) {
    final alerta = conAlerta(riesgo);
    final color = alerta
        ? ColoresVitalys.alertaTexto
        : ColoresVitalys.mentaTexto;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: alerta ? ColoresVitalys.alertaFondo : ColoresVitalys.exitoFondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${alerta ? 'Con alerta' : 'Sin alerta'}  $riesgo',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Tarjeta de paciente de la galería, con alerta o sin alerta.
class TarjetaPaciente extends StatelessWidget {
  const TarjetaPaciente({
    super.key,
    required this.paciente,
    required this.sedeAlta,
    required this.onTap,
  });

  final PacienteEnSeguimiento paciente;
  final String sedeAlta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    final alerta = conAlerta(p.riesgo);
    return Semantics(
      button: true,
      label: 'Abrir a ${p.nombre}',
      child: DecoratedBox(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: alerta
                    ? ColoresVitalys.alerta.withValues(alpha: 0.22)
                    : ColoresVitalys.borde,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: alerta
                    ? const [ColoresVitalys.alertaFondo, Colors.white]
                    : const [Color(0xFFEFFAF5), Colors.white],
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvatarIniciales(
                          iniciales: p.iniciales,
                          indiceColor: indiceColorDe(p.id),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _DatosPaciente(p: p, sedeAlta: sedeAlta),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        AnilloRiesgo(riesgo: p.riesgo),
                        const SizedBox(width: 14),
                        TextoAlerta(riesgo: p.riesgo),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatosPaciente extends StatelessWidget {
  const _DatosPaciente({required this.p, required this.sedeAlta});

  final PacienteEnSeguimiento p;
  final String sedeAlta;

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      fontSize: 13,
      color: ColoresVitalys.textoSecundario,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.nombre,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${p.edad} años · ${p.sexo}     ${p.documentoOculto}',
          style: estilo,
        ),
        const SizedBox(height: 5),
        _Dato(
          icono: Icons.apartment_rounded,
          texto: '$sedeAlta · ${p.tipoAtencion.nombre}',
        ),
        const SizedBox(height: 5),
        _Dato(
          icono: Icons.calendar_today_outlined,
          texto:
              '${formatoFecha(p.fechaAlta)}     '
              '${formatoEstancia(p.diasEstancia)}',
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icono, size: 14, color: ColoresVitalys.textoSuave),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
        ),
      ],
    );
  }
}
