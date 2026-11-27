import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/services/history_supabase.dart';
import 'package:red_vitalys/services/indicator_supabase.dart';

import 'supabase_ayudas.dart';

// Una fila que la app no sabe leer se salta y se avisa en la consola, como
// ya hace la auditoría: el tablero y la historia muestran las demás (F-02,
// F-08).

final _datos = DatosSimulados.porDefecto;

Map<String, Object?> _medicion(int id, String codigo, String sede) => {
  'id_medicion': id,
  'periodo_inicio': '2026-09-01',
  'valor': 12.5,
  'indicador': {'codigo': codigo},
  'sede': {'nombre': sede},
};

Map<String, Object?> _atencion(int id, Object? inicio) => {
  'id_atencion': id,
  'tipo_atencion': 'urgencias',
  'fecha_inicio': inicio,
  'fecha_fin': null,
  'destino_alta': null,
  'sede': {'nombre_corto': 'Cali Norte'},
  'usuario': {'nombre_completo': 'Dra. Camila Martínez'},
};

void main() {
  test('una medición de un indicador o una sede desconocidos se salta y el '
      'tablero se carga', () async {
    final cali = _datos.sede('s1').nombre;
    final servidor = await ServidorFalso(
      (pedido) async => respuestaJson([
        _medicion(1, 'reingreso', cali),
        _medicion(2, 'indicador_nuevo', cali),
        _medicion(3, 'espera', 'Sede que no existe'),
        _medicion(4, 'espera', cali.toUpperCase()),
      ], pedido),
    ).conSesion();
    final servicio = IndicatorSupabase(
      client: servidor.cliente,
      sitesByName: {for (final s in _datos.sedes) s.nombre: s.id},
    );

    final mediciones = await servicio.listMeasurements();

    expect(mediciones.map((m) => m.indicador), [
      IdIndicador.reingreso,
      IdIndicador.espera,
    ]);
    expect(mediciones.map((m) => m.sedeId), everyElement('s1'));
  });

  test('una atención mal formada se salta y la historia se carga', () async {
    final servidor = await ServidorFalso((pedido) async {
      if (pedido.url.path.endsWith('/identificador_paciente')) {
        return respuestaJson([
          {'id_paciente': 7},
        ], pedido);
      }
      if (pedido.url.path.endsWith('/paciente')) {
        return respuestaJson({
          'fecha_nacimiento': '1948-06-02',
          'direccion': null,
          'telefono': null,
          'identificador_paciente': [
            {
              'numero_identificacion': 'X-1',
              'es_principal': false,
              'sistema_origen': null,
            },
          ],
        }, pedido);
      }
      return respuestaJson([
        _atencion(41, '2026-11-01T15:00:00Z'),
        _atencion(42, null),
      ], pedido);
    }).conSesion();
    final paciente = _datos.pacientes.first;

    final historia = await HistorySupabase(servidor.cliente).historyOf(
      paciente,
      siteName: _datos.sede(paciente.sedeAltaId).nombre,
      today: _datos.hoy,
    );

    expect(historia.encounters.map((e) => e.id), ['enc-41']);
    expect(historia.systemIdentifiers, isEmpty);
  });
}
