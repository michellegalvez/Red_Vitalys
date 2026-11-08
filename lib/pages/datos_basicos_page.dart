import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/barra_volver.dart';
import 'package:red_vitalys/widgets/campo_dato.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

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
        BarraVolver(
          texto: 'Buscar pacientes  /  ${p.fullName}',
          onPressed: onVolver,
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
                TarjetaVitalys(
                  relleno: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CampoDato(
                        'Edad y sexo',
                        '${p.age} años · ${p.sex}',
                        tamanoValor: 16,
                        separacion: 16,
                      ),
                      CampoDato(
                        'Documento',
                        p.documentDisplay,
                        tamanoValor: 16,
                        separacion: 16,
                      ),
                      CampoDato(
                        'Fecha de nacimiento',
                        formatoFecha(p.birthDate),
                        tamanoValor: 16,
                        separacion: 16,
                      ),
                      CampoDato('Teléfono', p.phone, tamanoValor: 16),
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
