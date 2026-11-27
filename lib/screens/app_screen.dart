import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/historia_simulada.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/models/sign_in_result.dart';
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
import 'package:red_vitalys/reglas/foto.dart';
import 'package:red_vitalys/reglas/indicadores.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/repositorios/auditoria_memoria.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';
import 'package:red_vitalys/repositorios/foto_memoria.dart';
import 'package:red_vitalys/repositorios/foto_repositorio.dart';
import 'package:red_vitalys/repositorios/selector_foto.dart';
import 'package:red_vitalys/screens/secciones.dart';
import 'package:red_vitalys/services/access_control_service.dart';
import 'package:red_vitalys/services/auth_memory.dart';
import 'package:red_vitalys/services/auth_service.dart';
import 'package:red_vitalys/services/history_memory.dart';
import 'package:red_vitalys/services/history_service.dart';
import 'package:red_vitalys/services/indicator_memory.dart';
import 'package:red_vitalys/services/indicator_service.dart';
import 'package:red_vitalys/services/patient_memory.dart';
import 'package:red_vitalys/services/patient_service.dart';
import 'package:red_vitalys/services/session_service.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/navegacion.dart';
import 'package:red_vitalys/widgets/proposito.dart';

part 'app_screen_paginas.dart';
part 'app_screen_guardado.dart';
part 'app_screen_foto.dart';

/// Una declaración de propósito en curso. Sin paciente es la de la lista de
/// pacientes con alta reciente (F-06); con paciente, la de abrirlo o, si
/// [registrar], la de registrarle una atención (F-04).
/// Lo que se decide al declarar el propósito: sus eventos, si el acceso se
/// permite y el cambio de pantalla que se hace cuando ya se guardaron.
typedef _PlanConsulta = ({
  List<EventoAuditoria> eventos,
  bool permitido,
  void Function() aplicar,
});

class _Solicitud {
  const _Solicitud({
    this.paciente,
    this.elegido,
    this.error,
    this.registrar = false,
    this.reintentable = false,
  });

  final PacienteEnSeguimiento? paciente;
  final Proposito? elegido;
  final String? error;
  final bool registrar;

  /// El error es de red (verificar o registrar el acceso): el pop-up ofrece
  /// *Reintentar* (F-05, F-18, F-20).
  final bool reintentable;
}

// Mensajes de las fallas simuladas (specs F-04, F-05, F-12, F-13, F-20, F-23).
const _mensajeFallaIngreso = 'No se pudo iniciar sesión. Intente de nuevo.';
const _mensajeFallaVerificar = 'No se pudo verificar el acceso';
const _mensajeFallaAccion = 'No se pudo completar la acción';
const _mensajeFallaAtencion = 'No se pudo registrar la atención';
const _mensajeFallaMedicion = 'No se pudo registrar la medición';
const _mensajeFallaCierre = 'No se pudo cerrar la sesión. Intente de nuevo.';
const _duracionCierreSimulado = Duration(milliseconds: 400);

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
  const AppScreen({
    super.key,
    required this.datos,
    this.reloj = DateTime.now,
    this.auditoria,
    this.auth,
    this.patients,
    this.history,
    this.indicators,
    this.fotos,
    this.selectorFoto,
  });

  final DatosSimulados datos;

  /// Dónde se guarda la foto de perfil. Sin él, en memoria (P-02).
  final FotoPerfilRepositorio? fotos;

  /// Cómo se elige la foto en el dispositivo. Sin él, el selector real.
  final SelectorFoto? selectorFoto;

  /// Dónde se guardan los eventos de auditoría. Sin él, en memoria (P-01).
  final AuditoriaRepositorio? auditoria;

  /// Cómo se inicia y se cierra la sesión. Sin él, los usuarios simulados.
  final AuthService? auth;

  /// De dónde salen los pacientes. Sin él, los simulados.
  final PatientService? patients;

  /// De dónde sale la historia clínica. Sin él, la simulada.
  final HistoryService? history;

  /// De dónde salen las mediciones. Sin él, las simuladas.
  final IndicatorService? indicators;

  /// Hora real del dispositivo, para el bloqueo de 15 minutos (F-14).
  final DateTime Function() reloj;

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  DatosSimulados get _datos => widget.datos;

  late final AuthService _auth = widget.auth ?? AuthMemory(widget.datos);

  final _access = const AccessControlService();

  late final HistoryService _histories =
      widget.history ?? const HistoryMemory();

  // La historia traída de Supabase para la consulta abierta.
  Patient? _historiaRemota;
  bool _cargandoHistoria = false;
  bool _errorHistoria = false;
  // Cambia con cada pedido de la historia: solo se aplica la respuesta del
  // último (T-04).
  int _pedidoHistoria = 0;

  late final PatientService _patients =
      widget.patients ?? PatientMemory(widget.datos);

  // Sesión (F-13, F-15, F-23).
  Usuario? _usuario;
  String? _sedeSesion;

  // El Navigator interno: el botón Atrás del sistema le llega por aquí.
  final _navegador = GlobalKey<NavigatorState>();

  // Inicio de sesión.
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  PasoAcceso _paso = PasoAcceso.credenciales;
  Usuario? _usuarioValidado;
  bool _ingresando = false;
  String? _mensajeError;
  String? _avisoInactividad;
  String? _sedeElegida;
  String? _errorSede;

  // Bloqueo del dispositivo (F-14) e inactividad (F-15).
  final _session = SessionService();

  // Navegación y consultas.
  Seccion _seccion = Seccion.inicio;
  bool _listaDeclarada = false;

  /// La sección en la que estaba antes de que se pidiera el propósito de la
  /// lista: a ella vuelve *Cancelar* (F-16 A2).
  Seccion? _seccionPrevia;
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

  /// Interruptor de demo del acceso: con él, cada pantalla muestra su
  /// "Cargando…" y su error con *Reintentar*, y las acciones fallan la
  /// primera vez (estados de carga y error de las specs).
  bool _simularFallas = false;

  /// Las acciones que ya fallaron una vez con [_simularFallas]: la siguiente
  /// funciona.
  final Set<String> _fallasHechas = {};

  // Cierre de sesión en curso o fallido (F-23, solo en modo demo).
  bool _cerrandoSesion = false;
  String? _errorCierre;

  // Pacientes y atenciones registradas en esta sesión. Viven aquí, en la
  // Screen anfitriona; las Pages solo las muestran.
  late List<PacienteEnSeguimiento> _pacientes = _patients.isRemote
      ? []
      : [..._datos.pacientes];
  Map<String, List<Encounter>> _atenciones = {};

  // Mediciones de los indicadores. Las que registra el administrativo se
  // agregan aquí y el tablero se recalcula (F-12).
  late final IndicatorService _indicators =
      widget.indicators ?? IndicatorMemory(widget.datos);
  late List<Medicion> _mediciones = _indicators.isRemote
      ? []
      : [..._datos.mediciones];
  bool _cargandoMediciones = false;
  bool _errorMediciones = false;

  // Filtros de Pacientes en seguimiento.
  String _busqueda = '';

  // Auditoría de accesos (F-20, F-21). Los eventos solo se agregan con
  // [_registrarEvento]: nunca se editan ni se borran (AD-08).
  late final AuditoriaRepositorio _auditoria =
      widget.auditoria ?? AuditoriaMemoria(_datos.eventos);
  // Con Supabase la lista sale de la base al abrir la auditoría; en memoria
  // arranca con los eventos simulados.
  late final List<EventoAuditoria> _eventos = _auditoria.esRemoto
      ? []
      : [..._datos.eventos];
  bool _cargandoEventos = false;
  bool _cargandoPacientes = false;
  bool _errorPacientes = false;
  bool _errorEventos = false;
  bool _confirmandoSede = false;
  // Cambia al abrir y al cerrar cada sesión: una carga pedida en otra sesión
  // no se aplica a la siguiente.
  int _sesion = 0;
  bool _confirmandoProposito = false;
  FiltroAuditoria _filtroAuditoria = FiltroAuditoria.todos;

  // Foto de perfil (F-22).
  late final FotoPerfilRepositorio _fotos = widget.fotos ?? FotoMemoria();
  late final SelectorFoto _selectorFoto =
      widget.selectorFoto ?? SelectorFotoDispositivo();
  Uint8List? _foto;
  bool _cargandoFoto = false;
  bool _errorFoto = false;
  bool _guardandoFoto = false;
  String? _avisoFoto;

  @override
  void initState() {
    super.initState();
    // Cualquier tecla cuenta como uso, tenga o no el foco la app (F-15).
    HardwareKeyboard.instance.addHandler(_teclaPulsada);
  }

  bool _teclaPulsada(KeyEvent _) {
    _registrarActividad();
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_teclaPulsada);
    _session.stop();
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Inicio y cierre de sesión
  // ---------------------------------------------------------------------

  bool get _bloqueado => _session.isLocked(widget.reloj());

  Future<void> _ingresar() async {
    if (_ingresando) return;
    // Se valida con lo que había al pulsar Ingresar; después del await no se
    // vuelve a leer el campo.
    final correoEscrito = _correo.text.trim();
    final contrasenaEscrita = _contrasena.text;
    if (correoEscrito.isEmpty || contrasenaEscrita.isEmpty) {
      setState(() {
        _mensajeError = mensajeCamposVacios;
        _avisoInactividad = null;
      });
      return;
    }

    setState(() {
      _ingresando = true;
      _avisoInactividad = null;
    });
    if (!_auth.isRemote) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
    }

    if (_falla('ingresar')) {
      // Falla de red (F-13): se conserva el correo, se borra la contraseña y
      // no cuenta para el bloqueo ni crea evento.
      setState(() {
        _ingresando = false;
        _contrasena.clear();
        _mensajeError = _mensajeFallaIngreso;
      });
      return;
    }

    var resultado = ResultadoIngreso.bloqueado;
    Usuario? usuarioEscrito;
    if (!_bloqueado) {
      final respuesta = await _auth.signIn(correoEscrito, contrasenaEscrita);
      if (!mounted) return;
      if (respuesta.status == SignInStatus.networkError) {
        setState(() {
          _ingresando = false;
          _contrasena.clear();
          _mensajeError = _mensajeFallaIngreso;
        });
        return;
      }
      resultado = switch (respuesta.status) {
        SignInStatus.success => ResultadoIngreso.valido,
        SignInStatus.noSites => ResultadoIngreso.sinSedes,
        _ => ResultadoIngreso.datosIncorrectos,
      };
      usuarioEscrito = respuesta.user;
    }

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
        _contrasena.clear();
        _mensajeError = _session.registerFailure(widget.reloj())
            ? mensajeBloqueo
            : resultado.mensaje;
        return;
      }
      if (resultado != ResultadoIngreso.valido) {
        _mensajeError = resultado.mensaje;
        return;
      }
      final usuario = usuarioEscrito;
      if (usuario == null) return;
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
  Future<void> _confirmarSede() async {
    if (_confirmandoSede) return;
    final usuario = _usuarioValidado;
    final sede = _sedeElegida;
    if (usuario == null) return;
    if (sede == null || !usuario.sedesAsignadas.contains(sede)) {
      setState(() => _errorSede = mensajeElijaSede);
      return;
    }
    if (_falla('evento-ingreso')) {
      // Falla de red al registrar el ingreso (F-13 paso 5): no se abre la
      // sesión y se puede reintentar.
      setState(() => _errorSede = _mensajeFallaIngreso);
      return;
    }
    // El ingreso se registra al confirmar la sede, antes de abrir la
    // sesión, porque lleva la sede (F-13 paso 5, F-20 A3). Si no se puede
    // guardar, la sesión no se abre (AD-07).
    final evento = _armarEvento(
      usuario: usuario,
      sedeId: sede,
      accion: AccionAuditoria.ingresar,
      recurso: RecursoAuditoria.sesion,
      resultado: ResultadoAuditoria.permitido,
    );
    if (_auditoria.esRemoto) {
      _confirmandoSede = true;
      try {
        await _auditoria.agregar(evento);
      } catch (error) {
        debugPrint('No se pudo guardar el evento de ingreso: $error');
        if (!mounted) return;
        setState(() => _errorSede = _mensajeFallaIngreso);
        return;
      } finally {
        _confirmandoSede = false;
      }
      if (!mounted) return;
    }
    setState(() {
      _sesion++;
      _eventos.add(evento);
      _session.registerSuccess();
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
    _session.startInactivityTimer(() => _cerrarSesion(porInactividad: true));
    _cargarEventosSiHaceFalta();
    unawaited(_cargarPacientes());
    unawaited(_cargarMediciones());
  }

  Future<void> _cargarHistoria() async {
    final paciente = (_historia ?? _datosBasicos)?.paciente;
    if (!_histories.isRemote || paciente == null) return;
    final pedido = ++_pedidoHistoria;
    final sesion = _sesion;
    setState(() {
      _historiaRemota = null;
      _cargandoHistoria = true;
      _errorHistoria = false;
    });
    // Si mientras tanto se cerró la consulta, se abrió otra, se pidió de nuevo
    // o cambió la sesión, la respuesta ya no sirve.
    bool sigueAbierta() =>
        mounted &&
        pedido == _pedidoHistoria &&
        sesion == _sesion &&
        (_historia ?? _datosBasicos)?.paciente.id == paciente.id;
    try {
      final historia = await _histories.historyOf(
        paciente,
        siteName: _nombresSedes[paciente.sedeAltaId] ?? '',
        today: _datos.hoy,
      );
      if (!sigueAbierta()) return;
      setState(() {
        _historiaRemota = historia;
        _cargandoHistoria = false;
        _errorHistoria = false;
      });
    } catch (error) {
      debugPrint('No se pudo cargar la historia: $error');
      if (!sigueAbierta()) return;
      setState(() {
        _cargandoHistoria = false;
        _errorHistoria = true;
      });
    }
  }

  Future<void> _cargarMediciones() async {
    if (!_indicators.isRemote || _cargandoMediciones) return;
    setState(() {
      _cargandoMediciones = true;
      _errorMediciones = false;
    });
    final sesion = _sesion;
    try {
      final loaded = await _indicators.listMeasurements();
      if (!mounted || sesion != _sesion) return;
      setState(() {
        _mediciones = loaded;
        _cargandoMediciones = false;
      });
    } catch (error) {
      debugPrint('No se pudieron cargar las mediciones: $error');
      if (!mounted || sesion != _sesion) return;
      setState(() {
        _cargandoMediciones = false;
        _errorMediciones = true;
      });
    }
  }

  Future<void> _cargarPacientes() async {
    if (!_patients.isRemote || _cargandoPacientes) return;
    setState(() {
      _cargandoPacientes = true;
      _errorPacientes = false;
    });
    final sesion = _sesion;
    try {
      final loaded = await _patients.listPatients(_datos.hoy);
      if (!mounted || sesion != _sesion) return;
      setState(() {
        _pacientes = loaded;
        _cargandoPacientes = false;
      });
    } catch (error) {
      debugPrint('No se pudieron cargar los pacientes: $error');
      if (!mounted || sesion != _sesion) return;
      setState(() {
        _cargandoPacientes = false;
        _errorPacientes = true;
      });
    }
  }

  /// Cierra la sesión de Auth sin esperar; si falla, solo avisa en consola.
  void _cerrarSesionDeAuth() {
    unawaited(
      _auth.signOut().catchError((Object error) {
        debugPrint('No se pudo cerrar la sesión de Auth: $error');
      }),
    );
  }

  /// El usuario sale sin confirmar la sede: no se abre la sesión (F-13 A6).
  void _volverACredenciales() {
    if (_confirmandoSede) return;
    _cerrarSesionDeAuth();
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
    _session.stop();
    _cerrarSesionDeAuth();
    setState(() {
      _cerrandoSesion = false;
      _errorCierre = null;
      _usuario = null;
      _usuarioValidado = null;
      _paso = PasoAcceso.credenciales;
      _sedeElegida = null;
      _sedeSesion = null;
      _solicitud = null;
      _cerrarDetalles();
      _listaDeclarada = false;
      _seccionPrevia = null;
      _filtroAuditoria = FiltroAuditoria.todos;
      // La foto es de quien tenía la sesión: no pasa al siguiente usuario.
      _foto = null;
      _errorFoto = false;
      _avisoFoto = null;
      // Lo escrito en las búsquedas no pasa al siguiente usuario (F-15).
      _busqueda = '';
      _busquedaPaciente = '';
      _seccion = Seccion.inicio;
      _correo.clear();
      _contrasena.clear();
      _mensajeError = null;
      _avisoInactividad = porInactividad ? mensajeInactividad : null;
      // Lo traído de la base es de quien tenía la sesión: el siguiente
      // usuario lo vuelve a pedir con sus permisos.
      _sesion++;
      if (_patients.isRemote) _pacientes = [];
      if (_indicators.isRemote) _mediciones = [];
      _cargandoPacientes = false;
      _errorPacientes = false;
      _cargandoMediciones = false;
      _errorMediciones = false;
    });
  }

  /// *Cerrar sesión* a mano (F-23). En modo demo espera "Cerrando sesión…" y
  /// puede fallar una vez; el usuario sigue en el perfil. Sin el modo, cierra
  /// al instante.
  Future<void> _pedirCierreDeSesion() async {
    if (!_simularFallas) {
      _cerrarSesion();
      return;
    }
    if (_cerrandoSesion) return;
    setState(() {
      _cerrandoSesion = true;
      _errorCierre = null;
      _verPerfil = true;
    });
    await Future<void>.delayed(_duracionCierreSimulado);
    if (!mounted || _usuario == null) return;
    if (_falla('cerrar-sesion')) {
      setState(() {
        _cerrandoSesion = false;
        _errorCierre = _mensajeFallaCierre;
      });
      return;
    }
    _fallasHechas.clear();
    _cerrarSesion();
  }

  void _registrarActividad() {
    if (_usuario == null) return;
    _session.registerActivity();
  }

  /// Agrega un evento de acceso con la hora de los datos simulados, la
  /// misma que el diálogo muestra en *Quedará registrado* (F-20). Es la
  /// única forma de cambiar [_eventos], y solo agrega. Llamar dentro de
  /// `setState`.
  ///
  /// Con Supabase, además lo guarda en la base sin esperar. Hasta que cada
  /// acción pase a Supabase, solo el ingreso espera el resultado (P-01).
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
    final evento = _armarEvento(
      accion: accion,
      recurso: recurso,
      resultado: resultado,
      usuario: usuario,
      sedeId: sedeId,
      correoIntento: correoIntento,
      paciente: paciente,
      proposito: proposito,
      ip: ip,
    );
    _anotarEvento(evento, enviar: true);
  }

  /// Qué eventos deja declarar [elegido] para la solicitud [s], si el acceso
  /// se permite y qué se muestra después (F-02, F-03, F-04, F-06, F-18).
  /// Registrar una atención permitida no deja evento aquí: lo deja al
  /// guardarla.
  _PlanConsulta _planDeConsulta(
    Usuario usuario,
    _Solicitud s,
    Proposito elegido,
  ) {
    EventoAuditoria evento(
      AccionAuditoria accion,
      RecursoAuditoria recurso,
      bool permitido, {
      PacienteEnSeguimiento? paciente,
    }) => _armarEvento(
      usuario: usuario,
      sedeId: _sedeSesion,
      accion: accion,
      recurso: recurso,
      resultado: permitido
          ? ResultadoAuditoria.permitido
          : ResultadoAuditoria.denegado,
      paciente: paciente,
      proposito: elegido,
    );

    final paciente = s.paciente;
    if (paciente == null) {
      // La lista de pacientes con alta reciente (F-06 paso 3), con el
      // propósito validado por la matriz única (F-16, AD-06).
      final permitida =
          _access.decidePurpose(usuario, elegido) ==
          ResultadoConsulta.permitido;
      return (
        eventos: [
          evento(
            AccionAuditoria.consultar,
            RecursoAuditoria.pacientesAltaReciente,
            permitida,
          ),
        ],
        permitido: permitida,
        aplicar: () {
          _listaDeclarada = permitida;
          if (!permitida) _irA(Seccion.indicadores);
        },
      );
    }
    final resultado = _access.decideConsultation(
      user: usuario,
      patient: paciente,
      purpose: elegido,
      today: _datos.hoy,
      registering: s.registrar,
    );
    final permitido = resultado == ResultadoConsulta.permitido;
    void denegar({required bool alRegistrar}) => _denegado = (
      paciente: paciente,
      resultado: resultado,
      alRegistrar: alRegistrar,
    );
    if (usuario.rol == Rol.administrativo && !s.registrar) {
      // El administrativo no ve la historia: solo los datos básicos (F-03).
      return (
        eventos: [
          evento(
            AccionAuditoria.consultar,
            RecursoAuditoria.datosBasicos,
            permitido,
            paciente: paciente,
          ),
        ],
        permitido: permitido,
        aplicar: () => permitido
            ? _datosBasicos = (paciente: paciente, proposito: elegido)
            : denegar(alRegistrar: false),
      );
    }
    if (s.registrar) {
      return (
        eventos: [
          if (!permitido)
            evento(
              AccionAuditoria.registrar,
              RecursoAuditoria.atencion,
              false,
              paciente: paciente,
            ),
        ],
        permitido: permitido,
        aplicar: () => permitido
            ? _registro = (paciente: paciente, proposito: elegido)
            : denegar(alRegistrar: true),
      );
    }
    // La historia muestra también el riesgo: dos eventos, permitidos o
    // denegados (F-02 paso 4, F-07). Con *Urgencia* permitida van al filtro
    // Emergencia (F-17).
    return (
      eventos: [
        evento(
          AccionAuditoria.consultar,
          RecursoAuditoria.historiaClinica,
          permitido,
          paciente: paciente,
        ),
        evento(
          AccionAuditoria.consultar,
          RecursoAuditoria.riesgoReingreso,
          permitido,
          paciente: paciente,
        ),
      ],
      permitido: permitido,
      aplicar: () => permitido
          ? _historia = (paciente: paciente, proposito: elegido)
          : denegar(alRegistrar: false),
    );
  }

  /// Guarda en Supabase los eventos que dan acceso a algo y espera la
  /// respuesta: si no se guardan, la acción no se hace (F-20, AD-07).
  Future<bool> _guardarEventosAntes(List<EventoAuditoria> eventos) async {
    if (!_auditoria.esRemoto) return true;
    try {
      for (final evento in eventos) {
        await _auditoria.agregar(evento);
      }
      return true;
    } catch (error) {
      debugPrint('No se pudo guardar el evento: $error');
      return false;
    }
  }

  /// Deja [evento] en la lista de la sesión y, con [enviar], lo manda a
  /// Supabase sin esperar (los rechazos no muestran nada que proteger).
  /// Llamar dentro de `setState`.
  void _anotarEvento(EventoAuditoria evento, {required bool enviar}) {
    _eventos.add(evento);
    if (!enviar || !_auditoria.esRemoto) return;
    unawaited(
      _auditoria.agregar(evento).catchError((Object error) {
        debugPrint('No se pudo guardar el evento: $error');
      }),
    );
  }

  EventoAuditoria _armarEvento({
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
    return EventoAuditoria(
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
    );
  }

  /// Con Supabase, trae los eventos de la base cuando se abre la auditoría.
  /// En memoria no hace nada: la lista ya está al día (F-21).
  Future<void> _cargarEventosSiHaceFalta() async {
    if (!_auditoria.esRemoto || _seccion != Seccion.auditoria) return;
    setState(() {
      _cargandoEventos = true;
      _errorEventos = false;
    });
    try {
      final eventos = await _auditoria.listar();
      if (!mounted) return;
      setState(() {
        _eventos
          ..clear()
          ..addAll(eventos);
        _cargandoEventos = false;
      });
    } catch (error) {
      debugPrint('No se pudieron cargar los eventos: $error');
      if (!mounted) return;
      setState(() {
        _cargandoEventos = false;
        _errorEventos = true;
      });
    }
  }

  /// Con [_simularFallas], la acción [clave] falla la primera vez y funciona
  /// al reintentar. Sin él, nunca falla.
  bool _falla(String clave) => _simularFallas && _fallasHechas.add(clave);

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
    if (seccion.muestraPacientes &&
        !_listaDeclarada &&
        !_seccion.muestraPacientes) {
      _seccionPrevia = _seccion;
    }
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
    if (_usuario == null) return;
    if (!intentarAcceso(accionDeSeccion(seccion), recursoDeSeccion(seccion))) {
      return;
    }
    setState(() => _irA(seccion));
    _cargarEventosSiHaceFalta();
  }

  /// La consulta de [paciente] con [proposito] tal como la recibe el sistema,
  /// aunque la pantalla no ofrezca ese propósito al rol (F-16 CA-7, F-18
  /// CA-5): pasa por la misma decisión y deja su evento.
  @visibleForTesting
  Future<void> consultarConProposito(
    PacienteEnSeguimiento paciente,
    Proposito proposito,
  ) {
    setState(
      () => _solicitud = _Solicitud(paciente: paciente, elegido: proposito),
    );
    return _confirmarProposito();
  }

  /// La puerta del sistema para lo que el rol no tiene en la tabla de F-18:
  /// si el rol lo permite no hace nada y devuelve `true`; si no, registra el
  /// evento *Denegado* (F-20), avisa con [rechazoRol] y devuelve `false`.
  /// Las pantallas no ofrecen esas acciones; esta es la guarda por si se
  /// llega por otro camino.
  @visibleForTesting
  bool intentarAcceso(
    AccionPermitida accion,
    RecursoAuditoria recurso, {
    PacienteEnSeguimiento? paciente,
    Proposito? proposito,
  }) {
    final usuario = _usuario;
    if (usuario == null) return false;
    if (_access.canDo(usuario.rol, accion)) return true;
    final registra =
        accion == AccionPermitida.registrarAtencion ||
        accion == AccionPermitida.registrarMedicion;
    setState(() {
      _registrarEvento(
        usuario: usuario,
        sedeId: _sedeSesion,
        accion: registra
            ? AccionAuditoria.registrar
            : AccionAuditoria.consultar,
        recurso: recurso,
        resultado: ResultadoAuditoria.denegado,
        paciente: paciente,
        proposito: proposito,
      );
    });
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text(rechazoRol)));
    return false;
  }

  void _verPacientes() => _elegirSeccion(Seccion.pacientes);

  void _abrirPaciente(PacienteEnSeguimiento p) {
    // El propósito no se hereda: arranca sin elegir (F-16 CA-4).
    setState(() => _solicitud = _Solicitud(paciente: p));
  }

  /// El médico elige *Registrar atención* en la historia: antes declara el
  /// propósito (F-04, F-16).
  void _pedirRegistro(PacienteEnSeguimiento p) {
    if (_usuario == null) return;
    if (!intentarAcceso(
      AccionPermitida.registrarAtencion,
      RecursoAuditoria.atencion,
      paciente: p,
    )) {
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

  Future<void> _confirmarProposito() async {
    if (_confirmandoProposito) return;
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
    if (paciente != null) {
      // Fallas de red al verificar el acceso y al registrar el evento (F-05,
      // F-18, F-20). Registrar una atención deja su evento al guardar.
      final falla = _falla('verificar-${paciente.id}')
          ? _mensajeFallaVerificar
          : (!s.registrar && _falla('evento-${paciente.id}')
                ? _mensajeFallaAccion
                : null);
      if (falla != null) {
        setState(() {
          _solicitud = _Solicitud(
            paciente: paciente,
            elegido: elegido,
            error: falla,
            registrar: s.registrar,
            reintentable: true,
          );
        });
        return;
      }
    }
    final plan = _planDeConsulta(usuario, s, elegido);
    _confirmandoProposito = true;
    final guardados = await _guardarEventosAntes(
      plan.permitido ? plan.eventos : const [],
    );
    _confirmandoProposito = false;
    // Si mientras tanto se canceló el pop-up o se cerró la sesión, no se
    // muestra nada.
    if (!mounted || _solicitud != s || _usuario != usuario) return;
    if (!guardados) {
      // Sin evento no se muestra la información (F-20, AD-07).
      setState(() {
        _solicitud = _Solicitud(
          paciente: paciente,
          elegido: elegido,
          error: _mensajeFallaAccion,
          registrar: s.registrar,
          reintentable: true,
        );
      });
      return;
    }
    setState(() {
      _solicitud = null;
      for (final evento in plan.eventos) {
        _anotarEvento(evento, enviar: !plan.permitido);
      }
      plan.aplicar();
    });
    if (s.paciente != null &&
        !s.registrar &&
        (_historia != null || _datosBasicos != null)) {
      unawaited(_cargarHistoria());
    }
  }

  /// Cancelar no consulta nada (F-16 A2). Si era la lista, el médico queda
  /// en Indicadores, que no muestra pacientes.
  void _cancelarProposito() {
    final s = _solicitud;
    if (s == null) return;
    setState(() {
      _solicitud = null;
      if (s.paciente == null) {
        // Vuelve a donde estaba; recién iniciada la sesión, al tablero
        // (F-16 A2, CA-9).
        final previa = _seccionPrevia ?? Seccion.indicadores;
        _seccionPrevia = null;
        _irA(previa);
      }
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
    _historiaRemota = null;
    _cargandoHistoria = false;
    _errorHistoria = false;
    _pedidoHistoria++;
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
