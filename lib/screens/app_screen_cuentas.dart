part of 'app_screen.dart';

/// El registro de cuentas y la gestión de usuarios del director (F-24). Cambia
/// el estado solo con `setState`; los datos van y vienen por el servicio de
/// cuentas.
extension _Cuentas on _AppScreenState {
  /// Crea la cuenta desde el acceso (RF-39). Devuelve el mensaje de error, o
  /// `null` si se creó.
  Future<String?> _crearCuenta({
    required String nombre,
    required String correo,
    required String clave,
  }) async {
    final resultado = await _cuentas.signUp(
      name: nombre,
      email: correo,
      password: clave,
    );
    return switch (resultado) {
      SignUpStatus.created => null,
      SignUpStatus.emailTaken => mensajeCorreoTomado,
      SignUpStatus.failed => mensajeFallaRegistro,
    };
  }

  /// Trae las cuentas al entrar a *Usuarios* (RF-40). Solo se aplica la
  /// respuesta del último pedido de esta sesión.
  Future<void> _cargarCuentas() async {
    if (_usuario?.rol != Rol.director) return;
    final pedido = ++_pedidoCuentas;
    final sesion = _sesion;
    _actualizar(() {
      _cargandoCuentas = true;
      _errorCuentas = false;
    });
    bool vigente() => mounted && pedido == _pedidoCuentas && sesion == _sesion;
    try {
      final cuentas = await _cuentas.listAccounts();
      if (!vigente()) return;
      _actualizar(() {
        _listaCuentas = cuentas;
        _cargandoCuentas = false;
      });
    } catch (error) {
      debugPrint('No se pudieron cargar las cuentas: $error');
      if (!vigente()) return;
      _actualizar(() {
        _cargandoCuentas = false;
        _errorCuentas = true;
      });
    }
  }

  /// Guarda el rol, las sedes y si la cuenta está activa. El evento se crea
  /// antes de guardar; con Supabase lo crea la base en la misma operación
  /// (F-20). Devuelve el mensaje de error o `null` si se guardó.
  Future<String?> _guardarCuenta(
    Account cuenta, {
    required Rol rol,
    required List<String> sedes,
    required bool activa,
  }) async {
    final usuario = _usuario;
    final sede = _sedeSesion;
    if (usuario == null || sede == null) return null;
    if (!intentarAcceso(
      AccionPermitida.gestionarUsuarios,
      RecursoAuditoria.usuario,
    )) {
      return rechazoRol;
    }
    final problema = validarCambio(
      esPropia: cuenta.email == usuario.correo,
      rol: rol,
      sedes: sedes,
      activa: activa,
    );
    if (problema != null) return problema;
    final sesion = _sesion;
    final evento = _armarEvento(
      usuario: usuario,
      sedeId: sede,
      accion: AccionAuditoria.registrar,
      recurso: RecursoAuditoria.usuario,
      resultado: ResultadoAuditoria.permitido,
      cuentaAfectada: cuenta.email,
    );
    // Con Supabase el evento lo crea la base junto con el cambio; sin ella se
    // guarda antes y, si no se puede, el cambio no se hace (F-20).
    if (!_cuentas.isRemote && !await _guardarEventosAntes([evento])) {
      return mounted ? mensajeFallaCambio : null;
    }
    if (!mounted || sesion != _sesion) return null;
    try {
      await _cuentas.saveAccount(
        account: cuenta,
        role: rol,
        sites: sedes,
        active: activa,
        sessionSite: sede,
      );
    } on AccountRejected catch (rechazo) {
      return switch (rechazo.refusal) {
        AccountRefusal.ownAccount => mensajeCuentaPropia,
        AccountRefusal.noSites => mensajeAsigneSede,
        AccountRefusal.role => rechazoRol,
      };
    } catch (error) {
      debugPrint('No se pudo guardar la cuenta: $error');
      return mensajeFallaCambio;
    }
    if (!mounted || sesion != _sesion) return null;
    _actualizar(() {
      // El evento ya está guardado: aquí solo se anota en la sesión.
      _anotarEvento(evento, enviar: false);
      _cuentaAbierta = null;
    });
    unawaited(_cargarCuentas());
    return null;
  }

  Widget _usuarios() {
    final abierta = [
      for (final c in _listaCuentas)
        if (c.id == _cuentaAbierta) c,
    ].firstOrNull;
    if (abierta != null) {
      return EditarCuentaPage(
        key: ValueKey(abierta.id),
        nombre: abierta.name,
        correo: abierta.email,
        rol: esPendiente(activa: abierta.active, sedes: abierta.sites)
            ? null
            : abierta.role,
        sedesAsignadas: abierta.sites,
        activa: abierta.active,
        sedes: _datos.sedes,
        onGuardar: ({required rol, required sedes, required activa}) =>
            _guardarCuenta(abierta, rol: rol, sedes: sedes, activa: activa),
        onVolver: () => _actualizar(() => _cuentaAbierta = null),
      );
    }
    final ordenadas = [..._listaCuentas]
      ..sort((a, b) {
        final pa = esPendiente(activa: a.active, sedes: a.sites);
        final pb = esPendiente(activa: b.active, sedes: b.sites);
        if (pa != pb) return pa ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return UsuariosPage(
      cuentas: [
        for (final c in ordenadas)
          (
            id: c.id,
            nombre: c.name,
            correo: c.email,
            rol: nombreDeRol(c.role),
            sedes: [for (final s in c.sites) _datos.sede(s).nombreCorto]
                .join(', '),
            activa: c.active,
            pendiente: esPendiente(activa: c.active, sedes: c.sites),
          ),
      ],
      soloPendientes: _soloPendientes,
      onFiltrar: (solo) => _actualizar(() => _soloPendientes = solo),
      onElegir: (id) => _actualizar(() => _cuentaAbierta = id),
      cargando: _cargandoCuentas,
      hayError: _errorCuentas,
      onReintentar: _cargarCuentas,
    );
  }
}
