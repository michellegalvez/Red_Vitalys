import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_memoria.dart';
import 'package:red_vitalys/repositorios/auditoria_traduccion.dart';

EventoAuditoria _evento(String id) => EventoAuditoria(
  id: id,
  fechaHora: DateTime(2026, 11, 6),
  accion: AccionAuditoria.consultar,
  recurso: RecursoAuditoria.historiaClinica,
  resultado: ResultadoAuditoria.permitido,
);

void main() {
  group('AuditoriaMemoria', () {
    test(
      'agregar suma un evento y listar trae el más reciente primero',
      () async {
        final repo = AuditoriaMemoria([_evento('e1')]);
        await repo.agregar(_evento('e2'));
        final eventos = await repo.listar();
        expect(eventos.map((e) => e.id), ['e2', 'e1']);
      },
    );

    test('no es remoto', () {
      expect(AuditoriaMemoria().esRemoto, isFalse);
    });
  });

  group('traducción a los textos de la base', () {
    test('cada acción vuelve igual', () {
      for (final a in AccionAuditoria.values) {
        expect(textoAAccion(accionATexto(a)), a);
      }
    });

    test('cada recurso vuelve igual y todos los textos son distintos', () {
      for (final r in RecursoAuditoria.values) {
        expect(textoARecurso(recursoATexto(r)), r);
      }
      final textos = RecursoAuditoria.values.map(recursoATexto).toSet();
      expect(textos.length, RecursoAuditoria.values.length);
    });

    test('cada resultado y cada propósito vuelve igual', () {
      for (final r in ResultadoAuditoria.values) {
        expect(textoAResultado(resultadoATexto(r)), r);
      }
      for (final p in Proposito.values) {
        expect(textoAProposito(propositoATexto(p)), p);
      }
    });

    test('sin propósito (No aplica) vuelve nulo', () {
      expect(textoAProposito(null), isNull);
    });

    test('los textos son los que acepta la tabla', () {
      expect(accionATexto(AccionAuditoria.ingresar), 'ingresar');
      expect(recursoATexto(RecursoAuditoria.sesion), 'sesion');
      expect(
        recursoATexto(RecursoAuditoria.pacientesAltaReciente),
        'pacientes_alta_reciente',
      );
      expect(propositoATexto(Proposito.urgencia), 'urgencia');
      expect(resultadoATexto(ResultadoAuditoria.denegado), 'denegado');
    });
  });
}
