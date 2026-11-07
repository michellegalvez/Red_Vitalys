import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';

/// Contenido desplazable de una página, centrado y con ancho máximo en
/// escritorio. Nunca se desplaza hacia los lados (RNF-07).
class ContenidoPagina extends StatelessWidget {
  const ContenidoPagina({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        escritorio ? 38 : 16,
        escritorio ? 32 : 24,
        escritorio ? 38 : 16,
        escritorio ? 48 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Encabezado de página: sobretítulo en mayúsculas, título y descripción.
class EncabezadoPagina extends StatelessWidget {
  const EncabezadoPagina({
    super.key,
    required this.sobretitulo,
    required this.titulo,
    this.subtitulo,
  });

  final String sobretitulo;
  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sobretitulo.toUpperCase(),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: ColoresVitalys.primario,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(header: true, child: Text(titulo, style: tema.displaySmall)),
        if (subtitulo != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitulo!,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
        ],
      ],
    );
  }
}

/// Reparte las tarjetas en 1 columna en celular y en 3 en escritorio.
class RejillaTarjetas extends StatelessWidget {
  const RejillaTarjetas({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
        const separacion = 18.0;
        final ancho = (c.maxWidth - separacion * (columnas - 1)) / columnas;
        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final hijo in children) SizedBox(width: ancho, child: hijo),
          ],
        );
      },
    );
  }
}
