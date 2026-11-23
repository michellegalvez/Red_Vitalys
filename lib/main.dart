import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:red_vitalys/config/entorno.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/fuente_de_datos.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseListo = await _iniciarSupabase();
  runApp(
    RedVitalysApp(datos: elegirFuenteDeDatos(supabaseListo: supabaseListo)),
  );
}

/// Único punto donde se inicializa Supabase. Si faltan las variables o falla,
/// avisa en la consola y la app sigue con los datos simulados.
Future<bool> _iniciarSupabase() async {
  if (!Entorno.configurado) {
    debugPrint(
      'Supabase no está configurado (faltan SUPABASE_URL o '
      'SUPABASE_PUBLISHABLE_KEY): la app usa los datos simulados. '
      'Ejecuta con --dart-define-from-file=env.json.',
    );
    return false;
  }
  try {
    await Supabase.initialize(
      url: Entorno.supabaseUrl,
      publishableKey: Entorno.supabasePublishableKey,
    );
    debugPrint('Supabase inicializado.');
    return true;
  } catch (error) {
    debugPrint(
      'No se pudo inicializar Supabase ($error): '
      'la app usa los datos simulados.',
    );
    return false;
  }
}

class RedVitalysApp extends StatelessWidget {
  const RedVitalysApp({super.key, required this.datos});

  final DatosSimulados datos;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Vitalys',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'CO')],
      locale: const Locale('es', 'CO'),
      theme: temaRedVitalys(),
      home: AppScreen(datos: datos),
    );
  }
}
