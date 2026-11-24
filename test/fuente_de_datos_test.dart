import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/datos/datos_simulados.dart';
import 'package:red_vitalys/datos/fuente_de_datos.dart';

void main() {
  test('con Supabase listo, la fuente sigue siendo la de memoria', () {
    expect(
      elegirFuenteDeDatos(supabaseListo: true),
      same(DatosSimulados.porDefecto),
    );
  });

  test('sin Supabase, la fuente es la de memoria', () {
    expect(
      elegirFuenteDeDatos(supabaseListo: false),
      same(DatosSimulados.porDefecto),
    );
  });

  test('sin cliente de Supabase, la auditoría es la de memoria', () async {
    final auditoria = elegirAuditoria(datos: DatosSimulados.porDefecto);
    expect(auditoria.esRemoto, isFalse);
    final eventos = await auditoria.listar();
    expect(eventos.length, DatosSimulados.porDefecto.eventos.length);
  });
}
