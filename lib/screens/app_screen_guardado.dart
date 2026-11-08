part of 'app_screen.dart';

/// Validar y guardar lo que captura el médico y el administrativo: las
/// mediciones (F-12) y las atenciones (F-04). Cambia el estado solo con
/// `_actualizar`.
extension _Guardado on _AppScreenState {
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
  String? _guardarMedicion(NuevaMedicion nueva) {
    final usuario = _usuario;
    final valor = leerValor(nueva.valorTexto);
    if (usuario == null || valor == null) return null;
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
    _actualizar(() {
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
    return null;
  }

  /// Guarda la atención que llenó el médico: queda primera en la historia,
  /// con *Atención del paciente* le da relación con el paciente y deja su
  /// evento (F-04, F-05, F-20).
  ///
  /// Devuelve el mensaje de error, o `null` si se guardó. Con error no se
  /// guarda la atención ni se crea el evento (F-20).
  String? _guardarAtencion(NuevaAtencion nueva) {
    final registro = _registro;
    final usuario = _usuario;
    if (registro == null || usuario == null) return null;
    if (_falla('evento-atencion')) return _mensajeFallaAccion;
    if (_falla('guardar-atencion')) return _mensajeFallaAtencion;
    final paciente = registro.paciente;
    final total = _atenciones.values.fold<int>(0, (a, l) => a + l.length);
    final atencion = atencionDeFormulario(
      id: 'enc-n${total + 1}',
      nueva: nueva,
      sede: _datos.sede(nueva.sedeId).nombreCorto,
      medico: usuario.nombre,
    );
    _actualizar(() {
      _atenciones = {
        ..._atenciones,
        paciente.id: ordenarAtenciones([
          atencion,
          ...?_atenciones[paciente.id],
        ]),
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
