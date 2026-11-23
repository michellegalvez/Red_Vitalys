import 'package:red_vitalys/datos/datos_simulados.dart';

/// Único punto que decide de dónde salen los datos de la app (AD-02).
///
/// Por ahora siempre son los datos simulados en memoria, esté o no lista la
/// conexión con Supabase. Cuando existan los repositorios con Supabase, el
/// cambio se hace solo aquí.
DatosSimulados elegirFuenteDeDatos({required bool supabaseListo}) {
  return DatosSimulados.porDefecto;
}
