import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/repositorios/auditoria_repositorio.dart';

class AuditoriaMemoria implements AuditoriaRepositorio {
  AuditoriaMemoria([Iterable<EventoAuditoria> iniciales = const []])
    : _eventos = [...iniciales];

  final List<EventoAuditoria> _eventos;

  @override
  bool get esRemoto => false;

  @override
  Future<void> agregar(EventoAuditoria evento) async => _eventos.add(evento);

  @override
  Future<List<EventoAuditoria>> listar() async => [
    for (final e in _eventos.reversed) e,
  ];
}
