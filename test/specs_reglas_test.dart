import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';

PacienteEnSeguimiento _paciente(
  String id,
  String nombre, {
  int riesgo = 75,
  DateTime? alta,
}) => PacienteEnSeguimiento(
  id: id,
  nombre: nombre,
  iniciales: 'XX',
  edad: 60,
  sexo: 'M',
  tipoDocumento: 'CC',
  numeroDocumento: '1000$id',
  sedeAltaId: 's1',
  tipoAtencion: TipoAtencion.hospitalizacion,
  fechaAlta: alta ?? DateTime(2026, 10, 20),
  diasEstancia: 3,
  riesgo: riesgo,
);

void main() {
  final hoy = DateTime(2026, 11, 6, 10, 42);

  group('Lista de alta reciente (F-06)', () {
    test('con el mismo riesgo y la misma alta va primero el nombre que sigue el alfabeto (CA-14)', () {
      final lista = pacientesConAltaReciente([
        _paciente('1', 'Óscar Zapata'),
        _paciente('2', 'Álvaro Mejía'),
        _paciente('3', 'Beatriz Soto'),
      ], hoy);
      expect(lista.map((p) => p.nombre), [
        'Álvaro Mejía',
        'Beatriz Soto',
        'Óscar Zapata',
      ]);
    });

    test('el riesgo y el alta más reciente siguen mandando antes del nombre (CA-5)', () {
      final lista = pacientesConAltaReciente([
        _paciente('1', 'Ana', alta: DateTime(2026, 10, 10)),
        _paciente('2', 'Zoila', alta: DateTime(2026, 10, 25)),
        _paciente('3', 'Beto', riesgo: 90),
      ], hoy);
      expect(lista.map((p) => p.nombre), ['Beto', 'Zoila', 'Ana']);
    });
  });
}
