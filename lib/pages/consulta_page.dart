import 'package:flutter/material.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Acceso denegado (F-18): al abrir a un paciente o al registrarle una
/// atención, muestra el mensaje de la causa sin ningún dato del paciente. Si
/// el rechazo es por falta de relación, ofrece declarar *Urgencia* (F-17).
///
/// Solo muestra y avisa: volver y declarar *Urgencia* lo decide la Screen
/// anfitriona. La historia cuando sí se permite la muestra `PacientePage`.
class ConsultaPage extends StatelessWidget {
  const ConsultaPage({
    super.key,
    required this.resultado,
    required this.onVolver,
    required this.onDeclararUrgencia,
  });

  final ResultadoConsulta resultado;
  final VoidCallback onVolver;

  /// Solo se ofrece cuando el rechazo es por falta de relación.
  final VoidCallback onDeclararUrgencia;

  @override
  Widget build(BuildContext context) {
    final mensaje = resultado.mensaje ?? '';
    final sinRelacion = resultado == ResultadoConsulta.rechazoRelacion;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onVolver,
        ),
        title: const Text(
          'Acceso denegado',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ContenidoPagina(
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
                        texto: 'Volver',
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
      ),
    );
  }
}
