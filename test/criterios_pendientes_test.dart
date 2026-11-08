import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';

import 'ayudas.dart';

// Criterios de aceptación de F-14 (bloqueo), F-15 (cierre por inactividad),
// F-16 (declaración del propósito) y F-17 (acceso de emergencia) que no
// tenían prueba.

const _correoCamila = 'camila.martinez@vitalys.co';
const _jorge = 'Jorge Eliécer Pardo Villamizar';
const _hernan = 'Hernán Darío Quintero Salcedo';
const _seguimiento = 'Seguimiento de reingreso';
const _urgencia = 'Urgencia (acceso de emergencia)';

late DateTime ahora;

final _semillas = DatosSimulados.porDefecto.eventos;

int _semilla(bool Function(EventoAuditoria) condicion) =>
    _semillas.where(condicion).length;

Future<void> _abrir(WidgetTester t) {
  ahora = DateTime(2026, 11, 6, 10, 42);
  return abrirAppCon(t, reloj: () => ahora);
}

Future<void> _ingresarMal(WidgetTester t, String correo) async {
  await escribirAyuda(t, correo, 'mala');
  await tocarAyuda(t, find.text('Ingresar'));
}

Future<void> _fallar(WidgetTester t, int veces, {String? correo}) async {
  for (var i = 0; i < veces; i++) {
    await _ingresarMal(t, correo ?? _correoCamila);
  }
}

/// Pasa el tiempo para que el temporizador de inactividad se cumpla.
Future<void> _inactivos(WidgetTester t, Duration tiempo) async {
  await t.pump(tiempo);
  await t.pumpAndSettle();
}

Future<void> _verAuditoriaComoAuditor(WidgetTester t) =>
    entrarSedeUnica(t, 'Auditor');

Future<void> _volverALaLista(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

void main() {
  group('F-14 · Bloqueo del inicio de sesión', () {
    testWidgets('CA-1: el quinto fallo muestra el mensaje de bloqueo', (
      t,
    ) async {
      await _abrir(t);
      await _fallar(t, intentosParaBloqueo - 1);
      expect(find.text(mensajeBloqueo), findsNothing);
      await _fallar(t, 1);
      expect(find.text(mensajeBloqueo), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-2: bloqueado, las credenciales correctas no entran', (
      t,
    ) async {
      await _abrir(t);
      await _fallar(t, intentosParaBloqueo);
      await escribirAyuda(t, _correoCamila, claveAyuda);
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text(mensajeBloqueo), findsOneWidget);
      expect(find.text('Confirmar sede'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-3: a los 15 minutos entra', (t) async {
      await _abrir(t);
      await _fallar(t, intentosParaBloqueo);
      ahora = ahora.add(duracionBloqueo);
      await escribirAyuda(t, _correoCamila, claveAyuda);
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text('Confirmar sede'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-4: ingresar bien reinicia el conteo', (t) async {
      await _abrir(t);
      await _fallar(t, intentosParaBloqueo - 1);
      await entrarSedeUnica(t, 'Administrativo');
      await cerrarSesionDelMenu(t);

      await _fallar(t, intentosParaBloqueo - 1);
      expect(find.text(mensajeBloqueo), findsNothing);
      expect(find.text(mensajeDatosIncorrectos), findsOneWidget);
      await _fallar(t, 1);
      expect(find.text(mensajeBloqueo), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-5: con un correo que no existe bloquea igual', (t) async {
      await _abrir(t);
      await _fallar(t, intentosParaBloqueo, correo: 'nadie@vitalys.co');
      expect(find.text(mensajeBloqueo), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-6: 5 fallos entre 2 correos bloquean', (t) async {
      await _abrir(t);
      await _fallar(t, 3, correo: _correoCamila);
      await _fallar(t, 2, correo: 'andres.ruiz@vitalys.co');
      expect(find.text(mensajeBloqueo), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-7: el intento bloqueado deja un evento con correo e IP', (
      t,
    ) async {
      const correo = 'intruso@vitalys.co';
      await _abrir(t);
      await _fallar(t, intentosParaBloqueo, correo: correo);
      await escribirAyuda(t, correo, claveAyuda);
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text(mensajeBloqueo), findsOneWidget);

      ahora = ahora.add(duracionBloqueo);
      await _verAuditoriaComoAuditor(t);
      await tocarAyuda(t, find.text('Denegados'));
      // 5 fallos y el intento durante el bloqueo, todos con el correo escrito
      // y la IP.
      expect(find.text(correo), findsNWidgets(intentosParaBloqueo + 1));
      final conIp = _semilla((e) => e.ip != null);
      expect(
        find.text(DatosSimulados.porDefecto.ipPrototipo),
        findsNWidgets(conIp + intentosParaBloqueo + 1),
      );
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-9: la contraseña vacía no cuenta ni crea evento', (
      t,
    ) async {
      await _abrir(t);
      await _fallar(t, intentosParaBloqueo - 1);
      await escribirAyuda(t, _correoCamila, '');
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text(mensajeCamposVacios), findsOneWidget);
      expect(find.text(mensajeBloqueo), findsNothing);

      // Sigue en 4: el siguiente fallo es el quinto.
      await _fallar(t, 1);
      expect(find.text(mensajeBloqueo), findsOneWidget);

      ahora = ahora.add(duracionBloqueo);
      await _verAuditoriaComoAuditor(t);
      await tocarAyuda(t, find.text('Denegados'));
      final denegados = _semilla(
        (e) => e.resultado == ResultadoAuditoria.denegado,
      );
      // Los 5 fallos con contraseña; el intento vacío no creó ninguno.
      final total = denegados + intentosParaBloqueo;
      await t.ensureVisible(find.text('$total eventos'));
      expect(find.text('$total eventos'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('F-15 · Cierre por inactividad', () {
    testWidgets('CA-2: una acción a los 14 minutos reinicia la cuenta', (
      t,
    ) async {
      await _abrir(t);
      await entrarSedeUnica(t, 'Administrativo');
      await t.pump(const Duration(minutes: 14));
      await tocarAyuda(t, find.text('Mediciones'));
      await t.pump(const Duration(minutes: 14));
      await t.pumpAndSettle();
      expect(find.text('Registrar medición mensual'), findsOneWidget);
      expect(find.text(mensajeInactividad), findsNothing);
      await _inactivos(t, const Duration(minutes: 2));
      expect(find.text(mensajeInactividad), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-3: Atrás tras el cierre sigue en el inicio de sesión', (
      t,
    ) async {
      await _abrir(t);
      await entrarSedeUnica(t, 'Administrativo');
      await _inactivos(t, limiteInactividad);
      expect(find.text(mensajeInactividad), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Ingrese a su sesión'), findsOneWidget);
      expect(find.text('Tablero de indicadores'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-4: al volver a entrar hay que elegir la sede', (t) async {
      await _abrir(t);
      await entrarSedeUnica(t, 'Administrativo');
      await _inactivos(t, limiteInactividad);
      await tocarAyuda(t, find.text('Administrativo'));
      await tocarAyuda(t, find.text('Ingresar'));
      expect(find.text('Confirmar sede'), findsOneWidget);
      expect(find.text('Tablero de indicadores'), findsNothing);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-5: el cierre no deja ningún evento', (t) async {
      await _abrir(t);
      await entrarSedeUnica(t, 'Administrativo');
      await _inactivos(t, limiteInactividad);
      await entrarSedeUnica(t, 'Auditor');
      // Los de los datos simulados y los dos ingresos; ninguno del cierre.
      final total = _semillas.length + 2;
      await t.ensureVisible(find.text('$total eventos'));
      expect(find.text('$total eventos'), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });

  group('F-16 · Declaración del propósito', () {
    Future<void> elegirPaciente(WidgetTester t, String nombre) async {
      await tocarAyuda(t, find.text('Ver todos →'));
      await tocarAyuda(t, find.text(nombre));
    }

    testWidgets('CA-1: el médico ve los 5 propósitos y ninguno elegido', (
      t,
    ) async {
      await _abrir(t);
      await entrarMedica(t, proposito: _seguimiento);
      await elegirPaciente(t, _jorge);
      for (final p in Proposito.values) {
        expect(find.text(p.nombre), findsOneWidget, reason: p.nombre);
      }
      // Ninguno viene elegido: confirmar sin elegir lo pide.
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(mensajeElijaProposito), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-2: el administrativo solo ve Revisión de calidad', (
      t,
    ) async {
      await _abrir(t);
      await entrarSedeUnica(t, 'Administrativo');
      await tocarAyuda(t, find.text('Buscar'));
      await t.enterText(find.byType(TextField).first, 'Jorge');
      await t.pumpAndSettle();
      await tocarAyuda(t, find.text(_jorge));
      expect(find.text(Proposito.revisionCalidad.nombre), findsOneWidget);
      for (final p in Proposito.values.where(
        (p) => p != Proposito.revisionCalidad,
      )) {
        expect(find.text(p.nombre), findsNothing, reason: p.nombre);
      }
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-4: el propósito no se hereda al abrir a otro paciente', (
      t,
    ) async {
      await _abrir(t);
      await entrarMedica(t, proposito: _seguimiento);
      await elegirPaciente(t, _jorge);
      await tocarAyuda(t, find.text(Proposito.atencionPaciente.nombre));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      await _volverALaLista(t);

      await tocarAyuda(t, find.text(_hernan));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(mensajeElijaProposito), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-6: Seguimiento de reingreso queda en la auditoría', (
      t,
    ) async {
      await _abrir(t);
      await entrarMedica(t, proposito: _seguimiento);
      await elegirPaciente(t, _jorge);
      await tocarAyuda(t, find.text(_seguimiento));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      await _volverALaLista(t);
      await _volverALaLista(t);

      await cerrarSesionDelMenu(t);
      await entrarSedeUnica(t, 'Auditor');
      // La lista, la historia y el riesgo.
      final total = _semilla(
        (e) => e.proposito == Proposito.seguimientoReingreso,
      );
      expect(find.text(_seguimiento), findsNWidgets(total + 3));
      await cerrarAppAyuda(t);
    });
  });

  group('F-17 · Acceso de emergencia', () {
    int emergenciasIniciales() => _semilla(
      (e) =>
          e.proposito == Proposito.urgencia &&
          e.resultado == ResultadoAuditoria.permitido,
    );

    testWidgets('CA-4: Urgencia con relación abre la historia y es de '
        'emergencia', (t) async {
      await _abrir(t);
      await entrarMedica(t, proposito: _seguimiento);
      await tocarAyuda(t, find.text('Ver todos →'));
      await tocarAyuda(t, find.text(_jorge));
      await tocarAyuda(t, find.text(_urgencia));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(avisoAccesoEmergencia), findsWidgets);
      expect(find.text(rechazoRelacion), findsNothing);
      await _volverALaLista(t);
      await _volverALaLista(t);

      await cerrarSesionDelMenu(t);
      await entrarSedeUnica(t, 'Auditor');
      await tocarAyuda(t, find.text('Emergencia'));
      // La historia y el riesgo de ese acceso.
      final total = emergenciasIniciales() + 2;
      await t.ensureVisible(find.text('$total eventos'));
      expect(find.text('$total eventos'), findsOneWidget);
      await cerrarAppAyuda(t);
    });

    testWidgets('CA-5: sin relación y sin Urgencia se deniega y no es '
        'de emergencia', (t) async {
      await _abrir(t);
      await entrarMedica(t, proposito: _seguimiento);
      await tocarAyuda(t, find.text('Ver todos →'));
      await tocarAyuda(t, find.text(_hernan));
      await tocarAyuda(t, find.text(Proposito.atencionPaciente.nombre));
      await tocarAyuda(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);
      await _volverALaLista(t);
      await _volverALaLista(t);

      await cerrarSesionDelMenu(t);
      await entrarSedeUnica(t, 'Auditor');
      await tocarAyuda(t, find.text('Denegados'));
      // El de la historia y el del riesgo, además de los de los datos.
      final denegados = _semilla(
        (e) => e.resultado == ResultadoAuditoria.denegado,
      );
      await t.ensureVisible(find.text('${denegados + 2} eventos'));
      expect(find.text('${denegados + 2} eventos'), findsOneWidget);

      await tocarAyuda(t, find.text('Emergencia'));
      final emergencias = emergenciasIniciales();
      final texto = emergencias == 1 ? '1 evento' : '$emergencias eventos';
      await t.ensureVisible(find.text(texto));
      expect(find.text(texto), findsOneWidget);
      await cerrarAppAyuda(t);
    });
  });
}
