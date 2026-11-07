import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Lo que se ve al abrir a un paciente con el propósito ya declarado.
///
/// Si se permite, abre la entrada a su historia y su riesgo, que arman
/// otros integrantes (F-02, F-07), con el aviso de emergencia si se
/// declaró *Urgencia* (F-17). Si se rechaza, muestra el mensaje de la causa
/// sin ningún dato del paciente (F-18).
class ConsultaPage extends StatelessWidget {
  const ConsultaPage({
    super.key,
    required this.resultado,
    required this.paciente,
    required this.proposito,
    required this.sedeAlta,
    required this.onVolver,
    required this.onDeclararUrgencia,
  });

  final ResultadoConsulta resultado;
  final PacienteEnSeguimiento paciente;
  final Proposito proposito;
  final String sedeAlta;
  final VoidCallback onVolver;

  /// Solo se ofrece cuando el rechazo es por falta de relación.
  final VoidCallback onDeclararUrgencia;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onVolver,
        ),
        title: Text(
          resultado == ResultadoConsulta.permitido
              ? 'Paciente'
              : 'Acceso denegado',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: resultado == ResultadoConsulta.permitido
          ? _permitido(context)
          : _denegado(context),
    );
  }

  Widget _permitido(BuildContext context) {
    final p = paciente;
    final emergencia = proposito == Proposito.urgencia;
    return ContenidoPagina(
      children: [
        if (emergencia) ...[
          const Aviso(
            tipo: TipoAviso.advertencia,
            texto: avisoAccesoEmergencia,
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            AvatarIniciales(iniciales: p.iniciales, tamano: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      p.nombre,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.edad} años · ${p.sexo} · ${p.documentoOculto} · '
                    '$sedeAlta',
                    style: const TextStyle(
                      color: ColoresVitalys.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Etiqueta(
              icono: Icons.assignment_turned_in_outlined,
              texto: 'Propósito: ${proposito.nombreCorto}',
            ),
            EtiquetaRiesgo(riesgo: p.riesgo),
          ],
        ),
        const SizedBox(height: 24),
        const Aviso(
          tipo: TipoAviso.informativo,
          texto:
              'Aquí se abren la historia clínica unificada y el riesgo de '
              'reingreso con su explicación. Esas pantallas las construye '
              'otro integrante del equipo y se conectan en este punto.',
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: BotonVitalys(
            texto: 'Volver a la lista',
            variante: VarianteBoton.secundario,
            icono: Icons.arrow_back_rounded,
            onPressed: onVolver,
          ),
        ),
      ],
    );
  }

  Widget _denegado(BuildContext context) {
    final mensaje = resultado.mensaje ?? '';
    final sinRelacion = resultado == ResultadoConsulta.rechazoRelacion;
    return ContenidoPagina(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: ColoresVitalys.alertaFondo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: ColoresVitalys.alertaTexto,
                  ),
                ),
                const SizedBox(height: 22),
                Semantics(
                  header: true,
                  child: Text(
                    'No puede abrir este paciente',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
                const SizedBox(height: 10),
                const Text(
                  'El intento quedó registrado en la auditoría de accesos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ColoresVitalys.textoSecundario),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    BotonVitalys(
                      texto: 'Volver a la lista',
                      variante: VarianteBoton.secundario,
                      onPressed: onVolver,
                    ),
                    if (sinRelacion)
                      BotonVitalys(
                        texto: 'Declarar Urgencia',
                        icono: Icons.emergency_outlined,
                        onPressed: onDeclararUrgencia,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ColoresVitalys.fondoLavanda,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: ColoresVitalys.primario),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: ColoresVitalys.primario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
