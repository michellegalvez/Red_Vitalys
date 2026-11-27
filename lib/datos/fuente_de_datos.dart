import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/repositorios/auditoria_memoria.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/repositorios/auditoria_supabase.dart';
import 'package:red_vitalys/repositorios/foto_memoria.dart';
import 'package:red_vitalys/repositorios/foto_repositorio.dart';
import 'package:red_vitalys/repositorios/foto_supabase.dart';
import 'package:red_vitalys/repositorios/historia_memoria.dart';
import 'package:red_vitalys/repositorios/historia_repositorio.dart';
import 'package:red_vitalys/repositorios/historia_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único punto que decide de dónde salen los datos de la app (AD-02).
///
/// Los pacientes, las historias y los indicadores siguen en memoria hasta que
/// cada quien pase los suyos a Supabase.
DatosSimulados elegirFuenteDeDatos({required bool supabaseListo}) {
  return DatosSimulados.porDefecto;
}

/// Dónde se consulta la historia y se guardan atenciones (P-04):
/// en Supabase si hay [cliente]; si no, en memoria con los datos simulados.
HistoriaRepositorio elegirHistoria({
  required DatosSimulados datos,
  SupabaseClient? cliente,
  Map<String, List<Encounter>>? atencionesIniciales,
}) {
  if (cliente == null) {
    return HistoriaMemoria(
      datos: datos,
      atencionesIniciales: atencionesIniciales,
    );
  }
  return HistoriaSupabase(
    cliente: cliente,
    sedesPorId: {for (final s in datos.sedes) s.id: s},
    sedesPorNombre: {for (final s in datos.sedes) s.nombre: s},
    hoy: datos.hoy,
  );
}

/// Dónde se guarda la foto de perfil: en Supabase Storage si hay [cliente];
/// si no, en memoria (P-02).
FotoPerfilRepositorio elegirFotos({SupabaseClient? cliente}) {
  if (cliente == null) return FotoMemoria();
  return FotoSupabase(cliente);
}

/// Dónde se guarda la auditoría: en Supabase si hay [cliente]; si no, en
/// memoria con los eventos simulados (P-01).
AuditoriaRepositorio elegirAuditoria({
  required DatosSimulados datos,
  SupabaseClient? cliente,
}) {
  if (cliente == null) return AuditoriaMemoria(datos.eventos);
  return AuditoriaSupabase(
    cliente: cliente,
    sedesPorNombre: {for (final s in datos.sedes) s.nombre: s.id},
    usuariosPorCorreo: {for (final u in datos.usuarios) u.correo: u.id},
  );
}
