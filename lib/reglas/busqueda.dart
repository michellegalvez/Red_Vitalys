/// Búsqueda de pacientes por nombre o documento (F-01, RF-01).
///
/// Es una función pura: el administrativo y el médico buscan igual, y lo que
/// cambia es lo que se abre al elegir un paciente.
library;

import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';

const String mensajeBusquedaCorta = 'Escriba al menos 3 caracteres';
const String mensajeSinResultados =
    'No se encontró ningún paciente con ese nombre o documento';

/// Si [texto] ya sirve para buscar: al menos 3 caracteres (F-01 A2).
bool busquedaValida(String texto) =>
    normalizarTexto(texto).length >= minimoCaracteresBusqueda;

/// Los pacientes que coinciden con [texto], cada uno una sola vez y de la A
/// a la Z (F-01).
///
/// El nombre se busca por cualquier parte, del nombre o de los apellidos, sin
/// distinguir mayúsculas ni tildes. El documento se busca por el número
/// completo. Con menos de 3 caracteres no se busca y devuelve una lista
/// vacía.
List<PacienteEnSeguimiento> buscarPacientes(
  Iterable<PacienteEnSeguimiento> todos,
  String texto,
) {
  if (!busquedaValida(texto)) return const [];
  final buscado = normalizarTexto(texto);
  final vistos = <String>{};
  final encontrados =
      [
        for (final p in todos)
          if ((normalizarTexto(p.nombre).contains(buscado) ||
                  p.numeroDocumento == buscado) &&
              vistos.add(p.id))
            p,
      ]..sort(
        (a, b) =>
            normalizarTexto(a.nombre).compareTo(normalizarTexto(b.nombre)),
      );
  return List.unmodifiable(encontrados);
}
