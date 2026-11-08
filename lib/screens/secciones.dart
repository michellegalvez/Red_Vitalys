import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/widgets/navegacion.dart';

/// Las secciones de la app a las que se llega desde la navegación.
enum Seccion { inicio, pacientes, buscar, indicadores, mediciones, auditoria }

extension SeccionDestino on Seccion {
  DestinoNavegacion get destino => switch (this) {
    Seccion.inicio => (icono: Icons.home_rounded, nombre: 'Inicio'),
    Seccion.pacientes => (icono: Icons.groups_rounded, nombre: 'Pacientes'),
    Seccion.buscar => (icono: Icons.search_rounded, nombre: 'Buscar'),
    Seccion.indicadores => (
      icono: Icons.insights_rounded,
      nombre: 'Indicadores',
    ),
    Seccion.mediciones => (
      icono: Icons.edit_note_rounded,
      nombre: 'Mediciones',
    ),
    Seccion.auditoria => (
      icono: Icons.fact_check_outlined,
      nombre: 'Auditoría',
    ),
  };

  /// Inicio y Pacientes muestran la lista de pacientes con alta reciente,
  /// que pide declarar el propósito (F-06, F-16).
  bool get muestraPacientes =>
      this == Seccion.inicio || this == Seccion.pacientes;
}

/// El recurso que se consulta al entrar a cada sección, para el evento
/// *Denegado* cuando el rol no la tiene (F-18, F-20).
RecursoAuditoria recursoDeSeccion(Seccion seccion) => switch (seccion) {
  Seccion.inicio || Seccion.pacientes => RecursoAuditoria.pacientesAltaReciente,
  Seccion.buscar => RecursoAuditoria.datosBasicos,
  Seccion.indicadores => RecursoAuditoria.medicionIndicador,
  Seccion.mediciones => RecursoAuditoria.medicionIndicador,
  Seccion.auditoria => RecursoAuditoria.auditoriaAccesos,
};

/// La acción de la tabla de permisos (F-18) que pide cada sección.
AccionPermitida accionDeSeccion(Seccion seccion) => switch (seccion) {
  Seccion.inicio || Seccion.pacientes => AccionPermitida.verHistoria,
  Seccion.buscar => AccionPermitida.buscarPaciente,
  Seccion.indicadores => AccionPermitida.verTablero,
  Seccion.mediciones => AccionPermitida.registrarMedicion,
  Seccion.auditoria => AccionPermitida.verAuditoria,
};

/// Secciones de cada rol, según la tabla de permisos (F-18). La primera es
/// la pantalla inicial del rol (RF-37).
List<Seccion> seccionesDe(Rol rol) => switch (rol) {
  Rol.medico => const [
    Seccion.inicio,
    Seccion.pacientes,
    Seccion.buscar,
    Seccion.indicadores,
  ],
  Rol.administrativo => const [
    Seccion.indicadores,
    Seccion.buscar,
    Seccion.mediciones,
  ],
  Rol.auditor => const [Seccion.auditoria, Seccion.indicadores],
};
