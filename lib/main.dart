import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:red_vitalys/config/entorno.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/auth_supabase.dart';
import 'package:red_vitalys/services/indicator_supabase.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseClient? cliente;
  if (Entorno.configurado) {
    try {
      await Supabase.initialize(
        url: Entorno.supabaseUrl,
        publishableKey: Entorno.supabasePublishableKey,
      );
      cliente = Supabase.instance.client;
    } catch (error) {
      debugPrint('No se pudo inicializar Supabase: $error');
    }
  } else {
    debugPrint(
      'Supabase no está configurado; se usarán los datos simulados. '
      'Define SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY.',
    );
  }
  runApp(RedVitalysApp(cliente: cliente));
}

class RedVitalysApp extends StatelessWidget {
  const RedVitalysApp({super.key, this.cliente});

  final SupabaseClient? cliente;

  @override
  Widget build(BuildContext context) {
    final datos = DatosSimulados.porDefecto;
    return MaterialApp(
      title: 'Red Vitalys',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'CO')],
      locale: const Locale('es', 'CO'),
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: datos,
        auth: cliente == null
            ? null
            : AuthSupabase(
                client: cliente!,
                sitesByName: {for (final s in datos.sedes) s.nombre: s.id},
                knownUsers: {for (final u in datos.usuarios) u.correo: u},
              ),
        indicators: cliente == null
            ? null
            : IndicatorSupabase(
                client: cliente!,
                sitesByName: {for (final s in datos.sedes) s.nombre: s.id},
              ),
      ),
    );
  }
}
