import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
part 'app_screen_guardado.dart';

/// Una declaración de propósito en curso. Sin paciente es la de la lista de
/// pacientes con alta reciente (F-06); con paciente, la de abrirlo o, si
/// [registrar], la de registrarle una atención (F-04).
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
    if (_falla('evento-ingreso')) {
      // Falla de red al registrar el ingreso (F-13 paso 5): no se abre la
      // sesión y se puede reintentar.
      setState(() => _errorSede = _mensajeFallaIngreso);
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
      // Lo escrito en las búsquedas no pasa al siguiente usuario (F-15).
      _busqueda = '';
      _busquedaPaciente = '';
      _seccion = Seccion.inicio;
      _correo.clear();
      _contrasena.clear();
      _mensajeError = null;
      _avisoInactividad = porInactividad ? mensajeInactividad : null;
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
    if (rolPermite(usuario.rol, accion)) return true;
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
      // La historia muestra también el riesgo de reingreso: es otro recurso
      // y deja su propio evento, permitido o denegado (F-07 pasos 3-4, A2).
      _registrarEvento(
        usuario: usuario,
        sedeId: _sedeSesion,
        accion: AccionAuditoria.consultar,
        recurso: RecursoAuditoria.riesgoReingreso,
        resultado: permitido
            ? ResultadoAuditoria.permitido
            : ResultadoAuditoria.denegado,
        paciente: paciente,
        proposito: elegido,
      );
      if (permitido) {
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
