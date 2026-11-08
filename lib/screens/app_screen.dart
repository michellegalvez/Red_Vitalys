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

/// Un paciente abierto, con el propósito declarado.
typedef _Historia = ({PacienteEnSeguimiento paciente, Proposito proposito});

/// Los datos básicos de un paciente que abrió el administrativo (F-03).
typedef _DatosBasicos = ({PacienteEnSeguimiento paciente, Proposito proposito});

/// Un registro de atención en curso, con el propósito declarado.
typedef _Registro = ({PacienteEnSeguimiento paciente, Proposito proposito});

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
  _Historia? _historia;
  _Registro? _registro;
  _Denegado? _denegado;
  bool _verPerfil = false;
  IdIndicador? _indicadorAbierto;
  _DatosBasicos? _datosBasicos;

  /// La sede de la tendencia en el detalle de un indicador. `null` es *Toda
  /// la red* (F-09).
  String? _sedeTendencia;
  String _busquedaPaciente = '';

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
          resultado == ResultadoIngreso.bloqueado) {
        // Inicio de sesión fallido o intento durante el bloqueo (F-14 A3,
        // F-20 A4): con el correo escrito, la IP y sin sede.
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

  void _elegirSeccion(Seccion seccion) => setState(() => _irA(seccion));

  void _verPacientes() => _elegirSeccion(Seccion.pacientes);

  void _abrirPaciente(PacienteEnSeguimiento p, {Proposito? elegido}) {
    // El propósito no se hereda: arranca sin elegir (F-16 CA-4).
    setState(() => _solicitud = _Solicitud(paciente: p, elegido: elegido));
  }

  /// El médico elige *Registrar atención* en la historia: antes declara el
  /// propósito (F-04, F-16).
  void _pedirRegistro(PacienteEnSeguimiento p, {Proposito? elegido}) {
    setState(() {
      _solicitud = _Solicitud(paciente: p, elegido: elegido, registrar: true);
    });
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
      final resultado = evaluarConsulta(
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
    if (d.alRegistrar) {
      _pedirRegistro(d.paciente, elegido: Proposito.urgencia);
    } else {
      _abrirPaciente(d.paciente, elegido: Proposito.urgencia);
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
  List<PacienteEnSeguimiento> get _pacientesBuscados {
    final texto = normalizarTexto(_busqueda);
    return [
      for (final p in _altasRecientes)
        if (!_busquedaActiva ||
            normalizarTexto(p.nombre).contains(texto) ||
            p.numeroDocumento.contains(texto))
          p,
    ];
  }

  // ---------------------------------------------------------------------
  // Construcción
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    final solicitud = _solicitud;
    // Registrar una atención se pide desde la historia, que está apilada
    // encima de la pantalla raíz: su pop-up tiene que dibujarse por encima de
    // todas las pantallas para verse.
    final dialogoArriba =
        usuario != null && solicitud != null && solicitud.registrar;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, _) {
        _registrarActividad();
        return KeyEventResult.ignored;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _registrarActividad(),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                excluding: dialogoArriba,
                child: ExcludeFocus(
                  excluding: dialogoArriba,
                  child: NavigatorPopHandler(
                    enabled: _atrasPendiente,
                    // Atrás cierra primero el pop-up de propósito que esté abierto y,
                    // si no hay, la pantalla de arriba.
                    onPopWithResult: (_) {
                      if (_solicitud != null) {
                        _cancelarProposito();
                      } else {
                        _navegador.currentState?.maybePop();
                      }
                    },
                    child: Navigator(
                      key: _navegador,
                      pages: [
                        if (usuario == null)
                          MaterialPage<void>(
                            key: const ValueKey('acceso'),
                            child: _acceso(),
                          )
                        else ...[
                          MaterialPage<void>(
                            key: const ValueKey('app'),
                            child: _aplicacion(usuario),
                          ),
                          if (_indicadorAbierto case final indicador?)
                            MaterialPage<void>(
                              key: const ValueKey('indicador'),
                              child: _detalleIndicador(usuario, indicador),
                            ),
                          if (_datosBasicos case final datos?)
                            MaterialPage<void>(
                              key: ValueKey('datos-${datos.paciente.id}'),
                              child: _paginaDatosBasicos(usuario, datos),
                            ),
                          if (_historia case final historia?)
                            MaterialPage<void>(
                              key: ValueKey('historia-${historia.paciente.id}'),
                              child: _paginaHistoria(usuario, historia),
                            ),
                          if (_registro case final registro?)
                            MaterialPage<void>(
                              key: ValueKey('registro-${registro.paciente.id}'),
                              child: _paginaRegistro(usuario, registro),
                            ),
                          if (_denegado case final denegado?)
                            MaterialPage<void>(
                              key: ValueKey('denegado-${denegado.paciente.id}'),
                              child: ConsultaPage(
                                resultado: denegado.resultado,
                                onVolver: _cerrarDenegado,
                                onDeclararUrgencia: _declararUrgencia,
                              ),
                            ),
                          if (_verPerfil)
                            MaterialPage<void>(
                              key: const ValueKey('perfil'),
                              child: _perfil(),
                            ),
                        ],
                      ],
                      onDidRemovePage: (page) {
                        final clave = page.key;
                        if (clave is! ValueKey<String>) return;
                        final id = clave.value;
                        if (id.startsWith('historia')) {
                          _cerrarHistoria();
                        } else if (id.startsWith('datos')) {
                          setState(() => _datosBasicos = null);
                        } else if (id.startsWith('registro')) {
                          setState(() => _registro = null);
                        } else if (id.startsWith('denegado')) {
                          _cerrarDenegado();
                        } else if (id == 'indicador') {
                          setState(() {
                            _indicadorAbierto = null;
                            _sedeTendencia = null;
                          });
                        } else if (id == 'perfil') {
                          setState(() => _verPerfil = false);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (dialogoArriba) ...[
              const Positioned.fill(child: FondoDialogo()),
              Positioned.fill(child: _dialogo(usuario, solicitud)),
            ],
          ],
        ),
      ),
    );
  }

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

  Widget _acceso() {
    final validado = _usuarioValidado;
    return PopScope(
      canPop: _paso == PasoAcceso.credenciales,
      onPopInvokedWithResult: (hizoPop, _) {
        if (!hizoPop) _volverACredenciales();
      },
      child: AccesoPage(
        paso: _paso,
        correo: _correo,
        contrasena: _contrasena,
        mostrarContrasena: _mostrarContrasena,
        ingresando: _ingresando,
        mensajeError: _mensajeError,
        avisoInactividad: _avisoInactividad,
        contrasenaPrototipo: _datos.contrasenaPrototipo,
        perfiles: [
          for (final u in _datos.usuarios)
            (
              etiqueta: u.sedesAsignadas.isEmpty ? 'Sin sedes' : u.rol.nombre,
              correo: u.correo,
            ),
        ],
        usuario: validado,
        sedes: [
          if (validado != null)
            for (final id in validado.sedesAsignadas) _datos.sede(id),
        ],
        sedeElegida: _sedeElegida,
        errorSede: _errorSede,
        onAlternarContrasena: () =>
            setState(() => _mostrarContrasena = !_mostrarContrasena),
        onIngresar: _ingresar,
        onElegirPerfil: _rellenarPerfil,
        onElegirSede: (id) => setState(() {
          _sedeElegida = id;
          _errorSede = null;
        }),
        onConfirmarSede: _confirmarSede,
        onVolver: _volverACredenciales,
      ),
    );
  }

  Widget _aplicacion(Usuario usuario) {
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    final secciones = seccionesDe(usuario.rol);
    final sede = _datos.sede(_sedeSesion ?? usuario.sedesAsignadas.first);
    final solicitud = _solicitud;
    // El pop-up de registrar una atención lo dibuja `build`, por encima de
    // todas las pantallas.
    final enRaiz = solicitud != null && !solicitud.registrar;

    return PopScope(
      canPop: solicitud == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelarProposito();
      },
      child: solicitud != null && solicitud.paciente == null
          ? _propositoLista(usuario, sede, solicitud)
          : Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    excluding: enRaiz,
                    child: ExcludeFocus(
                      excluding: enRaiz,
                      child: _marco(
                        usuario: usuario,
                        sede: sede,
                        escritorio: escritorio,
                        onDestino: (i) => _elegirSeccion(secciones[i]),
                        body: _contenido(usuario, sede),
                      ),
                    ),
                  ),
                ),
                // El pop-up de un paciente desenfoca toda la pantalla.
                if (enRaiz) ...[
                  const Positioned.fill(child: FondoDialogo()),
                  Positioned.fill(child: _dialogo(usuario, solicitud)),
                ],
              ],
            ),
    );
  }

  /// La app con su barra superior y, en celular, la barra inferior. La
  /// usan las secciones y el perfil (F-22), que se ve con las mismas barras.
  Widget _marco({
    required Usuario usuario,
    required Sede sede,
    required bool escritorio,
    required ValueChanged<int> onDestino,
    required Widget body,
  }) {
    final secciones = seccionesDe(usuario.rol);
    final indice = secciones.indexOf(_seccion).clamp(0, secciones.length - 1);
    final destinos = [for (final s in secciones) s.destino];
    return Scaffold(
      appBar: BarraSuperior(
        iniciales: usuario.iniciales,
        nombreUsuario: usuario.nombre,
        sede: sede.nombreCorto,
        detalleUsuario: '${usuario.rol.nombre} · ${sede.nombreCorto}',
        destinos: destinos,
        indiceActual: indice,
        onDestino: onDestino,
        onPerfil: () => setState(() => _verPerfil = true),
        onSalir: _cerrarSesion,
      ),
      bottomNavigationBar: escritorio
          ? null
          : BarraInferior(
              destinos: destinos,
              indiceActual: indice,
              onDestino: onDestino,
            ),
      body: body,
    );
  }

  Widget _contenido(Usuario usuario, Sede sede) {
    if (_seccion.muestraPacientes && !_listaDeclarada) {
      // Detrás del diálogo no se ve ningún paciente.
      return const SizedBox.shrink();
    }
    return switch (_seccion) {
      Seccion.inicio => _inicio(usuario, sede),
      Seccion.pacientes => _seguimiento(),
      Seccion.indicadores => _tablero(),
      Seccion.buscar => _buscar(usuario),
      Seccion.mediciones => _registrarMedicion(),
      Seccion.auditoria => _auditoria(),
    };
  }

  Widget _inicio(Usuario usuario, Sede sede) {
    final altas = _altasRecientes;
    final conAlertaLista = [
      for (final p in altas)
        if (conAlerta(p.riesgo)) p,
    ];
    return InicioPage(
      fecha: formatoFechaHora(_datos.hoy),
      saludo: '${saludoSegunHora(_datos.hoy)}, ${usuario.saludo}',
      totalConAlerta: conAlertaLista.length,
      totalEnSeguimiento: altas.length,
      indicadoresQueEmpeoraron: indicadoresQueEmpeoraron(
        resumenes(_mediciones, _datos.hoy),
      ),
      totalIndicadores: indicadores.length,
      prioridad: conAlertaLista,
      nombresSedes: _nombresSedes,
      onVerConAlerta: _verPacientes,
      onVerTodos: _verPacientes,
      onVerIndicadores: () => _elegirSeccion(Seccion.indicadores),
      onAbrirPaciente: _abrirPaciente,
    );
  }

  Widget _seguimiento() {
    final escribiendo = _busqueda.trim().isNotEmpty && !_busquedaActiva;
    return SeguimientoPage(
      pacientes: _pacientesBuscados,
      busqueda: _busqueda,
      ayudaBusqueda: escribiendo
          ? 'Escriba al menos $minimoCaracteresBusqueda caracteres para buscar.'
          : null,
      nombresSedes: _nombresSedes,
      mensajeVacio: _altasRecientes.isEmpty
          ? mensajeSinAltas
          : 'Ningún paciente coincide con la búsqueda.',
      onBuscar: (texto) => setState(() => _busqueda = texto),
      onAbrirPaciente: _abrirPaciente,
    );
  }

  /// Pantalla completa del último paso tras iniciar sesión: el propósito
  /// para ver la lista de pacientes con alta reciente (F-06, F-16).
  Widget _propositoLista(Usuario usuario, Sede sede, _Solicitud solicitud) {
    final altas = _altasRecientes;
    return PropositoListaPage(
      saludo: '${saludoSegunHora(_datos.hoy)}, ${usuario.saludo}',
      rol: usuario.rol.nombre,
      sede: sede.nombreCorto,
      fecha: formatoFechaHora(_datos.hoy),
      totalPacientes: altas.length,
      conAlerta: altas.where((p) => conAlerta(p.riesgo)).length,
      propositos: propositosDe(usuario.rol),
      elegido: solicitud.elegido,
      error: solicitud.error,
      quedaraRegistrado: _quedaraRegistrado(usuario, sede),
      onElegir: _elegirProposito,
      onConfirmar: _confirmarProposito,
      onCancelar: _cancelarProposito,
    );
  }

  String _quedaraRegistrado(Usuario usuario, Sede sede) =>
      '${usuario.nombre} · ${sede.nombreCorto} · '
      '${formatoFechaHora(_datos.hoy)}';

  /// Pop-up para declarar el propósito de abrir a un paciente (F-16).
  Widget _dialogo(Usuario usuario, _Solicitud solicitud) {
    final paciente = solicitud.paciente;
    if (paciente == null) return const SizedBox.shrink();
    final sede = _datos.sede(_sedeSesion ?? usuario.sedesAsignadas.first);
    return DialogoProposito(
      destino: DestinoPaciente(
        paciente: paciente,
        sedeAlta: _nombresSedes[paciente.sedeAltaId] ?? '',
        mostrarRiesgo: usuario.rol != Rol.administrativo,
      ),
      accion: solicitud.registrar
          ? AccionDialogo.registrarAtencion
          : (usuario.rol == Rol.administrativo
                ? AccionDialogo.verDatosBasicos
                : AccionDialogo.abrirHistoria),
      // Al registrar solo sirven *Atención del paciente* y *Urgencia* (F-04).
      propositos: [
        for (final p in propositosDe(usuario.rol))
          if (!solicitud.registrar ||
              p == Proposito.atencionPaciente ||
              p == Proposito.urgencia)
            p,
      ],
      elegido: solicitud.elegido,
      error: solicitud.error,
      quedaraRegistrado: _quedaraRegistrado(usuario, sede),
      onElegir: _elegirProposito,
      onConfirmar: _confirmarProposito,
      onCancelar: _cancelarProposito,
    );
  }

  /// Las acciones que cierran lo abierto y llevan a una sección.
  ValueChanged<int> _irASeccion(Usuario usuario) {
    final secciones = seccionesDe(usuario.rol);
    return (i) => setState(() {
      _cerrarDetalles();
      _irA(secciones[i]);
    });
  }

  Sede _sedeDe(Usuario usuario) =>
      _datos.sede(_sedeSesion ?? usuario.sedesAsignadas.first);

  /// Tablero de indicadores (F-08): el valor de la red de cada uno, su cambio
  /// y las sedes donde actuar primero.
  Widget _tablero() {
    final destacado = indicadorDe(IdIndicador.reingreso);
    final comparacion = comparacionDe(
      _mediciones,
      destacado,
      _datos.sedes,
      _datos.hoy,
    );
    return IndicadoresPage(
      resumenes: resumenes(_mediciones, _datos.hoy),
      destacado: destacado,
      comparacionDestacada: comparacion,
      promedioDestacado: valorRed(
        _mediciones,
        destacado.id,
        ultimoPeriodo(_datos.hoy),
      ),
      onAbrirDetalle: (id) => setState(() {
        _indicadorAbierto = id;
        _sedeTendencia = null;
      }),
    );
  }

  /// Detalle de un indicador (F-09, F-10, F-11) con las barras de la app.
  Widget _detalleIndicador(Usuario usuario, IdIndicador id) {
    final indicador = indicadorDe(id);
    final sedes = [
      for (final s in _datos.sedes)
        if (aplica(indicador, s.tipo)) s,
    ];
    return _marco(
      usuario: usuario,
      sede: _sedeDe(usuario),
      escritorio: MediaQuery.sizeOf(context).width >= anchoEscritorio,
      onDestino: _irASeccion(usuario),
      body: DetalleIndicadorPage(
        indicador: indicador,
        sedesDisponibles: sedes,
        sedeTendencia: _sedeTendencia,
        tendencia: tendenciaDe(
          _mediciones,
          id,
          _datos.hoy,
          sedeId: _sedeTendencia,
        ),
        comparacion: comparacionDe(
          _mediciones,
          indicador,
          _datos.sedes,
          _datos.hoy,
        ),
        promedio: valorRed(_mediciones, id, ultimoPeriodo(_datos.hoy)),
        mediciones: medicionesRecientes(
          _mediciones,
          indicador,
          _datos.sedes,
          _datos.hoy,
        ),
        onElegirSede: (sedeId) => setState(() => _sedeTendencia = sedeId),
        onVolver: () => setState(() {
          _indicadorAbierto = null;
          _sedeTendencia = null;
        }),
      ),
    );
  }

  /// Registrar la medición mensual de un indicador (F-12).
  Widget _registrarMedicion() {
    final registradas = [
      for (final m in _mediciones.reversed)
        if (m.registradaPor != null)
          (
            indicador: indicadorDe(m.indicador),
            sede: _datos.sede(m.sedeId).nombreCorto,
            periodo: m.periodo,
            valor: m.valor,
          ),
    ];
    return RegistrarMedicionPage(
      sedes: _datos.sedes,
      hoy: _datos.hoy,
      registradas: registradas,
      validar: _validarMedicion,
      onGuardar: _guardarMedicion,
    );
  }

  /// Buscar pacientes por nombre o documento (F-01). Buscar no crea un evento:
  /// solo muestra el nombre y el documento; el evento se crea al abrirlo.
  Widget _buscar(Usuario usuario) {
    final esMedico = usuario.rol == Rol.medico;
    return BuscarPacientesPage(
      busqueda: _busquedaPaciente,
      resultados: buscarPacientes(_pacientes, _busquedaPaciente),
      accionAlElegir: esMedico
          ? 'Abrir la historia clínica'
          : 'Ver los datos básicos',
      onBuscar: (texto) => setState(() => _busquedaPaciente = texto),
      onElegir: _abrirPaciente,
    );
  }

  /// Datos básicos de un paciente para el administrativo (F-03).
  Widget _paginaDatosBasicos(Usuario usuario, _DatosBasicos d) {
    final paciente = _pacientes.firstWhere(
      (p) => p.id == d.paciente.id,
      orElse: () => d.paciente,
    );
    return _marco(
      usuario: usuario,
      sede: _sedeDe(usuario),
      escritorio: MediaQuery.sizeOf(context).width >= anchoEscritorio,
      onDestino: _irASeccion(usuario),
      body: DatosBasicosPage(
        paciente: historiaDe(
          paciente,
          sedeAlta: _nombresSedes[paciente.sedeAltaId] ?? '',
          hoy: _datos.hoy,
        ),
        propositoTexto: d.proposito.nombreCorto,
        fechaConsulta: formatoFechaHora(_datos.hoy),
        onVolver: () => setState(() => _datosBasicos = null),
      ),
    );
  }

  /// Historia clínica unificada, con el riesgo y sus factores (F-02, F-07).
  Widget _paginaHistoria(Usuario usuario, _Historia h) {
    // El paciente puede haber cambiado (por ejemplo, ganó relación al
    // registrarle una atención), así que se busca el actual.
    final paciente = _pacientes.firstWhere(
      (p) => p.id == h.paciente.id,
      orElse: () => h.paciente,
    );
    final historia = historiaDe(
      paciente,
      sedeAlta: _nombresSedes[paciente.sedeAltaId] ?? '',
      hoy: _datos.hoy,
      nuevas: _atenciones[paciente.id] ?? const [],
    );
    return _marco(
      usuario: usuario,
      sede: _sedeDe(usuario),
      escritorio: MediaQuery.sizeOf(context).width >= anchoEscritorio,
      onDestino: _irASeccion(usuario),
      body: PacientePage(
        historia: historia,
        proposito: h.proposito,
        fechaConsulta: formatoFechaHora(_datos.hoy),
        puedeRegistrar: usuario.rol == Rol.medico,
        onVolver: _cerrarHistoria,
        onRegistrarAtencion: () => _pedirRegistro(paciente),
      ),
    );
  }

  /// Formulario para registrar una atención (F-04).
  Widget _paginaRegistro(Usuario usuario, _Registro r) {
    return _marco(
      usuario: usuario,
      sede: _sedeDe(usuario),
      escritorio: MediaQuery.sizeOf(context).width >= anchoEscritorio,
      onDestino: _irASeccion(usuario),
      body: RegistrarAtencionPage(
        nombrePaciente: r.paciente.nombre,
        proposito: r.proposito,
        medico: usuario.nombre,
        sedes: [
          for (final s in _datos.sedes)
            if (s.tipo != TipoSede.laboratorio) s,
        ],
        sedeInicialId: _sedeSesion ?? usuario.sedesAsignadas.first,
        ahora: _datos.hoy,
        onGuardar: _guardarAtencion,
        onCancelar: () => setState(() => _registro = null),
      ),
    );
  }

  /// Auditoría de accesos (F-21). Solo el auditor tiene esta sección
  /// (F-18): los demás roles no la ven en su navegación.
  Widget _auditoria() {
    return AuditoriaPage(
      eventos: eventosFiltrados(_eventos, _filtroAuditoria),
      filtro: _filtroAuditoria,
      nombresUsuarios: {for (final u in _datos.usuarios) u.id: u.nombre},
      nombresPacientes: {for (final p in _pacientes) p.id: p.nombre},
      nombresSedes: {for (final s in _datos.sedes) s.id: s.nombre},
      onElegirFiltro: (f) => setState(() => _filtroAuditoria = f),
    );
  }

  /// Perfil (F-22) con las mismas barras de la app. Tocar un destino cierra
  /// el perfil y va a esa sección; *Cerrar sesión* es el de F-23.
  Widget _perfil() {
    final usuario = _usuario;
    if (usuario == null) return const SizedBox.shrink();
    final sede = _datos.sede(_sedeSesion ?? usuario.sedesAsignadas.first);
    return _marco(
      usuario: usuario,
      sede: sede,
      escritorio: MediaQuery.sizeOf(context).width >= anchoEscritorio,
      onDestino: _irASeccion(usuario),
      body: PerfilPage(
        datos: [
          (etiqueta: 'Nombre', valor: usuario.nombre),
          (etiqueta: 'Correo', valor: usuario.correo),
          (etiqueta: 'Rol', valor: usuario.rol.nombre),
          (etiqueta: 'Sede de esta sesión', valor: sede.nombre),
          (
            etiqueta: 'Sedes asignadas',
            valor: [
              for (final id in usuario.sedesAsignadas) _datos.sede(id).nombre,
            ].join('\n'),
          ),
        ],
        permisos: [
          for (final a in AccionPermitida.values)
            (accion: a.nombre, permitido: rolPermite(usuario.rol, a)),
        ],
        propositos: [for (final p in propositosDe(usuario.rol)) p.nombreCorto],
        onCerrarSesion: _cerrarSesion,
      ),
    );
  }
}
