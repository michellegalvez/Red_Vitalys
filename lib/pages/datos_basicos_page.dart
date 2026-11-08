import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Datos básicos de un paciente, para el administrativo (F-03, RF-03).
///
/// No incluye atenciones, diagnósticos, riesgo de reingreso ni los
/// identificadores de los sistemas de origen: esos son de la historia clínica,
/// que solo ve el médico. Solo muestra y avisa: volver lo decide la Screen
/// anfitriona.
class DatosBasicosPage extends StatelessWidget {
  const DatosBasicosPage({
    super.key,
    required this.paciente,
    required this.propositoTexto,
    required this.fechaConsulta,
    required this.onVolver,
  });

  /// Solo se usan sus datos básicos: nunca su historia ni su riesgo.
  final Patient paciente;
  final String propositoTexto;
  final String fechaConsulta;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    final iniciales = [
      for (final parte in p.fullName.split(' ').take(2)) parte[0],
    ].join();
    return ContenidoPagina(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onVolver,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text('Buscar pacientes  /  ${p.fullName}'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AvatarIniciales(
                      iniciales: iniciales,
                      indiceColor: indiceColorDe(p.id.replaceAll('pac-', '')),
                      tamano: 60,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DATOS BÁSICOS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: ColoresVitalys.primario,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            header: true,
                            child: Text(
                              p.fullName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ColoresVitalys.borde),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Campo('Edad y sexo', '${p.age} años · ${p.sex}'),
                      _Campo('Documento', p.documentDisplay),
                      _Campo('Fecha de nacimiento', formatoFecha(p.birthDate)),
                      _Campo('Dirección', p.address, ultimo: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Aviso(
                  tipo: TipoAviso.informativo,
                  texto:
                      'Su rol ve los datos básicos. La historia clínica y el '
                      'riesgo de reingreso son solo del médico.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta consulta queda registrada · Propósito: '
                  '$propositoTexto · $fechaConsulta',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ColoresVitalys.textoSuave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo(this.etiqueta, this.valor, {this.ultimo = false});

  final String etiqueta;
  final String valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: ColoresVitalys.textoSuave,
            ),
          ),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
