import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/formato/hora_colombia.dart';

// Las fechas de la base se leen con la hora de Colombia (UTC-5, la de
// America/Bogota en la base), sin depender de la zona del equipo.

void main() {
  test('un alta a las 22:00 de Colombia es de ese día aunque en UTC ya sea '
      'el siguiente', () {
    expect(diaColombia('2026-11-02T03:00:00+00:00'), DateTime(2026, 11, 1));
    expect(diaColombia('2026-11-02T05:00:00Z'), DateTime(2026, 11, 2));
  });

  test('la hora de un evento es la de Colombia', () {
    expect(
      horaColombia('2026-11-27T15:04:05.123+00:00'),
      DateTime(2026, 11, 27, 10, 4, 5, 123),
    );
  });

  test('una fecha del formulario va a la base como hora de Colombia', () {
    expect(textoColombia(DateTime(2026, 11, 5)), '2026-11-05T00:00:00-05:00');
    expect(
      textoColombia(DateTime(2026, 1, 9, 7, 3)),
      '2026-01-09T07:03:00-05:00',
    );
  });
}
