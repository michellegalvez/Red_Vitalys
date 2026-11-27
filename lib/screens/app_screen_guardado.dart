part of 'app_screen.dart';

/// Validar y guardar lo que captura el médico y el administrativo: las
/// mediciones (F-12) y las atenciones (F-04). Cambia el estado solo con
/// `_actualizar`.
extension _Guardado on _AppScreenState {
  /// El nombre de la sede de la sesión, la de los eventos (AD-05).
  String? get _nombreSedeSesion {
    final id = _sedeSesion;
    return id == null ? null : _datos.sede(id).nombre;
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
  ///
  /// Devuelve el mensaje de error, o `null` si se guardó.
  Future<String?> _guardarMedicion(NuevaMedicion nueva) async {
    final usuario = _usuario;
    final valor = leerValor(nueva.valorTexto);
    if (usuario == null || valor == null) return null;
    final sesion = _sesion;
    if (!_indicators.isRemote) {
      // Con los datos en memoria se nota el estado "Guardando medición…".
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return null;
    }
    if (!intentarAcceso(
      AccionPermitida.registrarMedicion,
      RecursoAuditoria.medicionIndicador,
    )) {
      return rechazoRol;
    }
    // Se vuelve a validar al guardar: la regla no depende de la Page.
    final rechazo = _validarMedicion(nueva);
    if (rechazo != null) return rechazo;
    if (_falla('evento-medicion')) return _mensajeFallaAccion;
    if (_falla('guardar-medicion')) return _mensajeFallaMedicion;
    final medicion = Medicion(
      indicador: nueva.indicador,
      sedeId: nueva.sedeId,
      periodo: nueva.periodo,
      valor: redondear1(valor),
      registradaPor: usuario.nombre,
      registradaEn: _datos.hoy,
    );
    // Sin evento no se guarda la medición (F-12 paso 5, F-20).
    final evento = _armarEvento(
      usuario: usuario,
      sedeId: _sedeSesion,
      accion: AccionAuditoria.registrar,
      recurso: RecursoAuditoria.medicionIndicador,
      resultado: ResultadoAuditoria.permitido,
    );
    if (_indicators.isRemote) {
      // Con Supabase, el evento se guarda con la medición en la misma
      // operación: si el evento no se crea, la medición tampoco, y si la
      // medición falla no queda un evento suelto.
      try {
        await _indicators.addMeasurement(
          medicion,
          siteName: _datos.sede(nueva.sedeId).nombre,
          sessionSiteName: _nombreSedeSesion,
        );
      } on DuplicateMeasurement {
        return mensajeMedicionRepetida;
      } on AuditEventNotSaved {
        return mounted ? _mensajeFallaAccion : null;
      } catch (error) {
        debugPrint('No se pudo guardar la medición: $error');
        return _mensajeFallaMedicion;
      }
    } else if (!await _guardarEventosAntes([evento])) {
      return mounted ? _mensajeFallaAccion : null;
    }
    if (!mounted || sesion != _sesion) return null;
    _actualizar(() {
      _mediciones = [..._mediciones, medicion];
      _anotarEvento(evento, enviar: false);
    });
    return null;
  }

  /// Guarda la atención que llenó el médico: queda primera en la historia,
  /// con *Atención del paciente* le da relación con el paciente y deja su
  /// evento (F-04, F-05, F-20).
  ///
  /// Devuelve el mensaje de error, o `null` si se guardó. Con error no se
  /// guarda la atención ni se crea el evento (F-20).
  Future<String?> _guardarAtencion(NuevaAtencion nueva) async {
    final registro = _registro;
    final usuario = _usuario;
    if (registro == null || usuario == null) return null;
    final sesion = _sesion;
    if (!_histories.isRemote) {
      // Con los datos en memoria se nota el estado "Guardando atención…".
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return null;
    }
    if (_falla('evento-atencion')) return _mensajeFallaAccion;
    if (_falla('guardar-atencion')) return _mensajeFallaAtencion;
    final paciente = registro.paciente;
    // Sin evento no se guarda la atención (F-04 paso 4, F-20).
    final evento = _armarEvento(
      usuario: usuario,
      sedeId: _sedeSesion,
      accion: AccionAuditoria.registrar,
      recurso: RecursoAuditoria.atencion,
      resultado: ResultadoAuditoria.permitido,
      paciente: paciente,
      proposito: registro.proposito,
    );
    if (_histories.isRemote) {
      // Con Supabase, el evento se guarda con la atención en la misma
      // operación: si el evento no se crea, la atención tampoco, y si la
      // atención falla no queda un evento suelto.
      try {
        await _histories.addEncounter(
          paciente,
          nueva,
          siteName: _datos.sede(nueva.sedeId).nombre,
          purpose: registro.proposito,
          sessionSiteName: _nombreSedeSesion,
        );
      } on AuditEventNotSaved {
        return mounted ? _mensajeFallaAccion : null;
      } catch (error) {
        debugPrint('No se pudo registrar la atención: $error');
        return mounted ? _mensajeFallaAtencion : null;
      }
    } else if (!await _guardarEventosAntes([evento])) {
      return mounted ? _mensajeFallaAccion : null;
    }
    // Si la sesión cambió, no se escribe a nombre de otro usuario.
    if (!mounted || sesion != _sesion) return null;
    final total = _atenciones.values.fold<int>(0, (a, l) => a + l.length);
    final atencion = atencionDeFormulario(
      id: 'enc-n${total + 1}',
      nueva: nueva,
      sede: _datos.sede(nueva.sedeId).nombreCorto,
      medico: usuario.nombre,
    );
    _actualizar(() {
      // Con Supabase la atención ya está en la base y llega con la historia.
      if (!_histories.isRemote) {
        _atenciones = {
          ..._atenciones,
          paciente.id: ordenarAtenciones([
            atencion,
            ...?_atenciones[paciente.id],
          ]),
        };
      }
      if (registro.proposito == Proposito.atencionPaciente &&
          !paciente.medicosConAtencion.contains(usuario.id)) {
        final actualizado = paciente.copyWith(
          medicosConAtencion: [...paciente.medicosConAtencion, usuario.id],
        );
        _pacientes = [
          for (final p in _pacientes) p.id == paciente.id ? actualizado : p,
        ];
      }
      _anotarEvento(evento, enviar: false);
      _registro = null;
    });
    if (_histories.isRemote) unawaited(_cargarHistoria());
    // Con *Urgencia* también se avisa que queda registrado (F-17 CA-10).
    final esUrgencia = registro.proposito == Proposito.urgencia;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esUrgencia
              ? '$avisoAccesoEmergencia. Atención registrada en la historia '
                    'unificada'
              : 'Atención registrada en la historia unificada',
        ),
      ),
    );
    return null;
  }
}
