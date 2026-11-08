import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/app_screen.dart';
import 'package:red_vitalys/tema/tema.dart';

const celular = Size(360, 780);
const escritorio = Size(1280, 800);
const correoCamila = 'camila.martinez@vitalys.co';
const clave = 'vitalys2026';

late DateTime ahora;

Future<void> abrirApp(WidgetTester t, {Size tamano = celular}) async {
  t.view.physicalSize = tamano;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  ahora = DateTime(2026, 10, 30, 10, 42);
  await t.pumpWidget(
    MaterialApp(
      theme: temaRedVitalys(),
      home: AppScreen(datos: DatosSimulados.porDefecto, reloj: () => ahora),
    ),
  );
}

Future<void> tocar(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

Future<void> escribir(WidgetTester t, String correo, String contrasena) async {
  await t.enterText(find.byType(TextField).at(0), correo);
  await t.enterText(find.byType(TextField).at(1), contrasena);
  await t.pump();
}

Future<void> elegirSede(WidgetTester t, String sede) async {
  await tocar(t, find.byType(DropdownButtonFormField<String>));
  await tocar(t, find.text(sede).last);
}

/// Valida las credenciales y llega al paso de la sede (F-13).
Future<void> validarCredenciales(WidgetTester t, String correo) async {
  await escribir(t, correo, clave);
  await tocar(t, find.text('Ingresar'));
}

Future<void> declarar(WidgetTester t, String proposito, String boton) async {
  await tocar(t, find.text(proposito));
  await tocar(t, find.text(boton));
}

/// Entra como la Dra. Camila con Cali Norte y declara el propósito de la
/// lista, así queda en el Inicio.
Future<void> entrarComoMedico(WidgetTester t) async {
  await validarCredenciales(t, correoCamila);
  await elegirSede(t, 'Clínica Vitalys Cali Norte');
  await tocar(t, find.text('Confirmar sede'));
  await declarar(t, 'Seguimiento de reingreso', 'Ver pacientes');
}

/// Cierra la app para que no quede pendiente el temporizador de inactividad.
Future<void> cerrarApp(WidgetTester t) => t.pumpWidget(const SizedBox());

void main() {
  group('Acceso', () {
    testWidgets('al inicio no pide la sede, solo después de validar', (
      t,
    ) async {
      await abrirApp(t);
      expect(find.text('Ingrese a su sesión'), findsOneWidget);
      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
      expect(find.text('Sede desde la que ingresa'), findsNothing);

      await validarCredenciales(t, correoCamila);
      expect(find.text('Elija su sede'), findsOneWidget);
      expect(find.text('Dra. Camila Martínez'), findsOneWidget);
      expect(find.text('Sede desde la que ingresa'), findsOneWidget);
    });

    testWidgets('el panel visual de escritorio muestra lo que ofrece', (
      t,
    ) async {
      await abrirApp(t, tamano: escritorio);
      expect(find.text('Riesgo de reingreso explicado'), findsOneWidget);
      expect(find.text('Indicadores de las 46 sedes'), findsOneWidget);
      expect(find.text('Cada acceso auditado'), findsOneWidget);
    });

    testWidgets('el ojo muestra y oculta la contraseña', (t) async {
      await abrirApp(t);
      bool oculta() =>
          t.widget<TextField>(find.byType(TextField).at(1)).obscureText;
      expect(oculta(), isTrue);
      await tocar(t, find.byTooltip('Mostrar contraseña'));
      expect(oculta(), isFalse);
      await tocar(t, find.byTooltip('Ocultar contraseña'));
      expect(oculta(), isTrue);
    });

    testWidgets('con los campos vacíos pide el correo y la contraseña', (
      t,
    ) async {
      await abrirApp(t);
      await tocar(t, find.text('Ingresar'));
      expect(find.text(mensajeCamposVacios), findsOneWidget);
    });

    testWidgets('datos incorrectos muestran el mismo mensaje', (t) async {
      await abrirApp(t);
      await escribir(t, 'nadie@vitalys.co', clave);
      await tocar(t, find.text('Ingresar'));
      expect(find.text(mensajeDatosIncorrectos), findsOneWidget);
    });

    testWidgets('valida primero y solo ofrece las sedes asignadas', (t) async {
      await abrirApp(t);
      await validarCredenciales(t, correoCamila);
      expect(find.text('Confirmar sede'), findsOneWidget);
      await tocar(t, find.byType(DropdownButtonFormField<String>));
      expect(find.text('Clínica Vitalys Cali Norte'), findsWidgets);
      expect(find.text('Centro Ambulatorio Cali Sur'), findsWidgets);
      expect(find.text('Clínica Vitalys Bogotá Usaquén'), findsNothing);
    });

    testWidgets('sin confirmar la sede no entra, y Volver no abre la sesión', (
      t,
    ) async {
      await abrirApp(t);
      await validarCredenciales(t, correoCamila);
      await tocar(t, find.text('Confirmar sede'));
      expect(find.text(mensajeElijaSede), findsOneWidget);
      await tocar(t, find.text('Volver'));
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.text('Buenos días, Dra. Camila'), findsNothing);
    });

    testWidgets('5 fallos bloquean 15 minutos aunque la clave sea correcta', (
      t,
    ) async {
      await abrirApp(t);
      for (var i = 0; i < intentosParaBloqueo; i++) {
        await escribir(t, correoCamila, 'mala');
        await tocar(t, find.text('Ingresar'));
      }
      expect(find.text(mensajeBloqueo), findsOneWidget);

      await validarCredenciales(t, correoCamila);
      expect(find.text(mensajeBloqueo), findsOneWidget);
      expect(find.text('Confirmar sede'), findsNothing);

      ahora = ahora.add(duracionBloqueo);
      await validarCredenciales(t, correoCamila);
      expect(find.text('Confirmar sede'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('una cuenta sin sedes no entra', (t) async {
      await abrirApp(t);
      await validarCredenciales(t, 'tomas.herrera@vitalys.co');
      expect(find.text(mensajeSinSedes), findsOneWidget);
    });

    testWidgets('con una sola sede aparece elegida y hay que confirmarla', (
      t,
    ) async {
      await abrirApp(t);
      await tocar(t, find.text('Administrativo'));
      await tocar(t, find.text('Ingresar'));
      expect(find.text('Clínica Vitalys Bogotá Usaquén'), findsOneWidget);
      await tocar(t, find.text('Confirmar sede'));
      // Pantalla inicial del administrativo (RF-37).
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('el auditor entra a la auditoría de accesos', (t) async {
      await abrirApp(t);
      await tocar(t, find.text('Auditor'));
      await tocar(t, find.text('Ingresar'));
      await tocar(t, find.text('Confirmar sede'));
      expect(find.text('Auditoría de accesos'), findsWidgets);
      await cerrarApp(t);
    });
  });

  group('Propósito de la lista', () {
    testWidgets('el médico declara el propósito antes de ver pacientes', (
      t,
    ) async {
      await abrirApp(t);
      await validarCredenciales(t, correoCamila);
      await elegirSede(t, 'Clínica Vitalys Cali Norte');
      await tocar(t, find.text('Confirmar sede'));

      expect(find.text('ÚLTIMO PASO ANTES DE ENTRAR'), findsOneWidget);
      expect(
        find.text('¿Para qué va a mirar los pacientes con alta reciente?'),
        findsOneWidget,
      );
      expect(find.text('Buenos días, Dra. Camila'), findsOneWidget);
      expect(find.text('pacientes con alta reciente'), findsOneWidget);
      expect(find.text('Quedará registrado como'), findsOneWidget);
      expect(find.text('Jorge Eliécer Pardo Villamizar'), findsNothing);

      await tocar(t, find.text('Ver pacientes'));
      expect(find.text(mensajeElijaProposito), findsOneWidget);

      await declarar(t, 'Seguimiento de reingreso', 'Ver pacientes');
      expect(find.text('Buenos días, Dra. Camila'), findsOneWidget);
      expect(find.text('Jorge Eliécer Pardo Villamizar'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('cancelar la lista deja al médico en Indicadores', (t) async {
      await abrirApp(t);
      await validarCredenciales(t, correoCamila);
      await elegirSede(t, 'Clínica Vitalys Cali Norte');
      await tocar(t, find.text('Confirmar sede'));
      await tocar(t, find.text('Ahora no'));
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      expect(find.text('Jorge Eliécer Pardo Villamizar'), findsNothing);
      await cerrarApp(t);
    });
  });

  group('Inicio', () {
    testWidgets('muestra el resumen y la prioridad de hoy del Figma', (
      t,
    ) async {
      await abrirApp(t);
      await entrarComoMedico(t);
      expect(find.text('6 NOV 2026 · 10:42'), findsOneWidget);
      expect(find.text('Buenos días, Dra. Camila'), findsOneWidget);
      expect(find.text('Pacientes con alerta'), findsOneWidget);
      expect(find.text('Riesgo de reingreso desde 70'), findsOneWidget);
      expect(find.text('frente al mes previo, de 4'), findsOneWidget);
      expect(find.text('Jorge Eliécer Pardo Villamizar'), findsOneWidget);
      expect(find.text('91'), findsOneWidget);
      await cerrarApp(t);
    });
  });

  group('Pacientes en seguimiento', () {
    Future<void> abrirLista(WidgetTester t, {Size tamano = celular}) async {
      await abrirApp(t, tamano: tamano);
      await entrarComoMedico(t);
      await tocar(t, find.text('Ver todos →'));
    }

    testWidgets(
      'muestra las 8 altas recientes, sin filtros de sede ni riesgo',
      (t) async {
        await abrirLista(t);
        expect(find.text('Pacientes en seguimiento'), findsOneWidget);
        expect(find.text('Buscar por nombre o documento'), findsOneWidget);
        expect(find.text('Sede: todas'), findsNothing);
        expect(find.text('Con alerta (4)'), findsNothing);
        expect(find.text('Rosa Elena Muñoz Patiño'), findsNothing);
        await t.ensureVisible(find.text('8 pacientes'));
        expect(find.text('8 pacientes'), findsOneWidget);
        await cerrarApp(t);
      },
    );

    testWidgets('busca por nombre sin tildes desde 3 caracteres', (t) async {
      await abrirLista(t);
      await t.enterText(find.byType(TextField).first, 'he');
      await t.pump();
      expect(find.textContaining('al menos 3 caracteres'), findsOneWidget);

      await t.enterText(find.byType(TextField).first, 'hernan');
      await t.pump();
      expect(find.text('Hernán Darío Quintero Salcedo'), findsOneWidget);
      expect(find.text('1 paciente'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('una búsqueda sin resultados lo avisa', (t) async {
      await abrirLista(t);
      await t.enterText(find.byType(TextField).first, 'zzzzzz');
      await t.pump();
      expect(find.text('Ningún paciente coincide con la búsqueda.'), findsOne);
      await t.ensureVisible(find.text('0 pacientes'));
      expect(find.text('0 pacientes'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('al abrir un paciente se pide el propósito sin elegir', (
      t,
    ) async {
      await abrirLista(t);
      await tocar(t, find.text('María Fernanda Rojas Benítez'));
      expect(find.text('ANTES DE ABRIR LA HISTORIA'), findsOneWidget);
      expect(
        find.text('¿Para qué va a abrir a este paciente?'),
        findsOneWidget,
      );
      expect(find.textContaining('CC ··· 5876'), findsWidgets);
      await tocar(t, find.text('Abrir historia clínica'));
      expect(find.text(mensajeElijaProposito), findsOneWidget);

      await tocar(t, find.text('Cancelar'));
      expect(find.text('Pacientes en seguimiento'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('sin relación se deniega y con Urgencia se abre marcado', (
      t,
    ) async {
      await abrirLista(t);
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      await tocar(t, find.text('Atención del paciente'));
      await tocar(t, find.text('Abrir historia clínica'));
      expect(find.text(rechazoRelacion), findsOneWidget);
      expect(find.text('Hernán Darío Quintero Salcedo'), findsNothing);

      await tocar(t, find.text('Declarar Urgencia'));
      // El pop-up vuelve sin propósito elegido: se elige Urgencia (F-16).
      await tocar(t, find.text('Urgencia (acceso de emergencia)'));
      expect(find.text(avisoDeclarandoUrgencia), findsOneWidget);
      await tocar(t, find.text('Abrir historia clínica'));
      expect(find.text(avisoAccesoEmergencia), findsOneWidget);

      await tocar(t, find.textContaining('Pacientes  /'));
      expect(find.text('Pacientes en seguimiento'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('con relación abre al paciente sin aviso de emergencia', (
      t,
    ) async {
      await abrirLista(t);
      await tocar(t, find.text('María Fernanda Rojas Benítez'));
      await tocar(t, find.text('Consulta de historia clínica'));
      await tocar(t, find.text('Abrir historia clínica'));
      expect(
        find.textContaining('Propósito: Consulta de historia clínica'),
        findsOne,
      );
      expect(find.text(avisoAccesoEmergencia), findsNothing);
      await cerrarApp(t);
    });

    testWidgets('en escritorio se ve sin desbordes', (t) async {
      await abrirLista(t, tamano: escritorio);
      expect(find.text('Pacientes en seguimiento'), findsOneWidget);
      expect(t.takeException(), isNull);
      await cerrarApp(t);
    });
  });

  group('Botón Atrás del sistema', () {
    Future<void> atras(WidgetTester t) async {
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
    }

    Future<void> abrirLista(WidgetTester t) async {
      await abrirApp(t);
      await entrarComoMedico(t);
      await tocar(t, find.text('Ver todos →'));
    }

    testWidgets('en el paso de la sede vuelve a las credenciales', (t) async {
      await abrirApp(t);
      await validarCredenciales(t, correoCamila);
      expect(find.text('Elija su sede'), findsOneWidget);
      await atras(t);
      expect(find.text('Ingrese a su sesión'), findsOneWidget);
      expect(find.text('Elija su sede'), findsNothing);
    });

    testWidgets('cierra el pop-up de un paciente sin abrirlo', (t) async {
      await abrirLista(t);
      await tocar(t, find.text('María Fernanda Rojas Benítez'));
      expect(find.text('ANTES DE ABRIR LA HISTORIA'), findsOneWidget);
      await atras(t);
      expect(find.text('ANTES DE ABRIR LA HISTORIA'), findsNothing);
      expect(find.text('Pacientes en seguimiento'), findsOneWidget);
      expect(
        find.textContaining('Propósito: Consulta de historia clínica'),
        findsNothing,
      );
      await cerrarApp(t);
    });

    testWidgets('en la pantalla del último paso equivale a Ahora no', (
      t,
    ) async {
      await abrirApp(t);
      await validarCredenciales(t, correoCamila);
      await elegirSede(t, 'Clínica Vitalys Cali Norte');
      await tocar(t, find.text('Confirmar sede'));
      expect(find.text('ÚLTIMO PASO ANTES DE ENTRAR'), findsOneWidget);
      await atras(t);
      expect(find.text('ÚLTIMO PASO ANTES DE ENTRAR'), findsNothing);
      expect(find.text('Tablero de indicadores'), findsOneWidget);
      await cerrarApp(t);
    });

    testWidgets('desde una consulta vuelve a la lista', (t) async {
      await abrirLista(t);
      await tocar(t, find.text('María Fernanda Rojas Benítez'));
      await declarar(
        t,
        'Consulta de historia clínica',
        'Abrir historia clínica',
      );
      expect(find.textContaining('Pacientes  /'), findsOneWidget);
      await atras(t);
      expect(find.textContaining('Pacientes  /'), findsNothing);
      expect(find.text('Pacientes en seguimiento'), findsOneWidget);
      await cerrarApp(t);
    });
  });

  group('Pop-up modal', () {
    testWidgets('Esc cierra el pop-up y el fondo no recibe toques', (t) async {
      await abrirApp(t);
      await entrarComoMedico(t);
      await tocar(t, find.text('Ver todos →'));
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      expect(find.text('ANTES DE ABRIR LA HISTORIA'), findsOneWidget);

      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('ANTES DE ABRIR LA HISTORIA'), findsNothing);
      await cerrarApp(t);
    });

    testWidgets('mientras está abierto el fondo no aparece en la semántica', (
      t,
    ) async {
      final semantica = t.ensureSemantics();
      await abrirApp(t);
      await entrarComoMedico(t);
      await tocar(t, find.text('Ver todos →'));
      await tocar(t, find.text('Hernán Darío Quintero Salcedo'));
      expect(
        find.bySemanticsLabel('Abrir a Jorge Eliécer Pardo Villamizar'),
        findsNothing,
      );
      semantica.dispose();
      await cerrarApp(t);
    });
  });

  group('Sesión', () {
    testWidgets('a los 15 minutos sin uso se cierra la sesión', (t) async {
      await abrirApp(t);
      await entrarComoMedico(t);
      await t.pump(limiteInactividad);
      await t.pumpAndSettle();
      expect(find.text(mensajeInactividad), findsOneWidget);
      expect(find.text('Ingrese a su sesión'), findsOneWidget);
    });

    testWidgets('Salir vuelve al inicio de sesión', (t) async {
      await abrirApp(t, tamano: escritorio);
      await entrarComoMedico(t);
      await tocar(t, find.byTooltip('Menú de usuario'));
      expect(find.text('Médico · Cali Norte'), findsOneWidget);
      await tocar(t, find.text('Cerrar sesión'));
      expect(find.text('Ingrese a su sesión'), findsOneWidget);
      expect(find.text(mensajeInactividad), findsNothing);
    });
  });
}
