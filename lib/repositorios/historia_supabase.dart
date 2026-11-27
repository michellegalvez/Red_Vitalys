import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/atencion.dart';
import 'package:red_vitalys/repositorios/historia_repositorio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación de [HistoriaRepositorio] conectada a Supabase (PostgREST, P-04).
class HistoriaSupabase implements HistoriaRepositorio {
  HistoriaSupabase({
    required this.cliente,
    required this.sedesPorId,
    required this.sedesPorNombre,
    required this.hoy,
  });

  final SupabaseClient cliente;
  final Map<String, Sede> sedesPorId;
  final Map<String, Sede> sedesPorNombre;
  final DateTime hoy;

  @override
  Future<Patient> obtenerHistoria(String pacienteId) async {
    // Si pacienteId es un string con prefijo tipo 'p1', intentamos extraer el id numérico
    final idNumerico =
        int.tryParse(pacienteId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

    final pacienteData = await cliente
        .from('paciente')
        .select('''
          id_paciente, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
          fecha_nacimiento, sexo, direccion, telefono,
          identificador_paciente (
            tipo_documento, numero_identificacion, es_principal,
            sistema_origen ( nombre )
          ),
          atencion (
            id_atencion, tipo_atencion, fecha_inicio, fecha_fin, destino_alta, proposito,
            id_sede, id_usuario,
            sede ( nombre, nombre_corto ),
            usuario ( nombre_completo ),
            prediccion_reingreso (
              id_prediccion, score_riesgo, fecha_prediccion,
              factor_riesgo ( variable, contribucion )
            )
          )
        ''')
        .eq('id_paciente', idNumerico)
        .maybeSingle();

    if (pacienteData == null) {
      throw StateError('Paciente no encontrado en Supabase: $pacienteId');
    }

    return _mapearPaciente(pacienteData, pacienteId);
  }

  @override
  Future<Encounter> registrarAtencion({
    required String pacienteId,
    required NuevaAtencion nueva,
    required String medicoId,
    required String medicoNombre,
    required Proposito proposito,
  }) async {
    final idPacNum =
        int.tryParse(pacienteId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

    // Resuelve id de sede en base de datos
    final sedeObj = sedesPorId[nueva.sedeId];
    int? sedeIdNum;
    if (sedeObj != null) {
      sedeIdNum = int.tryParse(sedeObj.id.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    sedeIdNum ??= 1;

    final usuarioUid = cliente.auth.currentUser?.id;

    final tipoSql = switch (nueva.tipo) {
      EncounterType.hospitalizacion => 'hospitalizacion',
      EncounterType.urgencias => 'urgencias',
      EncounterType.consultaExterna => 'consulta_externa',
    };

    final propositoSql = switch (proposito) {
      Proposito.seguimientoReingreso => 'seguimiento_reingreso',
      Proposito.consultaHistoria => 'consulta_historia',
      Proposito.atencionPaciente => 'atencion_paciente',
      Proposito.revisionCalidad => 'revision_calidad',
      Proposito.urgencia => 'urgencia',
    };

    final mapInsert = <String, dynamic>{
      'id_paciente': idPacNum,
      'id_sede': sedeIdNum,
      'tipo_atencion': tipoSql,
      'fecha_inicio': nueva.inicio.toIso8601String(),
      'destino_alta': nueva.destino,
      'proposito': propositoSql,
    };
    if (usuarioUid != null) {
      mapInsert['id_usuario'] = usuarioUid;
    }
    if (nueva.alta != null) {
      mapInsert['fecha_fin'] = nueva.alta!.toIso8601String();
    }

    final insertRes = await cliente
        .from('atencion')
        .insert(mapInsert)
        .select('id_atencion')
        .single();

    final idGenerado = insertRes['id_atencion']?.toString() ?? 'enc-supa';

    final duracion = nueva.alta?.difference(nueva.inicio).inDays;

    final sedeNombre = sedeObj?.nombreCorto ?? 'Sede Vitalys';

    return Encounter(
      id: idGenerado,
      type: nueva.tipo,
      status: nueva.alta == null
          ? EncounterStatus.enCurso
          : EncounterStatus.finalizada,
      facilityName: sedeNombre,
      startDate: nueva.inicio,
      endDate: nueva.alta,
      lengthOfStayDays: duracion,
      dischargeDestination: nueva.destino,
      doctorName: medicoNombre,
    );
  }

  Patient _mapearPaciente(Map<String, dynamic> data, String idOriginal) {
    final p1 = data['primer_nombre'] as String? ?? '';
    final p2 = data['segundo_nombre'] as String?;
    final a1 = data['primer_apellido'] as String? ?? '';
    final a2 = data['segundo_apellido'] as String?;
    final nombreCompleto = [
      p1,
      if (p2 != null && p2.isNotEmpty) p2,
      a1,
      if (a2 != null && a2.isNotEmpty) a2,
    ].join(' ');

    final fechaNac =
        DateTime.tryParse(data['fecha_nacimiento']?.toString() ?? '') ??
        DateTime(1980);
    final edad =
        hoy.year -
        fechaNac.year -
        (hoy.month < fechaNac.month ||
                (hoy.month == fechaNac.month && hoy.day < fechaNac.day)
            ? 1
            : 0);

    final idsLista = (data['identificador_paciente'] as List<dynamic>?) ?? [];
    String docTipo = 'CC';
    String docNum = '00000000';
    final systemIds = <SystemIdentifier>[];

    for (final rawId in idsLista) {
      final m = rawId as Map<String, dynamic>;
      final esPrincipal = m['es_principal'] == true;
      final tipo = m['tipo_documento'] as String? ?? 'CC';
      final num = m['numero_identificacion'] as String? ?? '';
      final sisMap = m['sistema_origen'] as Map<String, dynamic>?;
      final sisNombre = sisMap?['nombre'] as String? ?? 'Sistema de origen';

      if (esPrincipal) {
        docTipo = tipo;
        docNum = num;
      }
      systemIds.add(
        SystemIdentifier(systemName: sisNombre, identifier: '$tipo $num'),
      );
    }

    // Mapeo de atenciones y predicción
    final atencionesLista = (data['atencion'] as List<dynamic>?) ?? [];
    final encounters = <Encounter>[];
    ReadmissionRisk? riesgo;

    for (final rawAt in atencionesLista) {
      final mAt = rawAt as Map<String, dynamic>;
      final idAt = mAt['id_atencion']?.toString() ?? '';
      final tipoStr = mAt['tipo_atencion'] as String? ?? 'hospitalizacion';
      final tipo = switch (tipoStr) {
        'urgencias' => EncounterType.urgencias,
        'consulta_externa' => EncounterType.consultaExterna,
        _ => EncounterType.hospitalizacion,
      };

      final fInicio =
          DateTime.tryParse(mAt['fecha_inicio']?.toString() ?? '') ??
          DateTime.now();
      final fFin = mAt['fecha_fin'] != null
          ? DateTime.tryParse(mAt['fecha_fin'].toString())
          : null;
      final sedeMap = mAt['sede'] as Map<String, dynamic>?;
      final sedeNombre =
          sedeMap?['nombre_corto'] as String? ??
          sedeMap?['nombre'] as String? ??
          'Sede Vitalys';
      final usuMap = mAt['usuario'] as Map<String, dynamic>?;
      final medico = usuMap?['nombre_completo'] as String? ?? 'Médico Vitalys';

      final duracion = fFin?.difference(fInicio).inDays;

      encounters.add(
        Encounter(
          id: idAt,
          type: tipo,
          status: fFin == null
              ? EncounterStatus.enCurso
              : EncounterStatus.finalizada,
          facilityName: sedeNombre,
          startDate: fInicio,
          endDate: fFin,
          lengthOfStayDays: duracion,
          dischargeDestination: mAt['destino_alta'] as String?,
          doctorName: medico,
        ),
      );

      // Extraer predicción más reciente
      final predLista = (mAt['prediccion_reingreso'] as List<dynamic>?) ?? [];
      for (final rawPred in predLista) {
        final mPred = rawPred as Map<String, dynamic>;
        final scoreNum = (mPred['score_riesgo'] as num?)?.toInt() ?? 0;
        final fPred =
            DateTime.tryParse(mPred['fecha_prediccion']?.toString() ?? '') ??
            DateTime.now();

        final factoresLista = (mPred['factor_riesgo'] as List<dynamic>?) ?? [];
        final factors = <RiskFactor>[];
        for (final rawFac in factoresLista) {
          final mFac = rawFac as Map<String, dynamic>;
          final v = mFac['variable'] as String? ?? '';
          final c = ((mFac['contribucion'] as num?)?.toDouble() ?? 0.0).round();
          factors.add(RiskFactor(name: v, points: c));
        }

        if (riesgo == null || fPred.isAfter(riesgo.calculatedDate)) {
          riesgo = ReadmissionRisk(
            score: scoreNum,
            calculatedDate: fPred,
            periodDescription: '30 días tras el alta',
            factors: factors,
          );
        }
      }
    }

    encounters.sort((a, b) => b.startDate.compareTo(a.startDate));

    return Patient(
      id: idOriginal,
      fullName: nombreCompleto,
      age: edad,
      sex: (data['sexo'] as String? ?? 'M').toUpperCase(),
      documentType: docTipo,
      documentNumber: docNum,
      birthDate: fechaNac,
      phone: data['telefono'] as String? ?? '',
      address: data['direccion'] as String? ?? '',
      systemIdentifiers: systemIds,
      readmissionRisk: riesgo,
      encounters: encounters,
    );
  }
}
