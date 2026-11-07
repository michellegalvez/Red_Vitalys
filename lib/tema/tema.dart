import 'package:flutter/material.dart';

/// Colores de Red Vitalys, tomados de la galería de componentes del Figma.
abstract final class ColoresVitalys {
  static const tinta = Color(0xFF141438);
  static const textoSecundario = Color(0xFF55557A);
  static const textoSuave = Color(0xFF7A7A99);
  static const primario = Color(0xFF4C48E8);
  static const primarioOscuro = Color(0xFF3B37C8);
  static const fondo = Color(0xFFF4F3FC);
  static const fondoLavanda = Color(0xFFECEAFB);
  static const fondoMenta = Color(0xFFE2F4F3);
  static const borde = Color(0xFFDCDCEC);
  static const superficie = Colors.white;

  static const alerta = Color(0xFFDC2033);
  static const alertaTexto = Color(0xFFB3141F);
  static const alertaFondo = Color(0xFFFCE4E0);
  static const naranjaFondo = Color(0xFFFCD8B8);
  static const naranjaTexto = Color(0xFFB4510F);
  static const mentaFondo = Color(0xFFA6F5DA);
  static const mentaTexto = Color(0xFF0B6B4D);
  static const exito = Color(0xFF169C62);
  static const exitoFondo = Color(0xFFD3F8E2);
  static const advertenciaFondo = Color(0xFFFFF1D6);
  static const advertenciaTexto = Color(0xFF8A4B00);
  static const infoFondo = Color(0xFFE8E8FB);

  static const violetaHeroInicio = Color(0xFF2B1680);
  static const violetaHeroFin = Color(0xFF4A2BD8);
  static const turquesa = Color(0xFF5EEAD4);
  static const verdeLima = Color(0xFFA7F3D0);
}

/// A partir de este ancho la app usa el diseño de escritorio (RNF-07).
const double anchoEscritorio = 900;

/// Ancho máximo del contenido en escritorio.
const double anchoMaximoContenido = 1200;

ThemeData temaRedVitalys() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColoresVitalys.primario,
      primary: ColoresVitalys.primario,
      surface: ColoresVitalys.superficie,
    ),
    scaffoldBackgroundColor: ColoresVitalys.fondo,
  );
  final texto = base.textTheme.apply(
    bodyColor: ColoresVitalys.tinta,
    displayColor: ColoresVitalys.tinta,
  );
  return base.copyWith(
    textTheme: texto.copyWith(
      displaySmall: texto.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
      ),
      headlineSmall: texto.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: texto.bodyMedium?.copyWith(height: 1.4),
    ),
    dividerColor: ColoresVitalys.borde,
  );
}
