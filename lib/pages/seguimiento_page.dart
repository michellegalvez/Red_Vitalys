import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Pacientes en seguimiento: las altas de los últimos 30 días de toda la
/// red, del mayor al menor riesgo (F-06). La búsqueda la aplica la Screen.
///
/// No filtra por sede ni por riesgo: F-06 lo deja fuera de alcance.
class SeguimientoPage extends StatelessWidget {
  const SeguimientoPage({
    super.key,
    required this.pacientes,
    required this.busqueda,
    required this.ayudaBusqueda,
    required this.nombresSedes,
    required this.mensajeVacio,
    required this.onBuscar,
    required this.onAbrirPaciente,
  });

  /// Ya buscados y ordenados.
  final List<PacienteEnSeguimiento> pacientes;
  final String busqueda;
  final String? ayudaBusqueda;
  final Map<String, String> nombresSedes;
  final String mensajeVacio;

  final ValueChanged<String> onBuscar;
  final ValueChanged<PacienteEnSeguimiento> onAbrirPaciente;

  @override
  Widget build(BuildContext context) {
    final cantidad = pacientes.length;
    return ContenidoPagina(
      children: [
        const EncabezadoPagina(
          sobretitulo: 'Seguimiento posterior al alta',
          titulo: 'Pacientes en seguimiento',
          subtitulo:
              'Con alta en los últimos 30 días, de mayor a menor riesgo de '
              'reingreso.',
        ),
        const SizedBox(height: 26),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Buscador(
            hint: 'Buscar por nombre o documento',
            valor: busqueda,
            ayuda: ayudaBusqueda,
            onChanged: onBuscar,
          ),
        ),
        const SizedBox(height: 26),
        if (pacientes.isEmpty)
          _Vacio(mensaje: mensajeVacio)
        else
          RejillaTarjetas(
            children: [
              for (var i = 0; i < pacientes.length; i++)
                TarjetaPaciente(
                  paciente: pacientes[i],
                  sedeAlta: nombresSedes[pacientes[i].sedeAltaId] ?? '',
                  onTap: () => onAbrirPaciente(pacientes[i]),
                ),
            ],
          ),
        const SizedBox(height: 26),
        Semantics(
          liveRegion: true,
          child: Text(
            cantidad == 1 ? '1 paciente' : '$cantidad pacientes',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
        ),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColoresVitalys.borde),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: ColoresVitalys.textoSuave,
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ],
      ),
    );
  }
}
