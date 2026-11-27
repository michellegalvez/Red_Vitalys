// Reglas del registro de cuentas y de la gestión de usuarios (F-24). Puras,
// sin Flutter.

import 'package:red_vitalys/modelos/modelos.dart';

/// Largo mínimo de la contraseña de una cuenta nueva (RF-39).
const int largoMinimoClave = 8;

const String mensajeCuentaCreada =
    'Cuenta creada. Confirme su correo y espere a que la Dirección la apruebe.';
const String mensajeCorreoTomado = 'Ya existe una cuenta con ese correo.';
const String mensajeClaveCorta =
    'La contraseña debe tener al menos 8 caracteres.';
const String mensajeClavesDistintas = 'Las contraseñas no coinciden.';
const String mensajeNombreVacio = 'Escriba su nombre completo.';
const String mensajeCorreoInvalido = 'Escriba un correo válido.';
const String mensajeFallaRegistro =
    'No se pudo crear la cuenta. Intente de nuevo.';
const String mensajeAsigneSede = 'Asigne al menos una sede.';
const String mensajeCuentaPropia =
    'No puede quitarse su propio rol ni desactivar su cuenta.';
const String mensajeFallaCambio =
    'No se pudo guardar el cambio. Intente de nuevo.';
const String mensajeSinPendientes = 'No hay cuentas que esperen aprobación.';
const String mensajeFallaCuentas = 'No se pudieron cargar los usuarios';

final _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// El primer problema de los datos para crear una cuenta, o `null` si sirven
/// (F-24 A2).
String? validarRegistro({
  required String nombre,
  required String correo,
  required String clave,
  required String repetida,
}) {
  if (nombre.trim().isEmpty) return mensajeNombreVacio;
  if (!_formatoCorreo.hasMatch(correo.trim())) return mensajeCorreoInvalido;
  if (clave.length < largoMinimoClave) return mensajeClaveCorta;
  if (clave != repetida) return mensajeClavesDistintas;
  return null;
}

/// El problema de un cambio de cuenta, o `null` si se puede guardar
/// (F-24 A5, A6).
String? validarCambio({
  required bool esPropia,
  required Rol rol,
  required List<String> sedes,
  required bool activa,
}) {
  if (esPropia && (rol != Rol.director || !activa)) return mensajeCuentaPropia;
  if (activa && sedes.isEmpty) return mensajeAsigneSede;
  return null;
}

/// Una cuenta activa sin sedes espera que el director la apruebe (F-24).
bool esPendiente({required bool activa, required List<String> sedes}) =>
    activa && sedes.isEmpty;
