import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/services/history_supabase.dart';
import 'package:red_vitalys/services/remote_ids.dart';

import 'supabase_ayudas.dart';

// Abrir una historia no espera una consulta para empezar la siguiente cuando
// no dependen una de la otra, y no vuelve a buscar al paciente.

final _datos = DatosSimulados.porDefecto;

void main() {
  test(
    'la historia pide los datos del paciente y sus atenciones a la vez',
    () async {
      final atencionesPedidas = Completer<void>();
      final servidor = await ServidorFalso((pedido) async {
        if (pedido.url.path.endsWith('/paciente')) {
          // Solo responde cuando ya se pidieron las atenciones.
          await atencionesPedidas.future;
          return respuestaJson({
            'fecha_nacimiento': '1948-06-02',
            'direccion': null,
            'telefono': null,
            'identificador_paciente': <Object>[],
          }, pedido);
        }
        atencionesPedidas.complete();
        return respuestaJson([], pedido);
      }).conSesion();
      final paciente = _datos.pacientes.first;
      RemoteIds.of(servidor.cliente).rememberPatient(paciente.id, 7);

      final historia = await HistorySupabase(servidor.cliente)
          .historyOf(
            paciente,
            siteName: _datos.sede(paciente.sedeAltaId).nombre,
            today: _datos.hoy,
          )
          .timeout(const Duration(seconds: 2));

      expect(historia.encounters, isEmpty);
      expect(
        servidor.pedidos.where(
          (p) => p.url.path.endsWith('/identificador_paciente'),
        ),
        isEmpty,
      );
    },
  );
}
