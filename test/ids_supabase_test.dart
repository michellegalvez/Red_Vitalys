import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_supabase.dart';
import 'package:red_vitalys/services/remote_ids.dart';

import 'supabase_ayudas.dart';

// Un solo lugar traduce el paciente, la sede y el indicador a los ids de la
// base: filtra por el tipo y el número del documento, guarda lo que ya sabe
// y lo olvida cuando cambia la sesión.

final _datos = DatosSimulados.porDefecto;
final _paciente = _datos.pacientes.first;

bool _es(dynamic pedido, String tabla) =>
    (pedido.url.path as String).endsWith('/$tabla');

EventoAuditoria _evento({String? pacienteId}) => EventoAuditoria(
  id: 'e1',
  fechaHora: _datos.hoy,
  usuarioId: 'u1',
  accion: AccionAuditoria.consultar,
  recurso: RecursoAuditoria.historiaClinica,
  resultado: ResultadoAuditoria.permitido,
  sedeId: 's1',
  pacienteId: pacienteId,
);

void main() {
  test('el paciente se busca por tipo y número de documento y se pide una '
      'sola vez', () async {
    final servidor = await ServidorFalso(
      (pedido) async => respuestaJson([
        {'id_paciente': 7},
      ], pedido),
    ).conSesion();
    final ids = RemoteIds.of(servidor.cliente);

    expect(await ids.patientId(_paciente), 7);
    expect(await ids.patientId(_paciente), 7);

    final consulta = servidor.pedidos.single.url.queryParameters;
    expect(consulta['tipo_documento'], 'eq.${_paciente.tipoDocumento}');
    expect(
      consulta['numero_identificacion'],
      'eq.${_paciente.numeroDocumento}',
    );
    expect(consulta['es_principal'], 'eq.true');
  });

  test('sin el paciente en la base da un error claro', () async {
    final servidor = await ServidorFalso(
      (pedido) async => respuestaJson([], pedido),
    ).conSesion();

    await expectLater(
      RemoteIds.of(servidor.cliente).patientId(_paciente),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'mensaje',
          contains('paciente'),
        ),
      ),
    );
  });

  test(
    'con dos pacientes con el mismo documento no elige uno al azar',
    () async {
      final servidor = await ServidorFalso(
        (pedido) async => respuestaJson([
          {'id_paciente': 7},
          {'id_paciente': 8},
        ], pedido),
      ).conSesion();

      await expectLater(
        RemoteIds.of(servidor.cliente).patientId(_paciente),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('la sede se reconoce sin importar tildes ni mayúsculas y se pide una '
      'vez por sesión', () async {
    final servidor = await ServidorFalso(
      (pedido) async => respuestaJson([
        {'id_sede': 3, 'nombre': 'CLINICA VITALYS CALI NORTE'},
      ], pedido),
    ).conSesion();
    final ids = RemoteIds.of(servidor.cliente);

    expect(await ids.siteId('Clínica Vitalys Cali Norte'), 3);
    expect(await ids.siteId('Clínica Vitalys Cali Norte'), 3);
    expect(servidor.pedidos, hasLength(1));

    await servidor.cliente.auth.signOut();
    await servidor.conSesion();
    expect(await ids.siteId('Clínica Vitalys Cali Norte'), 3);
    expect(servidor.pedidos, hasLength(2));
  });

  test('una sede desconocida da un error claro', () async {
    final servidor = await ServidorFalso(
      (pedido) async => respuestaJson([
        {'id_sede': 3, 'nombre': 'Clínica Vitalys Cali Norte'},
      ], pedido),
    ).conSesion();

    await expectLater(
      RemoteIds.of(servidor.cliente).siteId('Sede que no existe'),
      throwsA(isA<StateError>()),
    );
  });

  test('la auditoría no se queda con una lista de sedes vacía', () async {
    var sedes = <Object>[];
    final insertados = <Object?>[];
    final servidor = await ServidorFalso((pedido) async {
      if (_es(pedido, 'sede')) return respuestaJson(sedes, pedido);
      insertados.add(pedido.body);
      return respuestaJson(null, pedido, estado: 201);
    }).conSesion();
    final auditoria = AuditoriaSupabase(
      cliente: servidor.cliente,
      sedesPorNombre: {for (final s in _datos.sedes) s.nombre: s.id},
      usuariosPorCorreo: const {},
      pacientesPorDocumento: const {},
    );

    await auditoria.agregar(_evento());
    sedes = [
      {'id_sede': 3, 'nombre': _datos.sede('s1').nombre},
    ];
    await auditoria.agregar(_evento());

    expect(insertados.first, contains('"id_sede":null'));
    expect(insertados.last, contains('"id_sede":3'));
  });

  test(
    'el evento usa el paciente que ya resolvió la lista de pacientes',
    () async {
      final servidor = await ServidorFalso(
        (pedido) async => _es(pedido, 'sede')
            ? respuestaJson([], pedido)
            : respuestaJson(null, pedido, estado: 201),
      ).conSesion();
      RemoteIds.of(servidor.cliente).rememberPatient('p1', 42);
      final auditoria = AuditoriaSupabase(
        cliente: servidor.cliente,
        sedesPorNombre: const {},
        usuariosPorCorreo: const {},
        pacientesPorDocumento: const {},
      );

      await auditoria.agregar(_evento(pacienteId: 'p1'));

      expect(
        servidor.pedidos.where((p) => _es(p, 'identificador_paciente')),
        isEmpty,
      );
      expect(servidor.pedidos.last.body, contains('"id_paciente":42'));
    },
  );
}
