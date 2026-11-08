import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';

void main() {
  final datos = DatosSimulados.porDefecto;
  final camila = datos.usuarioPorCorreo('camila.martinez@vitalys.co')!;
  final andres = datos.usuarioPorCorreo('andres.ruiz@vitalys.co')!;
  PacienteEnSeguimiento paciente(String id) =>
      datos.pacientes.firstWhere((p) => p.id == id);

  group('alerta de riesgo (F-06)', () {
    test('70 tiene alerta y 69 no', () {
      expect(conAlerta(70), isTrue);
      expect(conAlerta(69), isFalse);
    });
  });

  group('pacientes con alta reciente (F-06)', () {
    final lista = pacientesConAltaReciente(datos.pacientes, datos.hoy);

    test('deja fuera el alta de hace más de 30 días', () {
      expect(lista.map((p) => p.id), isNot(contains('p9')));
      expect(lista, hasLength(8));
    });

    test('ordena del mayor al menor riesgo', () {
      final riesgos = lista.map((p) => p.riesgo).toList();
      expect(riesgos, [...riesgos]..sort((a, b) => b.compareTo(a)));
    });

    test('con el mismo riesgo va primero el alta más reciente', () {
      final a = paciente('p3');
      final antiguo = PacienteEnSeguimiento(
        id: 'x',
        nombre: 'X',
        iniciales: 'X',
        edad: 1,
        sexo: 'F',
        tipoDocumento: 'CC',
        numeroDocumento: '1',
        sedeAltaId: 's1',
        tipoAtencion: TipoAtencion.urgencias,
        fechaAlta: a.fechaAlta.subtract(const Duration(days: 2)),
        diasEstancia: 0,
        riesgo: a.riesgo,
      );
      final orden = pacientesConAltaReciente([antiguo, a], datos.hoy);
      expect(orden.first.id, 'p3');
    });

    test('hay al menos 4 pacientes con alerta (RNF-04)', () {
      expect(
        lista.where((p) => conAlerta(p.riesgo)).length,
        greaterThanOrEqualTo(4),
      );
    });
  });

  group('inicio de sesión (F-13, F-14)', () {
    ResultadoIngreso ingresar(
      String correo,
      String clave, {
      bool bloqueado = false,
    }) => evaluarIngreso(
      correo: correo,
      contrasena: clave,
      usuario: datos.usuarioPorCorreo(correo),
      contrasenaValida: datos.contrasenaPrototipo,
      bloqueado: bloqueado,
    );

    test('campos vacíos no cuentan como fallo', () {
      final r = ingresar('camila.martinez@vitalys.co', '');
      expect(r, ResultadoIngreso.camposVacios);
      expect(r.cuentaComoFallo, isFalse);
    });

    test('el mismo mensaje si el correo no existe o la clave está mal', () {
      final noExiste = ingresar('nadie@vitalys.co', 'vitalys2026');
      final malaClave = ingresar('camila.martinez@vitalys.co', 'otra');
      expect(noExiste.mensaje, mensajeDatosIncorrectos);
      expect(malaClave.mensaje, mensajeDatosIncorrectos);
      expect(noExiste.cuentaComoFallo, isTrue);
    });

    test('bloqueado no deja entrar aunque la clave sea correcta', () {
      final r = ingresar(
        'camila.martinez@vitalys.co',
        'vitalys2026',
        bloqueado: true,
      );
      expect(r.mensaje, mensajeBloqueo);
    });

    test('una cuenta sin sedes no entra', () {
      expect(
        ingresar('tomas.herrera@vitalys.co', 'vitalys2026').mensaje,
        mensajeSinSedes,
      );
    });

    test('datos correctos validan', () {
      expect(
        ingresar(' Camila.Martinez@vitalys.co ', 'vitalys2026'),
        ResultadoIngreso.valido,
      );
    });
  });

  group('propósito y relación (F-05, F-16, F-17, F-18)', () {
    test('el médico ve 5 propósitos, el administrativo 1, el auditor 0', () {
      expect(propositosDe(Rol.medico), hasLength(5));
      expect(propositosDe(Rol.administrativo), [Proposito.revisionCalidad]);
      expect(propositosDe(Rol.auditor), isEmpty);
    });

    test('hay relación por atención registrada o por alta en su sede', () {
      expect(tieneRelacion(camila, paciente('p1'), datos.hoy), isTrue);
      expect(tieneRelacion(camila, paciente('p2'), datos.hoy), isTrue);
      expect(tieneRelacion(camila, paciente('p3'), datos.hoy), isFalse);
    });

    test('sin relación se rechaza, salvo con Urgencia', () {
      ResultadoConsulta abrir(Proposito p) => evaluarConsulta(
        usuario: camila,
        paciente: paciente('p3'),
        proposito: p,
        hoy: datos.hoy,
      );
      expect(
        abrir(Proposito.atencionPaciente),
        ResultadoConsulta.rechazoRelacion,
      );
      expect(abrir(Proposito.urgencia), ResultadoConsulta.permitido);
    });

    test('el administrativo no abre la historia', () {
      final r = evaluarConsulta(
        usuario: andres,
        paciente: paciente('p1'),
        proposito: Proposito.urgencia,
        hoy: datos.hoy,
      );
      expect(r, ResultadoConsulta.rechazoRol);
    });

    test('los mensajes de rechazo no llevan datos del paciente', () {
      final p = paciente('p3');
      for (final r in ResultadoConsulta.values) {
        final m = r.mensaje ?? '';
        expect(m, isNot(contains(p.nombre.split(' ').first)));
        expect(m, isNot(contains(p.numeroDocumento)));
      }
    });
  });

  group('formato (RNF-05)', () {
    test('fecha, hora y estancia', () {
      expect(
        formatoFechaHora(DateTime(2026, 11, 6, 9, 5)),
        '6 nov 2026 · 09:05',
      );
      expect(formatoEstancia(0), 'Mismo día');
      expect(formatoEstancia(15), '15 d');
    });

    test('la búsqueda no distingue tildes ni mayúsculas', () {
      expect(normalizarTexto('  HERNÁN Darío '), 'hernan dario');
    });

    test('el documento se muestra con los últimos 4 dígitos', () {
      expect(paciente('p1').documentoOculto, 'CC ··· 7654');
    });
  });
}
