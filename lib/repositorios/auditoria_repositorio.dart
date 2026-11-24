import 'package:red_vitalys/modelos/modelos.dart';

/// Dónde se guardan los eventos de auditoría (AD-02, AD-03).
///
/// Solo se agrega y se lee: no hay forma de editar ni de borrar un evento
/// (AD-08). Si [agregar] falla, el evento no quedó guardado y quien lo pidió
/// no debe ejecutar la acción (AD-07).
abstract interface class AuditoriaRepositorio {
  /// `true` si los eventos viven en Supabase y hay que leerlos de ahí.
  bool get esRemoto;

  Future<void> agregar(EventoAuditoria evento);

  /// Todos los eventos, del más reciente al más antiguo.
  Future<List<EventoAuditoria>> listar();
}
