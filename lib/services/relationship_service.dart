import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tells whether a doctor has a relationship with a patient (F-05).
abstract interface class RelationshipService {
  bool get isRemote;

  Future<bool> hasRelationship(
    Usuario doctor,
    PacienteEnSeguimiento patient,
    DateTime today,
  );
}

/// Decides the relationship with the loaded data, for the tests and without
/// Supabase.
class RelationshipMemory implements RelationshipService {
  const RelationshipMemory();

  @override
  bool get isRemote => false;

  @override
  Future<bool> hasRelationship(
    Usuario doctor,
    PacienteEnSeguimiento patient,
    DateTime today,
  ) async => tieneRelacion(doctor, patient, today);
}

/// Asks the database, which applies the same rule with its own data, so a
/// failure shows "No se pudo verificar el acceso" (F-05 CA-8, F-18 CA-9).
class RelationshipSupabase implements RelationshipService {
  RelationshipSupabase(this.client);

  final SupabaseClient client;

  @override
  bool get isRemote => true;

  @override
  Future<bool> hasRelationship(
    Usuario doctor,
    PacienteEnSeguimiento patient,
    DateTime today,
  ) async {
    final result = await client.rpc<dynamic>(
      'tiene_relacion',
      params: {'p_id_paciente': await _patientId(patient)},
    );
    return result == true;
  }

  Future<int> _patientId(PacienteEnSeguimiento patient) async {
    if (patient.id.startsWith('db')) {
      return int.parse(patient.id.substring(2));
    }
    final row = await client
        .from('identificador_paciente')
        .select('id_paciente')
        .eq('tipo_documento', patient.tipoDocumento)
        .eq('numero_identificacion', patient.numeroDocumento)
        .eq('es_principal', true)
        .limit(1)
        .single();
    return row['id_paciente'] as int;
  }
}
