import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/widgets/bloque_inicio.dart';
import 'package:red_vitalys/widgets/carga.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Inicio del médico: el resumen del día y los pacientes que más
/// prioridad tienen (F-06). Solo muestra y avisa por callbacks.
class InicioPage extends StatelessWidget {
  const InicioPage({
    super.key,
    required this.fecha,
    required this.saludo,
    required this.totalConAlerta,
    required this.totalEnSeguimiento,
    required this.indicadoresQueEmpeoraron,
    required this.totalIndicadores,
    required this.prioridad,
    required this.nombresSedes,
    required this.onVerConAlerta,
    required this.onVerTodos,
    required this.onVerIndicadores,
    required this.onAbrirPaciente,
    this.simularFallas = false,
  });

  final String fecha;
  final String saludo;
  final int totalConAlerta;
  final int totalEnSeguimiento;
  final int indicadoresQueEmpeoraron;
  final int totalIndicadores;
  final List<PacienteEnSeguimiento> prioridad;

  /// Nombre corto de cada sede por su id.
  final Map<String, String> nombresSedes;

  final VoidCallback onVerConAlerta;
  final VoidCallback onVerTodos;
  final VoidCallback onVerIndicadores;
  final ValueChanged<PacienteEnSeguimiento> onAbrirPaciente;

  /// Modo demo: muestra la carga y su error con *Reintentar*.
  final bool simularFallas;

  @override
  Widget build(BuildContext context) {
    return ContenidoPagina(
      children: [
        EncabezadoPagina(
          sobretitulo: fecha,
          titulo: saludo,
          subtitulo:
              'Estos son los pacientes que más necesitan su atención hoy.',
        ),
        const SizedBox(height: 26),
        RejillaTarjetas(
          children: [
            BloqueInicio(
              valor: '$totalConAlerta',
              titulo: 'Pacientes con alerta',
              detalle: 'Riesgo de reingreso desde 70',
              tono: TonoBloque.alerta,
              onTap: onVerConAlerta,
            ),
            BloqueInicio(
              valor: '$indicadoresQueEmpeoraron',
              titulo: 'Indicadores que empeoraron',
              detalle: 'frente al mes previo, de $totalIndicadores',
              tono: TonoBloque.naranja,
              onTap: onVerIndicadores,
            ),
            BloqueInicio(
              valor: '$totalEnSeguimiento',
              titulo: 'En seguimiento',
              detalle: 'Altas de los últimos 30 días',
              tono: TonoBloque.menta,
              onTap: onVerTodos,
            ),
          ],
        ),
        const SizedBox(height: 34),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Prioridad de hoy',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            TextButton(
              onPressed: onVerTodos,
              child: const Text(
                'Ver todos →',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CargaSimulada(
          simular: simularFallas,
          textoCargando: 'Cargando pacientes…',
          textoError: 'No se pudo cargar la lista',
          child: prioridad.isEmpty
              ? const EstadoVacio(
                  titulo: 'Hoy no hay pacientes con alerta.',
                  icono: Icons.check_circle_outline_rounded,
                )
              : RejillaTarjetas(
                  children: [
                    for (var i = 0; i < prioridad.length; i++)
                      TarjetaPaciente(
                        paciente: prioridad[i],
                        sedeAlta: nombresSedes[prioridad[i].sedeAltaId] ?? '',
                        onTap: () => onAbrirPaciente(prioridad[i]),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
