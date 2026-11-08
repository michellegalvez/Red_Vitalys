import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';

// Ayudas comunes de las pruebas de criterios: abrir la app con un reloj,
// entrar con cada rol y llamar a la puerta del sistema de AppScreen.

const celularAyuda = Size(360, 780);
const claveAyuda = 'vitalys2026';

/// Abre la app. Si no se pasa [reloj], usa el de los datos simulados.
Future<void> abrirAppCon(
  WidgetTester t, {
  Size tamano = celularAyuda,
  DateTime Function()? reloj,
}) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(
        datos: DatosSimulados.porDefecto,
        reloj: reloj ?? () => DatosSimulados.porDefecto.hoy,
      ),
    ),
  );
}

Future<void> tocarAyuda(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

Future<void> escribirAyuda(WidgetTester t, String correo, String clave) async {
  await t.enterText(find.byType(TextField).at(0), correo);
  await t.enterText(find.byType(TextField).at(1), clave);
  await t.pump();
}

/// Entra con un rol de una sola sede (administrativo o auditor).
Future<void> entrarSedeUnica(WidgetTester t, String perfil) async {
  await tocarAyuda(t, find.text(perfil));
  await tocarAyuda(t, find.text('Ingresar'));
  await tocarAyuda(t, find.text('Confirmar sede'));
}

/// Entra como la Dra. Camila con Cali Norte. Con [proposito] declara el de la
/// lista; sin él deja la ventana del propósito abierta.
Future<void> entrarMedica(WidgetTester t, {String? proposito}) async {
  await tocarAyuda(t, find.text('Médico'));
  await tocarAyuda(t, find.text('Ingresar'));
  await tocarAyuda(t, find.byType(DropdownButtonFormField<String>));
  await tocarAyuda(t, find.text('Clínica Vitalys Cali Norte').last);
  await tocarAyuda(t, find.text('Confirmar sede'));
  if (proposito == null) return;
  await tocarAyuda(t, find.text(proposito));
  await tocarAyuda(t, find.text('Ver pacientes'));
}

Future<void> cerrarSesionDelMenu(WidgetTester t) async {
  await tocarAyuda(t, find.byTooltip('Menú de usuario'));
  await tocarAyuda(t, find.text('Cerrar sesión'));
}

/// Cierra la app para que no quede pendiente el temporizador de inactividad.
Future<void> cerrarAppAyuda(WidgetTester t) => t.pumpWidget(const SizedBox());

/// El estado de AppScreen, para llamar a `intentarAcceso`.
dynamic estadoApp(WidgetTester t) => t.state(find.byType(AppScreen));

/// Cuántos eventos *Denegado* traen los datos simulados.
int denegadosIniciales() => DatosSimulados.porDefecto.eventos
    .where((e) => e.resultado == ResultadoAuditoria.denegado)
    .length;
