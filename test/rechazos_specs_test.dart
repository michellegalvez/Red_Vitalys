import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/secciones.dart';
import 'package:red_vitalys/widgets/auditoria.dart';

import 'ayudas.dart';

// Rechazos por rol (F-18 A1 y CA-1 a CA-8; F-20 CA-4, CA-9 y CA-12; F-21
// CA-8; F-22 CA-5; F-01 CA-6; F-06 CA-9; F-04 CA-8; F-07 A3 y CA-6; F-02 A3
// y CA-6). Las pantallas no ofrecen esas acciones: se prueban por la puerta
// del sistema, `intentarAcceso`.

/// Intenta la acción y comprueba el aviso del rechazo.
Future<void> intentar(
  WidgetTester t,
  AccionPermitida accion,
  RecursoAuditoria recurso,
) async {
  final permitido = estadoApp(t).intentarAcceso(accion, recurso) as bool;
  expect(permitido, isFalse);
  await t.pump();
  expect(find.text(rechazoRol), findsOneWidget);
  await t.pumpAndSettle(const Duration(seconds: 6));
}

/// Con la auditoría abierta, deja solo los *Denegados* y comprueba que el
/// evento nuevo, el más reciente, es el esperado.
Future<void> comprobarEventoDenegado(
  WidgetTester t, {
  required RecursoAuditoria recurso,
  required AccionAuditoria accion,
}) async {
  await tocarAyuda(t, find.text('Denegados'));
  final total = denegadosIniciales() + 1;
  await t.ensureVisible(find.text('$total eventos'));
  expect(find.text('$total eventos'), findsOneWidget);
  final tarjeta = find.byType(TarjetaEvento).first;
  // Cada dato es una etiqueta y su valor, en dos textos de la tarjeta.
  Finder dentro(String texto) =>
      find.descendant(of: tarjeta, matching: find.text(texto));
  expect(dentro(recurso.nombre), findsOneWidget);
  expect(dentro(accion.nombre), findsOneWidget);
  expect(dentro('No aplica'), findsOneWidget);
  expect(dentro('Denegado'), findsOneWidget);
}

Future<void> verComoAuditor(WidgetTester t) async {
  await cerrarSesionDelMenu(t);
  await entrarSedeUnica(t, 'Auditor');
}

void main() {
  group('Rechazos por rol', () {
    testWidgets('administrativo: registrar una atención', (t) async {
      await abrirAppCon(t);
      await entrarSedeUnica(t, 'Administrativo');
      await intentar(
        t,
        AccionPermitida.registrarAtencion,
        RecursoAuditoria.atencion,
      );
      await verComoAuditor(t);
      await comprobarEventoDenegado(
        t,
        recurso: RecursoAuditoria.atencion,
        accion: AccionAuditoria.registrar,
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('auditor: buscar pacientes', (t) async {
      await abrirAppCon(t);
      await entrarSedeUnica(t, 'Auditor');
      await intentar(
        t,
        AccionPermitida.buscarPaciente,
        RecursoAuditoria.datosBasicos,
      );
      await comprobarEventoDenegado(
        t,
        recurso: RecursoAuditoria.datosBasicos,
        accion: AccionAuditoria.consultar,
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('médico: registrar una medición', (t) async {
      await abrirAppCon(t);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      await intentar(
        t,
        AccionPermitida.registrarMedicion,
        RecursoAuditoria.medicionIndicador,
      );
      await verComoAuditor(t);
      await comprobarEventoDenegado(
        t,
        recurso: RecursoAuditoria.medicionIndicador,
        accion: AccionAuditoria.registrar,
      );
      await cerrarAppAyuda(t);
    });

    for (final recurso in [
      RecursoAuditoria.historiaClinica,
      RecursoAuditoria.riesgoReingreso,
    ]) {
      testWidgets('administrativo: consultar ${recurso.nombre}', (t) async {
        await abrirAppCon(t);
        await entrarSedeUnica(t, 'Administrativo');
        await intentar(t, AccionPermitida.verHistoria, recurso);
        await verComoAuditor(t);
        await comprobarEventoDenegado(
          t,
          recurso: recurso,
          accion: AccionAuditoria.consultar,
        );
        await cerrarAppAyuda(t);
      });
    }

    testWidgets('médico: abrir la auditoría de accesos', (t) async {
      await abrirAppCon(t);
      await entrarMedica(t, proposito: 'Seguimiento de reingreso');
      await intentar(
        t,
        AccionPermitida.verAuditoria,
        RecursoAuditoria.auditoriaAccesos,
      );
      await verComoAuditor(t);
      await comprobarEventoDenegado(
        t,
        recurso: RecursoAuditoria.auditoriaAccesos,
        accion: AccionAuditoria.consultar,
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('administrativo: abrir la lista de alta reciente', (t) async {
      await abrirAppCon(t);
      await entrarSedeUnica(t, 'Administrativo');
      await intentar(
        t,
        AccionPermitida.verHistoria,
        RecursoAuditoria.pacientesAltaReciente,
      );
      await verComoAuditor(t);
      await comprobarEventoDenegado(
        t,
        recurso: RecursoAuditoria.pacientesAltaReciente,
        accion: AccionAuditoria.consultar,
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('lo que el rol sí tiene no se rechaza', (t) async {
      await abrirAppCon(t);
      await entrarSedeUnica(t, 'Administrativo');
      final permitido = estadoApp(t).intentarAcceso(
        AccionPermitida.registrarMedicion,
        RecursoAuditoria.medicionIndicador,
      ) as bool;
      expect(permitido, isTrue);
      await t.pump();
      expect(find.text(rechazoRol), findsNothing);
      await cerrarAppAyuda(t);
    });
  });

  group('Secciones y permisos coinciden', () {
    const accionPorSeccion = {
      Seccion.indicadores: AccionPermitida.verTablero,
      Seccion.buscar: AccionPermitida.buscarPaciente,
      Seccion.mediciones: AccionPermitida.registrarMedicion,
      Seccion.auditoria: AccionPermitida.verAuditoria,
      Seccion.inicio: AccionPermitida.verHistoria,
      Seccion.pacientes: AccionPermitida.verHistoria,
    };

    test('seccionesDe(rol) es lo que rolPermite deja ver', () {
      for (final rol in Rol.values) {
        for (final seccion in Seccion.values) {
          expect(
            seccionesDe(rol).contains(seccion),
            rolPermite(rol, accionPorSeccion[seccion]!),
            reason: '$rol / $seccion',
          );
          expect(accionDeSeccion(seccion), accionPorSeccion[seccion]);
        }
      }
    });
  });
}
