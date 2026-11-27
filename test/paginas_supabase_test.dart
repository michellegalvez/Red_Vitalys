import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/repositorios/auditoria_supabase.dart';
import 'package:red_vitalys/services/indicator_supabase.dart';
import 'package:red_vitalys/services/patient_supabase.dart';

import 'supabase_ayudas.dart';

// PostgREST da como máximo 1.000 filas por pedido. La auditoría no tiene
// paginación en pantalla (F-21) y el tablero y la búsqueda usan todas las
// filas, así que se piden todas las páginas.

final _datos = DatosSimulados.porDefecto;
const _total = 1005;

/// Contesta como PostgREST la página que piden `offset` y `limit` de
/// [filas], nunca más de 1.000.
http.Response _pagina(http.Request pedido, List<Map<String, Object?>> filas) {
  final consulta = pedido.url.queryParameters;
  final desde = int.parse(consulta['offset'] ?? '0');
  final pedidas = int.parse(consulta['limit'] ?? '1000');
  final cuantas = pedidas < 1000 ? pedidas : 1000;
  final hasta = (desde + cuantas).clamp(0, filas.length);
  return respuestaJson(
    filas.sublist(desde.clamp(0, filas.length), hasta),
    pedido,
  );
}

void main() {
  test('la auditoría trae los eventos de todas las páginas', () async {
    final eventos = [
      for (var i = _total; i > 0; i--)
        {
          'id_evento': i,
          'fecha_hora_evento': '2026-11-27T15:00:00Z',
          'accion': 'consultar',
          'tipo_recurso': 'historia_clinica',
          'resultado': 'permitido',
          'proposito_uso': null,
          'correo_intento': null,
          'ip': null,
          'id_paciente': null,
          'usuario': null,
          'sede': null,
        },
    ];
    final servidor = await ServidorFalso(
      (pedido) async => _pagina(pedido, eventos),
    ).conSesion();
    final auditoria = AuditoriaSupabase(
      cliente: servidor.cliente,
      sedesPorNombre: const {},
      usuariosPorCorreo: const {},
      pacientesPorDocumento: const {},
    );

    final leidos = await auditoria.listar();

    expect(leidos, hasLength(_total));
    expect(leidos.first.id, 'e$_total');
    expect(leidos.last.id, 'e1');
  });

  test('el tablero trae las mediciones de todas las páginas', () async {
    final cali = _datos.sede('s1').nombre;
    final mediciones = [
      for (var i = 1; i <= _total; i++)
        {
          'id_medicion': i,
          'periodo_inicio': '2026-09-01',
          'valor': 10,
          'indicador': {'codigo': 'espera'},
          'sede': {'nombre': cali},
        },
    ];
    final servidor = await ServidorFalso(
      (pedido) async => _pagina(pedido, mediciones),
    ).conSesion();
    final servicio = IndicatorSupabase(
      client: servidor.cliente,
      sitesByName: {for (final s in _datos.sedes) s.nombre: s.id},
    );

    expect(await servicio.listMeasurements(), hasLength(_total));
  });

  test('la búsqueda encuentra a los pacientes de todas las páginas', () async {
    final personas = [
      for (var i = 1; i <= _total; i++)
        {
          'id_paciente': i,
          'primer_nombre': 'Paciente',
          'segundo_nombre': null,
          'primer_apellido': 'Número $i',
          'segundo_apellido': null,
          'fecha_nacimiento': '1960-01-01',
          'sexo': 'F',
          'identificador_paciente': [
            {
              'tipo_documento': 'CC',
              'numero_identificacion': '$i',
              'es_principal': true,
            },
          ],
        },
    ];
    final servidor = await ServidorFalso(
      (pedido) async => pedido.url.path.endsWith('/paciente')
          ? _pagina(pedido, personas)
          : _pagina(pedido, const []),
    ).conSesion();
    final servicio = PatientSupabase(
      client: servidor.cliente,
      sitesByName: const {},
      usersByEmail: const {},
      patientIdsByDocument: const {},
    );

    expect(await servicio.listPatients(_datos.hoy), hasLength(_total));
  });
}
