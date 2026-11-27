import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:red_vitalys/config/entorno.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/fuente_de_datos.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/repositorios/foto_repositorio.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:red_vitalys/services/history_service.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:red_vitalys/services/lock_store.dart';
import 'package:red_vitalys/services/relationship_service.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseListo = await _iniciarSupabase();
  final datos = elegirFuenteDeDatos(supabaseListo: supabaseListo);
  final cliente = supabaseListo ? Supabase.instance.client : null;
  runApp(
    RedVitalysApp(
      datos: datos,
      auditoria: elegirAuditoria(datos: datos, cliente: cliente),
      auth: elegirAuth(datos: datos, cliente: cliente),
      patients: elegirPacientes(datos: datos, cliente: cliente),
      history: elegirHistoria(cliente: cliente),
      indicators: elegirIndicadores(datos: datos, cliente: cliente),
      fotos: elegirFotos(cliente: cliente),
      lockStore: LockDevice(),
      relationships: elegirRelaciones(cliente: cliente),
    ),
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
  const RedVitalysApp({
    super.key,
    required this.datos,
    this.auditoria,
    this.auth,
    this.patients,
    this.history,
    this.indicators,
    this.fotos,
    this.lockStore,
    this.relationships,
  });

  final DatosSimulados datos;
  final AuditoriaRepositorio? auditoria;
  final AuthService? auth;
  final PatientService? patients;
  final HistoryService? history;
  final IndicatorService? indicators;
  final FotoPerfilRepositorio? fotos;
  final LockStore? lockStore;
  final RelationshipService? relationships;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Vitalys',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'CO')],
      locale: const Locale('es', 'CO'),
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: datos,
        auditoria: auditoria,
        auth: auth,
        patients: patients,
        history: history,
        indicators: indicators,
        fotos: fotos,
        lockStore: lockStore,
        relationships: relationships,
      ),
    );
  }
}
