part of 'app_screen.dart';

/// Cómo se arma cada Page con el estado de [_AppScreenState]. Solo lee el
/// estado y conecta los callbacks; los cambios pasan por `_actualizar`.
extension _Paginas on _AppScreenState {
  /// La raíz de la app: el Navigator con las pantallas apiladas y, encima,
  /// el pop-up de propósito cuando hace falta.
  Widget _raiz() {
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
        // La rueda del mouse también es uso (F-15).
        onPointerSignal: (_) => _registrarActividad(),
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
                          _actualizar(() => _datosBasicos = null);
                        } else if (id.startsWith('registro')) {
                          _actualizar(() => _registro = null);
                        } else if (id.startsWith('denegado')) {
                          _cerrarDenegado();
                        } else if (id == 'indicador') {
                          _actualizar(() {
                            _indicadorAbierto = null;
                            _sedeTendencia = null;
                          });
                        } else if (id == 'perfil') {
                          _actualizar(() => _verPerfil = false);
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
            _actualizar(() => _mostrarContrasena = !_mostrarContrasena),
        onIngresar: _ingresar,
        onElegirPerfil: _rellenarPerfil,
        onElegirSede: (id) => _actualizar(() {
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
        onPerfil: () => _actualizar(() => _verPerfil = true),
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
      onBuscar: (texto) => _actualizar(() => _busqueda = texto),
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
      accion: solicitud.registrar
          ? AccionDialogo.registrarAtencion
          : (usuario.rol == Rol.administrativo
                ? AccionDialogo.verDatosBasicos
                : AccionDialogo.abrirHistoria),
      // Al registrar solo sirven *Atención del paciente* y *Urgencia* (F-04).
      propositos: solicitud.registrar
          ? propositosParaRegistrar(usuario.rol)
          : propositosDe(usuario.rol),
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
    return (i) => _actualizar(() {
      _cerrarDetalles();
      _irA(secciones[i]);
    });
  }

  Sede _sedeDe(Usuario usuario) =>
      _datos.sede(_sedeSesion ?? usuario.sedesAsignadas.first);

  /// Tablero de indicadores (F-08): el valor de la red de cada uno, su cambio
  /// y las sedes donde actuar primero.
  Widget _tablero() {
    final destacado = indicadorDe(_indicadorTablero);
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
      periodo: ultimoPeriodo(_datos.hoy),
      // Las sedes con su marca se ven para el indicador que se elija (F-08).
      onElegirDestacado: (id) => _actualizar(() => _indicadorTablero = id),
      onAbrirDetalle: (id) => _actualizar(() {
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
        onElegirSede: (sedeId) => _actualizar(() => _sedeTendencia = sedeId),
        onVolver: () => _actualizar(() {
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
      onBuscar: (texto) => _actualizar(() => _busquedaPaciente = texto),
      onElegir: _abrirPaciente,
    );
  }

  /// Datos básicos de un paciente para el administrativo (F-03).
  Widget _paginaDatosBasicos(Usuario usuario, _ConsultaAbierta d) {
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
        onVolver: () => _actualizar(() => _datosBasicos = null),
      ),
    );
  }

  /// Historia clínica unificada, con el riesgo y sus factores (F-02, F-07).
  Widget _paginaHistoria(Usuario usuario, _ConsultaAbierta h) {
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
  Widget _paginaRegistro(Usuario usuario, _ConsultaAbierta r) {
    return _marco(
      usuario: usuario,
      sede: _sedeDe(usuario),
      escritorio: MediaQuery.sizeOf(context).width >= anchoEscritorio,
      onDestino: _irASeccion(usuario),
      body: RegistrarAtencionPage(
        nombrePaciente: r.paciente.nombre,
        proposito: r.proposito,
        medico: usuario.nombre,
        // Cualquier sede de la red (F-04).
        sedes: _datos.sedes,
        sedeInicialId: _sedeSesion ?? usuario.sedesAsignadas.first,
        ahora: _datos.hoy,
        onGuardar: _guardarAtencion,
        onCancelar: () => _actualizar(() => _registro = null),
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
      onElegirFiltro: (f) => _actualizar(() => _filtroAuditoria = f),
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
