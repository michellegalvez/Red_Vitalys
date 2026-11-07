import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/pages/acceso_page.dart';
import 'package:red_vitalys/pages/consulta_page.dart';
import 'package:red_vitalys/pages/inicio_page.dart';
import 'package:red_vitalys/pages/pendiente_page.dart';
import 'package:red_vitalys/pages/proposito_lista_page.dart';
import 'package:red_vitalys/pages/seguimiento_page.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/screens/secciones.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/navegacion.dart';
import 'package:red_vitalys/widgets/proposito.dart';

/// Una declaración de propósito en curso. Sin paciente es la de la lista
/// de pacientes con alta reciente (F-06); con paciente, la de abrirlo.
class _Solicitud {
  const _Solicitud({this.paciente, this.elegido, this.error});

  final PacienteEnSeguimiento? paciente;
  final Proposito? elegido;
  final String? error;
}

/// Un paciente abierto, con el propósito declarado y lo que se decidió.
typedef _Consulta = ({
  PacienteEnSeguimiento paciente,
  Proposito proposito,
  ResultadoConsulta resultado,
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
  _Consulta? _consulta;
  bool _verPerfil = false;

  // Filtros de Pacientes en seguimiento.
  String _busqueda = '';

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
    final usuarioEscrito = _datos.usuarioPorCorreo(_correo.text);
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
      _consulta = null;
      _verPerfil = false;
      _listaDeclarada = false;
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

  void _elegirProposito(Proposito p) {
    final s = _solicitud;
    if (s == null) return;
    setState(() => _solicitud = _Solicitud(paciente: s.paciente, elegido: p));
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
        );
      });
      return;
    }
    final paciente = s.paciente;
    setState(() {
      _solicitud = null;
      if (paciente == null) {
        _listaDeclarada = true;
        return;
      }
      _consulta = (
        paciente: paciente,
        proposito: elegido,
        resultado: evaluarConsulta(
          usuario: usuario,
          paciente: paciente,
          proposito: elegido,
          hoy: _datos.hoy,
        ),
      );
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

  void _cerrarConsulta() => setState(() => _consulta = null);

  void _declararUrgencia() {
    final c = _consulta;
    if (c == null) return;
    setState(() => _consulta = null);
    _abrirPaciente(c.paciente, elegido: Proposito.urgencia);
  }

  // ---------------------------------------------------------------------
  // Datos para las Pages
  // ---------------------------------------------------------------------

  Map<String, String> get _nombresSedes => {
    for (final s in _datos.sedes) s.id: s.nombreCorto,
  };

  List<PacienteEnSeguimiento> get _altasRecientes =>
      pacientesConAltaReciente(_datos.pacientes, _datos.hoy);

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
    final consulta = _consulta;
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
        child: NavigatorPopHandler(
          enabled: _atrasPendiente,
          onPopWithResult: (_) => _navegador.currentState?.maybePop(),
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
                if (_verPerfil)
                  MaterialPage<void>(
                    key: const ValueKey('perfil'),
                    child: _perfil(),
                  ),
                if (consulta != null)
                  MaterialPage<void>(
                    key: ValueKey('consulta-${consulta.paciente.id}'),
                    child: ConsultaPage(
                      resultado: consulta.resultado,
                      paciente: consulta.paciente,
                      proposito: consulta.proposito,
                      sedeAlta:
                          _nombresSedes[consulta.paciente.sedeAltaId] ?? '',
                      onVolver: _cerrarConsulta,
                      onDeclararUrgencia: _declararUrgencia,
                    ),
                  ),
              ],
            ],
            onDidRemovePage: (page) {
              final clave = page.key;
              if (clave is! ValueKey<String>) return;
              if (clave.value.startsWith('consulta')) {
                _cerrarConsulta();
              } else if (clave.value == 'perfil') {
                setState(() => _verPerfil = false);
              }
            },
          ),
        ),
      ),
    );
  }

  /// Hay algo a lo que volver con Atrás: el paso de la sede, el perfil, una
  /// consulta abierta o una declaración de propósito. Si no, Atrás sale de
  /// la app como siempre.
  bool get _atrasPendiente {
    if (_usuario == null) return _paso == PasoAcceso.sede;
    return _verPerfil || _consulta != null || _solicitud != null;
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
    final indice = secciones.indexOf(_seccion).clamp(0, secciones.length - 1);
    final destinos = [for (final s in secciones) s.destino];
    final sede = _datos.sede(_sedeSesion ?? usuario.sedesAsignadas.first);
    final solicitud = _solicitud;

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
                    excluding: solicitud != null,
                    child: ExcludeFocus(
                      excluding: solicitud != null,
                      child: Scaffold(
                        appBar: BarraSuperior(
                          iniciales: usuario.iniciales,
                          nombreUsuario: usuario.nombre,
                          sede: sede.nombreCorto,
                          detalleUsuario:
                              '${usuario.rol.nombre} · ${sede.nombreCorto}',
                          destinos: destinos,
                          indiceActual: indice,
                          onDestino: (i) => _elegirSeccion(secciones[i]),
                          onPerfil: () => setState(() => _verPerfil = true),
                          onSalir: _cerrarSesion,
                        ),
                        bottomNavigationBar: escritorio
                            ? null
                            : BarraInferior(
                                destinos: destinos,
                                indiceActual: indice,
                                onDestino: (i) => _elegirSeccion(secciones[i]),
                              ),
                        body: _contenido(usuario, sede),
                      ),
                    ),
                  ),
                ),
                // El pop-up de un paciente desenfoca toda la pantalla.
                if (solicitud != null) ...[
                  const Positioned.fill(child: FondoDialogo()),
                  Positioned.fill(child: _dialogo(usuario, solicitud)),
                ],
              ],
            ),
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
      Seccion.indicadores => const PendientePage(
        sobretitulo: 'Calidad de la red',
        titulo: 'Tablero de indicadores',
        descripcion:
            'Reingreso hospitalario a 30 días, tiempo de espera, adherencia '
            'a protocolos clínicos y eventos adversos evitables, por sede.',
        icono: Icons.insights_rounded,
      ),
      Seccion.mediciones => const PendientePage(
        sobretitulo: 'Calidad de la red',
        titulo: 'Registrar medición mensual',
        descripcion: 'Las mediciones del mes de los 4 indicadores de una sede.',
        icono: Icons.edit_note_rounded,
      ),
      Seccion.auditoria => const PendientePage(
        sobretitulo: 'Control de accesos',
        titulo: 'Auditoría de accesos',
        descripcion:
            'Quién accedió, cuándo, a qué recurso, con qué resultado y con '
            'qué propósito.',
        icono: Icons.fact_check_outlined,
      ),
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
      indicadoresQueEmpeoraron: _datos.indicadoresQueEmpeoraron,
      totalIndicadores: _datos.totalIndicadores,
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
      ),
      propositos: propositosDe(usuario.rol),
      elegido: solicitud.elegido,
      error: solicitud.error,
      quedaraRegistrado: _quedaraRegistrado(usuario, sede),
      onElegir: _elegirProposito,
      onConfirmar: _confirmarProposito,
      onCancelar: _cancelarProposito,
    );
  }

  Widget _perfil() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _verPerfil = false),
        ),
        title: const Text(
          'Mi perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: const PendientePage(
        sobretitulo: 'Su cuenta',
        titulo: 'Mi perfil',
        descripcion:
            'Sus datos, la sede de la sesión y lo que su rol puede '
            'hacer.',
        icono: Icons.person_outline_rounded,
      ),
    );
  }
}
