import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/historia.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/foco.dart';

/// El ícono de cada tipo de atención (F-02, F-04).
IconData iconoTipoAtencion(EncounterType tipo) => switch (tipo) {
  EncounterType.hospitalizacion => Icons.local_hospital_outlined,
  EncounterType.urgencias => Icons.emergency_outlined,
  EncounterType.consultaExterna => Icons.medical_services_outlined,
};

/// El nombre de cada tipo de atención.
String nombreTipoAtencion(EncounterType tipo) => switch (tipo) {
  EncounterType.hospitalizacion => 'Hospitalización',
  EncounterType.urgencias => 'Urgencias',
  EncounterType.consultaExterna => 'Consulta externa',
};

/// Tres tarjetas para elegir el tipo de atención (F-04). No trae ninguna
/// elegida: el médico decide. En pantallas angostas van una bajo la otra.
class SelectorTipoAtencion extends StatelessWidget {
  const SelectorTipoAtencion({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final EncounterType? valor;

  /// Sin `onChanged` las tarjetas quedan deshabilitadas.
  final ValueChanged<EncounterType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final tarjetas = [
          for (final t in EncounterType.values)
            _TarjetaTipo(
              tipo: t,
              seleccionada: valor == t,
              onTap: onChanged == null ? null : () => onChanged!(t),
            ),
        ];
        if (c.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tarjetas.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                tarjetas[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < tarjetas.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: tarjetas[i]),
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaTipo extends StatelessWidget {
  const _TarjetaTipo({
    required this.tipo,
    required this.seleccionada,
    required this.onTap,
  });

  final EncounterType tipo;
  final bool seleccionada;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = seleccionada
        ? ColoresVitalys.primario
        : ColoresVitalys.textoSecundario;
    return Semantics(
      selected: seleccionada,
      button: true,
      enabled: onTap != null,
      child: AnilloFoco(
        radio: BorderRadius.circular(16),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: seleccionada ? ColoresVitalys.fondoLavanda : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: seleccionada
                    ? ColoresVitalys.primario
                    : ColoresVitalys.textoSuave.withValues(alpha: 0.4),
                width: seleccionada ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(iconoTipoAtencion(tipo), color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nombreTipoAtencion(tipo),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: seleccionada
                          ? ColoresVitalys.primario
                          : ColoresVitalys.tinta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
