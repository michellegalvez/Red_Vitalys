import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';

void main() => runApp(const RedVitalysApp());

class RedVitalysApp extends StatelessWidget {
  const RedVitalysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Vitalys',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'CO')],
      locale: const Locale('es', 'CO'),
      theme: temaRedVitalys(),
      home: AppScreen(datos: DatosSimulados.porDefecto),
    );
  }
}
