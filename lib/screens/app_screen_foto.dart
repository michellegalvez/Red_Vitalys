part of 'app_screen.dart';

/// La foto de perfil (F-22): traerla, elegir otra, subirla y quitarla. Cambia
/// el estado solo con `setState`; los datos van y vienen por el repositorio.
extension _Foto on _AppScreenState {
  void _abrirPerfil() {
    _actualizar(() => _verPerfil = true);
    _cargarPerfil();
    _cargarFoto();
  }

  /// Vuelve a leer el perfil de la base (F-22 CA-8). En memoria no hay nada
  /// que traer.
  Future<void> _cargarPerfil() async {
    final usuario = _usuario;
    if (!_auth.isRemote || usuario == null) return;
    final pedido = ++_pedidoPerfil;
    _actualizar(() {
      _cargandoPerfil = true;
      _errorPerfil = false;
    });
    bool vigente() => mounted && pedido == _pedidoPerfil && _usuario == usuario;
    try {
      final perfil = await _auth.reloadProfile(usuario);
      if (!vigente()) return;
      _actualizar(() {
        _perfilRemoto = perfil;
        _cargandoPerfil = false;
      });
    } catch (error) {
      debugPrint('No se pudo cargar el perfil: $error');
      if (!vigente()) return;
      _actualizar(() {
        _cargandoPerfil = false;
        _errorPerfil = true;
      });
    }
  }

  /// Trae la foto del usuario con sesión. Con [_simularFallas] la primera
  /// vez falla, como las demás cargas del modo demo.
  Future<void> _cargarFoto() async {
    if (_usuario == null) return;
    _actualizar(() {
      _cargandoFoto = true;
      _errorFoto = false;
    });
    try {
      if (_falla('cargar-foto')) throw StateError('Falla simulada');
      final bytes = await _fotos.descargar();
      if (!mounted || _usuario == null) return;
      _actualizar(() {
        _foto = bytes;
        _cargandoFoto = false;
      });
    } catch (error) {
      debugPrint('No se pudo cargar la foto: $error');
      if (!mounted) return;
      _actualizar(() {
        _cargandoFoto = false;
        _errorFoto = true;
      });
    }
  }

  /// Abre el selector, valida la foto (tipo y tamaño) y la sube.
  Future<void> _cambiarFoto() async {
    if (_usuario == null || _guardandoFoto) return;
    final FotoElegida? elegida;
    try {
      elegida = await _selectorFoto.elegir();
    } catch (error) {
      debugPrint('No se pudo abrir el selector de fotos: $error');
      _actualizar(() => _avisoFoto = mensajeFotoNoElegida);
      return;
    }
    if (elegida == null || !mounted) return;
    final rechazo = validarFoto(
      nombre: elegida.nombre,
      bytes: elegida.bytes.length,
      tipoMime: elegida.tipoMime,
    );
    if (rechazo != null) {
      _actualizar(() => _avisoFoto = rechazo);
      return;
    }
    final bytes = elegida.bytes;
    final extension = extensionDeFoto(
      elegida.nombre,
      tipoMime: elegida.tipoMime,
    )!;
    await _guardarFoto(
      () => _fotos.subir(bytes: bytes, extension: extension),
      nueva: bytes,
    );
  }

  Future<void> _quitarFoto() {
    return _guardarFoto(_fotos.quitar, nueva: null);
  }

  Future<void> _guardarFoto(
    Future<void> Function() guardar, {
    required Uint8List? nueva,
  }) async {
    _actualizar(() {
      _guardandoFoto = true;
      _avisoFoto = null;
    });
    try {
      if (_falla('guardar-foto')) throw StateError('Falla simulada');
      await guardar();
      if (!mounted || _usuario == null) return;
      _actualizar(() {
        _foto = nueva;
        _guardandoFoto = false;
      });
    } catch (error) {
      debugPrint('No se pudo guardar la foto: $error');
      if (!mounted) return;
      _actualizar(() {
        _guardandoFoto = false;
        _avisoFoto = mensajeFotoNoGuardada;
      });
    }
  }
}
