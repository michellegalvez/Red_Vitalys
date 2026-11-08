import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/modelos/indicadores.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/pages/acceso_page.dart';
import 'package:red_vitalys/pages/auditoria_page.dart';
import 'package:red_vitalys/pages/buscar_pacientes_page.dart';
import 'package:red_vitalys/pages/datos_basicos_page.dart';
import 'package:red_vitalys/pages/consulta_page.dart';
import 'package:red_vitalys/pages/indicadores_page.dart';
import 'package:red_vitalys/pages/inicio_page.dart';
import 'package:red_vitalys/pages/paciente_page.dart';
import 'package:red_vitalys/pages/perfil_page.dart';
import 'package:red_vitalys/pages/proposito_lista_page.dart';
import 'package:red_vitalys/pages/registrar_atencion_page.dart';
import 'package:red_vitalys/pages/registrar_medicion_page.dart';
import 'package:red_vitalys/pages/seguimiento_page.dart';
import 'package:red_vitalys/reglas/busqueda.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/secciones.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/navegacion.dart';
import 'package:red_vitalys/widgets/proposito.dart';

part 'app_screen_paginas.dart';

/// Una declaración de propósito en curso. Sin paciente es la de la lista de
/// pacientes con alta reciente (F-06); con paciente, la de abrirlo o, si
/// [registrar], la de registrarle una atención (F-04).
class _Solicitud {
  const _Solicitud({
    this.paciente,
    this.elegido,
    this.error,
    this.registrar = false,
  });

  final PacienteEnSeguimiento? paciente;
  final Proposito? elegido;
  final String? error;
  final bool registrar;
}

/// Un paciente abierto con el propósito declarado: su historia, sus datos
/// básicos (F-03) o el registro de una atención en curso (F-04).
typedef _ConsultaAbierta = ({
  PacienteEnSeguimiento paciente,
  Proposito proposito,
});

/// Un acceso rechazado: al abrir al paciente o al registrarle una atención.
typedef _Denegado = ({
  PacienteEnSeguimiento paciente,
  ResultadoConsulta resultado,
  bool alRegistrar,
});

/// Screen anfitriona: guarda todo el estado de la app con `setState` y se
/// lo pasa a las Pages, que solo muestran y avisan por callbacks.
class AppScreen extends StatefulWidget {
  const AppScreen({super.key, required this.datos, this.reloj = DateTime.now});

  final DatosSimulados datos;

  /// Hora real del dispositivo, para el bloqueo de 15 minutos (F-14).
  final DateTime Function() reloj;

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  DatosSimulados get _datos => widget.datos;

  // Sesión (F-13, F-15, F-23).
  Usuario? _usuario;
  String? _sedeSesion;
  Timer? _temporizadorInactividad;

  // El Navigator interno: el botón Atrás del sistema le llega por aquí.
  final _navegador = GlobalKey<NavigatorState>();

  // Inicio de sesión.
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  PasoAcceso _paso = PasoAcceso.credenciales;
  Usuario? _usuarioValidado;
  bool _mostrarContrasena = false;
  bool _ingresando = false;
  String? _mensajeError;
  String? _avisoInactividad;
  String? _sedeElegida;
  String? _errorSede;

  // Bloqueo del dispositivo (F-14).
  int _fallosSeguidos = 0;
  DateTime? _bloqueadoDesde;

  // Navegación y consultas.
  Seccion _seccion = Seccion.inicio;
  bool _listaDeclarada = false;
  _Solicitud? _solicitud;
  _ConsultaAbierta? _historia;
  _ConsultaAbierta? _registro;
  _Denegado? _denegado;
  bool _verPerfil = false;
  IdIndicador? _indicadorAbierto;
  _ConsultaAbierta? _datosBasicos;

  /// La sede de la tendencia en el detalle de un indicador. `null` es *Toda
  /// la red* (F-09).
  String? _sedeTendencia;
  String _busquedaPaciente = '';

  /// El indicador cuyas sedes se ven en el tablero (F-08).
  IdIndicador _indicadorTablero = IdIndicador.reingreso;

  // Pacientes y atenciones registradas en esta sesión. Viven aquí, en la
  // Screen anfitriona; las Pages solo las muestran.
  late List<PacienteEnSeguimiento> _pacientes = [..._datos.pacientes];
  Map<String, List<Encounter>> _atenciones = {};

  // Mediciones de los indicadores. Las que registra el administrativo se
  // agregan aquí y el tablero se recalcula (F-12).
  late List<Medicion> _mediciones = [..._datos.mediciones];

  // Filtros de Pacientes en seguimiento.
  String _busqueda = '';

  // Auditoría de accesos (F-20, F-21). Los eventos solo se agregan con
  // [_registrarEvento]: nunca se editan ni se borran (AD-08).
  late final List<EventoAuditoria> _eventos = [..._datos.eventos];
  FiltroAuditoria _filtroAuditoria = FiltroAuditoria.todos;

  @override
  void dispose() {
    _temporizadorInactividad?.cancel();
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Inicio y cierre de sesión
  // ---------------------------------------------------------------------

  bool get _bloqueado {
    final desde = _bloqueadoDesde;
    if (desde == null) return false;
    return widget.reloj().isBefore(desde.add(duracionBloqueo));
  }

  Future<void> _ingresar() async {
    if (_ingresando) return;
    if (!_bloqueado && _bloqueadoDesde != null) {
      // Pasaron los 15 minutos: se desbloquea solo (F-14).
      _bloqueadoDesde = null;
      _fallosSeguidos = 0;
    }
    // Se valida con lo que había al pulsar Ingresar; después del await no se
    // vuelve a leer el campo.
    final correoEscrito = _correo.text.trim();
    final usuarioEscrito = _datos.usuarioPorCorreo(correoEscrito);
    final resultado = evaluarIngreso(
      correo: _correo.text,
      contrasena: _contrasena.text,
      usuario: usuarioEscrito,
      contrasenaValida: _datos.contrasenaPrototipo,
      bloqueado: _bloqueado,
    );
    if (resultado == ResultadoIngreso.camposVacios) {
      setState(() {
        _mensajeError = resultado.mensaje;
        _avisoInactividad = null;
      });
      return;
    }

    setState(() {
      _ingresando = true;
      _avisoInactividad = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    setState(() {
      _ingresando = false;
      if (resultado.cuentaComoFallo ||
          resultado == ResultadoIngreso.bloqueado ||
          resultado == ResultadoIngreso.sinSedes) {
        // Inicio de sesión fallido, intento durante el bloqueo o cuenta sin
        // sedes (F-13 A3, F-14 A3, F-20 A4): con el correo escrito, la IP y
        // sin sede. La cuenta sin sedes no suma al bloqueo.
        _registrarEvento(
          accion: AccionAuditoria.ingresar,
          recurso: RecursoAuditoria.sesion,
          resultado: ResultadoAuditoria.denegado,
          correoIntento: correoEscrito,
          ip: _datos.ipPrototipo,
        );
      }
      if (resultado.cuentaComoFallo) {
        _fallosSeguidos++;
        _contrasena.clear();
        if (_fallosSeguidos >= intentosParaBloqueo) {
          _bloqueadoDesde = widget.reloj();
          _mensajeError = mensajeBloqueo;
        } else {
          _mensajeError = resultado.mensaje;
        }
        return;
      }
      if (resultado != ResultadoIngreso.valido) {
        _mensajeError = resultado.mensaje;
        return;
      }
      final usuario = usuarioEscrito;
      if (usuario == null) return;
      _fallosSeguidos = 0;
      _mensajeError = null;
      _usuarioValidado = usuario;
      _paso = PasoAcceso.sede;
      _errorSede = null;
      // Con una sola sede, esa aparece elegida (F-13 A4).
      _sedeElegida = usuario.sedesAsignadas.length == 1
          ? usuario.sedesAsignadas.first
          : null;
    });
  }

  /// El usuario confirma la sede y se abre la sesión (F-13 pasos 4 a 6).
  void _confirmarSede() {
    final usuario = _usuarioValidado;
    final sede = _sedeElegida;
    if (usuario == null) return;
    if (sede == null || !usuario.sedesAsignadas.contains(sede)) {
      setState(() => _errorSede = mensajeElijaSede);
      return;
    }
    setState(() {
      // El ingreso se registra al confirmar la sede, antes de abrir la
      // sesión, porque lleva la sede (F-13 paso 5, F-20 A3).
      _registrarEvento(
        usuario: usuario,
        sedeId: sede,
        accion: AccionAuditoria.ingresar,
        recurso: RecursoAuditoria.sesion,
        resultado: ResultadoAuditoria.permitido,
      );
      _fallosSeguidos = 0;
      _mensajeError = null;
      _errorSede = null;
      _usuario = usuario;
      _usuarioValidado = null;
      _paso = PasoAcceso.credenciales;
      _sedeSesion = sede;
      _contrasena.clear();
      _busqueda = '';
      _irA(seccionesDe(usuario.rol).first);
    });
    _registrarActividad();
  }

  /// El usuario sale sin confirmar la sede: no se abre la sesión (F-13 A6).
  void _volverACredenciales() {
    setState(() {
      _paso = PasoAcceso.credenciales;
      _usuarioValidado = null;
      _sedeElegida = null;
      _errorSede = null;
      _contrasena.clear();
    });
  }

  /// Cierra la sesión a mano (F-23) o por inactividad (F-15). Se borran la
  /// sede, la consulta abierta y lo que no se había guardado.
  void _cerrarSesion({bool porInactividad = false}) {
    _temporizadorInactividad?.cancel();
    setState(() {
      _usuario = null;
      _usuarioValidado = null;
      _paso = PasoAcceso.credenciales;
      _sedeElegida = null;
      _sedeSesion = null;
      _solicitud = null;
      _cerrarDetalles();
      _listaDeclarada = false;
      _filtroAuditoria = FiltroAuditoria.todos;
      // Lo escrito en las búsquedas no pasa al siguiente usuario (F-15).
      _busqueda = '';
      _busquedaPaciente = '';
      _seccion = Seccion.inicio;
      _indicadorTablero = IdIndicador.reingreso;
      _correo.clear();
      _contrasena.clear();
      _mostrarContrasena = false;
      _mensajeError = null;
      _avisoInactividad = porInactividad ? mensajeInactividad : null;
    });
  }

  void _registrarActividad() {
    if (_usuario == null) return;
    _temporizadorInactividad?.cancel();
    _temporizadorInactividad = Timer(
      limiteInactividad,
      () => _cerrarSesion(porInactividad: true),
    );
  }

  /// Agrega un evento de acceso con la hora de los datos simulados, la
  /// misma que el diálogo muestra en *Quedará registrado* (F-20). Es la
  /// única forma de cambiar [_eventos], y solo agrega. Llamar dentro de
  /// `setState`.
  void _registrarEvento({
    required AccionAuditoria accion,
    required RecursoAuditoria recurso,
    required ResultadoAuditoria resultado,
    Usuario? usuario,
    String? sedeId,
    String? correoIntento,
    PacienteEnSeguimiento? paciente,
    Proposito? proposito,
    String? ip,
  }) {
    _eventos.add(
      EventoAuditoria(
        id: 'e${_eventos.length + 1}',
        usuarioId: usuario?.id,
        correoIntento: correoIntento,
        pacienteId: paciente?.id,
        fechaHora: _datos.hoy,
        accion: accion,
        recurso: recurso,
        resultado: resultado,
        proposito: proposito,
        sedeId: sedeId,
        ip: ip,
      ),
    );
  }

  void _rellenarPerfil(String correo) {
    setState(() {
      _correo.text = correo;
      _contrasena.text = _datos.contrasenaPrototipo;
      _mensajeError = null;
    });
  }

  // ---------------------------------------------------------------------
  // Navegación y propósito
  // ---------------------------------------------------------------------

  /// Cambia de sección. Llamar dentro de `setState`.
  void _irA(Seccion seccion) {
    _seccion = seccion;
    // Al abrir la auditoría el filtro es *Todos* (F-21).
    if (seccion == Seccion.auditoria) _filtroAuditoria = FiltroAuditoria.todos;
    if (!seccion.muestraPacientes) {
      _listaDeclarada = false;
      _solicitud = null;
    } else if (!_listaDeclarada) {
      // Sin propósito no se ve ningún paciente (F-06 CA-12, F-16 CA-8).
      _solicitud = const _Solicitud();
    }
  }

  void _elegirSeccion(Seccion seccion) {
    final usuario = _usuario;
    if (usuario == null) return;
    if (!seccionesDe(usuario.rol).contains(seccion)) {
      _rechazarPorRol(usuario, RecursoAuditoria.pacientesAltaReciente);
      return;
    }
    setState(() => _irA(seccion));
  }

  /// Lo que el rol no tiene en la tabla de F-18 se rechaza y queda como
  /// evento *Denegado* (F-18 CA-1, F-20). La navegación no ofrece esas
  /// acciones; esta es la guarda por si se llega por otro camino.
  void _rechazarPorRol(Usuario usuario, RecursoAuditoria recurso) {
    setState(() {
      _registrarEvento(
        usuario: usuario,
        sedeId: _sedeSesion,
        accion:
            recurso == RecursoAuditoria.atencion ||
                recurso == RecursoAuditoria.medicionIndicador
            ? AccionAuditoria.registrar
            : AccionAuditoria.consultar,
        recurso: recurso,
        resultado: ResultadoAuditoria.denegado,
      );
    });
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text(rechazoRol)));
  }

  void _verPacientes() => _elegirSeccion(Seccion.pacientes);

  void _abrirPaciente(PacienteEnSeguimiento p) {
    // El propósito no se hereda: arranca sin elegir (F-16 CA-4).
    setState(() => _solicitud = _Solicitud(paciente: p));
  }

  /// El médico elige *Registrar atención* en la historia: antes declara el
  /// propósito (F-04, F-16).
  void _pedirRegistro(PacienteEnSeguimiento p) {
    final usuario = _usuario;
    if (usuario == null) return;
    if (!rolPermite(usuario.rol, AccionPermitida.registrarAtencion)) {
      _rechazarPorRol(usuario, RecursoAuditoria.atencion);
      return;
    }
    setState(() => _solicitud = _Solicitud(paciente: p, registrar: true));
  }

  void _elegirProposito(Proposito p) {
    final s = _solicitud;
    if (s == null) return;
    setState(() {
      _solicitud = _Solicitud(
        paciente: s.paciente,
        elegido: p,
        registrar: s.registrar,
      );
    });
  }

  void _confirmarProposito() {
    final s = _solicitud;
    final usuario = _usuario;
    if (s == null || usuario == null) return;
    final elegido = s.elegido;
    if (elegido == null) {
      setState(() {
        _solicitud = _Solicitud(
          paciente: s.paciente,
          error: mensajeElijaProposito,
          registrar: s.registrar,
        );
      });
      return;
    }
    final paciente = s.paciente;
    setState(() {
      _solicitud = null;
      if (paciente == null) {
        // Abrir la lista de pacientes con alta reciente (F-06 paso 3).
        _registrarEvento(
          usuario: usuario,
          sedeId: _sedeSesion,
          accion: AccionAuditoria.consultar,
          recurso: RecursoAuditoria.pacientesAltaReciente,
          resultado: ResultadoAuditoria.permitido,
          proposito: elegido,
        );
        _listaDeclarada = true;
        return;
      }
      if (usuario.rol == Rol.administrativo) {
        // El administrativo no ve la historia: solo los datos básicos (F-03).
        final r = evaluarDatosBasicos(usuario: usuario, proposito: elegido);
        final ok = r == ResultadoConsulta.permitido;
        _registrarEvento(
          usuario: usuario,
          sedeId: _sedeSesion,
          accion: AccionAuditoria.consultar,
          recurso: RecursoAuditoria.datosBasicos,
          resultado: ok
              ? ResultadoAuditoria.permitido
              : ResultadoAuditoria.denegado,
          paciente: paciente,
          proposito: elegido,
        );
        if (ok) {
          _datosBasicos = (paciente: paciente, proposito: elegido);
        } else {
          _denegado = (paciente: paciente, resultado: r, alRegistrar: false);
        }
        return;
      }
      final resultado = s.registrar
          ? evaluarRegistro(
              usuario: usuario,
              paciente: paciente,
              proposito: elegido,
              hoy: _datos.hoy,
            )
          : evaluarConsulta(
              usuario: usuario,
              paciente: paciente,
              proposito: elegido,
              hoy: _datos.hoy,
            );
      final permitido = resultado == ResultadoConsulta.permitido;
      if (s.registrar) {
        // Registrar una atención (F-04): el evento *Permitido* se crea al
        // guardarla; el rechazo queda registrado ya (F-18).
        if (permitido) {
          _registro = (paciente: paciente, proposito: elegido);
        } else {
          _registrarEvento(
            usuario: usuario,
            sedeId: _sedeSesion,
            accion: AccionAuditoria.registrar,
            recurso: RecursoAuditoria.atencion,
            resultado: ResultadoAuditoria.denegado,
            paciente: paciente,
            proposito: elegido,
          );
          _denegado = (
            paciente: paciente,
            resultado: resultado,
            alRegistrar: true,
          );
        }
        return;
      }
      // Abrir a un paciente, se permita o se deniegue (F-02, F-17, F-18).
      // Con *Urgencia* permitida queda en el filtro Emergencia.
      _registrarEvento(
        usuario: usuario,
        sedeId: _sedeSesion,
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.historiaClinica,
        resultado: permitido
            ? ResultadoAuditoria.permitido
            : ResultadoAuditoria.denegado,
        paciente: paciente,
        proposito: elegido,
      );
      if (permitido) {
        // La historia muestra también el riesgo de reingreso: es otro
        // recurso y deja su propio evento (F-07 pasos 3-4).
        _registrarEvento(
          usuario: usuario,
          sedeId: _sedeSesion,
          accion: AccionAuditoria.consultar,
          recurso: RecursoAuditoria.riesgoReingreso,
          resultado: ResultadoAuditoria.permitido,
          paciente: paciente,
          proposito: elegido,
        );
        _historia = (paciente: paciente, proposito: elegido);
      } else {
        _denegado = (
          paciente: paciente,
          resultado: resultado,
          alRegistrar: false,
        );
      }
    });
  }

  /// Cancelar no consulta nada (F-16 A2). Si era la lista, el médico queda
  /// en Indicadores, que no muestra pacientes.
  void _cancelarProposito() {
    final s = _solicitud;
    if (s == null) return;
    setState(() {
      _solicitud = null;
      if (s.paciente == null) _irA(Seccion.indicadores);
    });
  }

  /// Cierra todo lo que se abre encima de las secciones.
  /// Llamar dentro de `setState`.
  void _cerrarDetalles() {
    _historia = null;
    _registro = null;
    _denegado = null;
    _verPerfil = false;
    _indicadorAbierto = null;
    _sedeTendencia = null;
    _datosBasicos = null;
  }

  void _cerrarHistoria() => setState(() {
    _historia = null;
    _registro = null;
  });

  void _cerrarDenegado() => setState(() => _denegado = null);

  void _declararUrgencia() {
    final d = _denegado;
    if (d == null) return;
    setState(() => _denegado = null);
    // Vuelve a pedir el propósito sin ninguno elegido: el médico elige
    // *Urgencia* y confirma (F-16, F-17 paso 2).
    if (d.alRegistrar) {
      _pedirRegistro(d.paciente);
    } else {
      _abrirPaciente(d.paciente);
    }
  }

  /// Valida una medición con las reglas de F-12. Devuelve el mensaje de
  /// rechazo o `null` si se puede guardar.
  String? _validarMedicion(NuevaMedicion m) {
    return validarMedicion(
      indicador: indicadorDe(m.indicador),
      sede: _datos.sede(m.sedeId),
      periodo: m.periodo,
      valorTexto: m.valorTexto,
      hoy: _datos.hoy,
      existentes: _mediciones,
    );
  }

  /// Guarda la medición: entra al tablero y a las mediciones recientes, y
  /// deja su evento sin paciente y con propósito *No aplica* (F-12, F-20).
  void _guardarMedicion(NuevaMedicion nueva) {
    final usuario = _usuario;
    final valor = leerValor(nueva.valorTexto);
    if (usuario == null || valor == null) return;
    if (!rolPermite(usuario.rol, AccionPermitida.registrarMedicion)) {
      _rechazarPorRol(usuario, RecursoAuditoria.medicionIndicador);
      return;
    }
    // Se vuelve a validar al guardar: la regla no depende de la Page.
    if (_validarMedicion(nueva) != null) return;
    setState(() {
      _mediciones = [
        ..._mediciones,
        Medicion(
          indicador: nueva.indicador,
          sedeId: nueva.sedeId,
          periodo: nueva.periodo,
          valor: redondear1(valor),
          registradaPor: usuario.nombre,
          registradaEn: _datos.hoy,
        ),
      ];
      _registrarEvento(
        usuario: usuario,
        sedeId: _sedeSesion,
        accion: AccionAuditoria.registrar,
        recurso: RecursoAuditoria.medicionIndicador,
        resultado: ResultadoAuditoria.permitido,
      );
    });
  }

  /// Guarda la atención que llenó el médico: queda primera en la historia,
  /// con *Atención del paciente* le da relación con el paciente y deja su
  /// evento (F-04, F-05, F-20).
  void _guardarAtencion(NuevaAtencion nueva) {
    final registro = _registro;
    final usuario = _usuario;
    if (registro == null || usuario == null) return;
    final paciente = registro.paciente;
    final total = _atenciones.values.fold<int>(0, (a, l) => a + l.length);
    final atencion = Encounter(
      id: 'enc-n${total + 1}',
      type: nueva.tipo,
      status: EncounterStatus.finalizada,
      facilityName: _datos.sede(nueva.sedeId).nombreCorto,
      startDate: nueva.fecha,
      endDate: nueva.fecha,
      lengthOfStayDays: 0,
      doctorName: usuario.nombre,
      reason: nueva.motivo,
      diagnosis: nueva.diagnostico,
    );
    setState(() {
      _atenciones = {
        ..._atenciones,
        paciente.id: [atencion, ...?_atenciones[paciente.id]],
      };
      if (registro.proposito == Proposito.atencionPaciente &&
          !paciente.medicosConAtencion.contains(usuario.id)) {
        final actualizado = paciente.copyWith(
          medicosConAtencion: [...paciente.medicosConAtencion, usuario.id],
        );
        _pacientes = [
          for (final p in _pacientes) p.id == paciente.id ? actualizado : p,
        ];
      }
      _registrarEvento(
        usuario: usuario,
        sedeId: _sedeSesion,
        accion: AccionAuditoria.registrar,
        recurso: RecursoAuditoria.atencion,
        resultado: ResultadoAuditoria.permitido,
        paciente: paciente,
        proposito: registro.proposito,
      );
      _registro = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Atención registrada en la historia unificada'),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Datos para las Pages
  // ---------------------------------------------------------------------

  Map<String, String> get _nombresSedes => {
    for (final s in _datos.sedes) s.id: s.nombreCorto,
  };

  List<PacienteEnSeguimiento> get _altasRecientes =>
      pacientesConAltaReciente(_pacientes, _datos.hoy);

  bool get _busquedaActiva =>
      normalizarTexto(_busqueda).length >= minimoCaracteresBusqueda;

  /// Altas recientes con la búsqueda aplicada (por nombre o documento).
  /// Conserva el orden por riesgo de la lista; el criterio es el mismo de
  /// la búsqueda de pacientes (F-01).
  List<PacienteEnSeguimiento> get _pacientesBuscados => [
    for (final p in _altasRecientes)
      if (!_busquedaActiva || coincideBusqueda(p, _busqueda)) p,
  ];

  // ---------------------------------------------------------------------
  // Construcción
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => _raiz();

  /// Hay algo a lo que volver con Atrás: el paso de la sede, una pantalla de
  /// detalle o una declaración de propósito. Si no, Atrás sale de la app como
  /// siempre.
  bool get _atrasPendiente {
    if (_usuario == null) return _paso == PasoAcceso.sede;
    return _verPerfil ||
        _indicadorAbierto != null ||
        _datosBasicos != null ||
        _historia != null ||
        _registro != null ||
        _denegado != null ||
        _solicitud != null;
  }

  /// Las Pages se arman en `app_screen_paginas.dart`; cambian el estado
  /// solo a través de este método.
  void _actualizar(VoidCallback cambio) => setState(cambio);
}
