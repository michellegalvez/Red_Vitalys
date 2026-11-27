import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/services/patient_supabase.dart';

import 'supabase_ayudas.dart';

// Ningún paciente desaparece de la lista ni de la búsqueda por un dato que la
// app no reconoce, y una fila mal formada no deja la lista sin nadie (F-01,
// F-06).

final _datos = DatosSimulados.porDefecto;

Map<String, Object?> _persona(
  int id,
  String documento, {
  String nombre = 'Rosa',
  String apellido = 'Lema',
  Object? sexo = 'F',
}) => {
  'id_paciente': id,
  'primer_nombre': nombre,
  'segundo_nombre': null,
  'primer_apellido': apellido,
  'segundo_apellido': null,
  'fecha_nacimiento': '1960-01-01',
  'sexo': sexo,
  'identificador_paciente': [
    {
      'tipo_documento': 'CC',
      'numero_identificacion': documento,
      'es_principal': true,
    },
  ],
};

Map<String, Object?> _alta(int paciente, String sede) => {
  'id_paciente': paciente,
  'fecha_inicio': '2026-10-28T13:00:00Z',
  'fecha_fin': '2026-11-02T13:00:00Z',
  'tipo_atencion': 'hospitalizacion',
  'proposito': 'atencion_paciente',
  'sede': {'nombre': sede},
  'usuario': {'correo': 'CAMILA.MARTINEZ@vitalys.co'},
  'prediccion_reingreso': [
    {'score_riesgo': 80, 'fecha_prediccion': '2026-11-02'},
  ],
};

Future<PatientSupabase> _servicio({
  required List<Map<String, Object?>> atenciones,
  required List<Map<String, Object?>> personas,
}) async {
  final servidor = await ServidorFalso(
    (pedido) async => respuestaJson(
      pedido.url.path.endsWith('/paciente') ? personas : atenciones,
      pedido,
    ),
  ).conSesion();
  return PatientSupabase(
    client: servidor.cliente,
    sitesByName: {for (final s in _datos.sedes) s.nombre: s.id},
    usersByEmail: {for (final u in _datos.usuarios) u.correo: u.id},
    patientIdsByDocument: const {},
  );
}

void main() {
  test('la sede y el médico se reconocen sin importar tildes ni '
      'mayúsculas', () async {
    final servicio = await _servicio(
      atenciones: [_alta(7, 'CLINICA VITALYS CALI NORTE')],
      personas: [_persona(7, '555')],
    );

    final rosa = (await servicio.listPatients(_datos.hoy)).single;

    expect(rosa.sedeAltaId, 's1');
    expect(rosa.medicosConAtencion, [
      _datos.usuarioPorCorreo('camila.martinez@vitalys.co')!.id,
    ]);
  });

  test(
    'con una sede que la app no conoce el paciente sigue en la lista',
    () async {
      final servicio = await _servicio(
        atenciones: [_alta(7, 'Sede nueva de la red')],
        personas: [_persona(7, '555')],
      );

      final pacientes = await servicio.listPatients(_datos.hoy);

      expect(pacientes.single.numeroDocumento, '555');
      expect(pacientes.single.fechaAlta, DateTime(2026, 11, 2));
    },
  );

  test('una fila mal formada se salta y las demás se ven', () async {
    final servicio = await _servicio(
      atenciones: [_alta(7, _datos.sede('s1').nombre)],
      personas: [
        _persona(7, '555'),
        _persona(8, '666', sexo: null),
        _persona(9, '777', nombre: '', apellido: ''),
      ],
    );

    final pacientes = await servicio.listPatients(_datos.hoy);

    expect(pacientes.map((p) => p.numeroDocumento), ['555', '777']);
    expect(pacientes.last.iniciales, isNotEmpty);
  });
}
