import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/modelos/modelos.dart';

EventoAuditoria _evento(Proposito? proposito, ResultadoAuditoria resultado) =>
    EventoAuditoria(
      id: 'x',
      fechaHora: DateTime(2026, 11, 6, 10, 42),
      accion: AccionAuditoria.consultar,
      recurso: RecursoAuditoria.historiaClinica,
      resultado: resultado,
      proposito: proposito,
    );

void main() {
  group('Emergencia (F-17, F-20, F-21)', () {
    test('es de emergencia con Urgencia y resultado Permitido', () {
      expect(
        _evento(Proposito.urgencia, ResultadoAuditoria.permitido).esEmergencia,
        isTrue,
      );
    });

    test('con Urgencia pero Denegado no es de emergencia', () {
      expect(
        _evento(Proposito.urgencia, ResultadoAuditoria.denegado).esEmergencia,
        isFalse,
      );
    });

    test('con otro propósito, permitido, no es de emergencia', () {
      expect(
        _evento(
          Proposito.atencionPaciente,
          ResultadoAuditoria.permitido,
        ).esEmergencia,
        isFalse,
      );
    });

    test('sin propósito (No aplica) no es de emergencia', () {
      expect(_evento(null, ResultadoAuditoria.permitido).esEmergencia, isFalse);
    });
  });
}
