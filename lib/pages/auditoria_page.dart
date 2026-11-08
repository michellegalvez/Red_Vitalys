import 'package:flutter/material.dart';
import 'package:red_vitalys/formato/formato.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/reglas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/auditoria.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Auditoría de accesos (F-21): quién accedió, cuándo, a qué recurso, con
/// qué propósito y con qué resultado. Solo el auditor llega aquí.
///
/// Los eventos llegan ya filtrados y ordenados por la Screen; esta Page
/// solo los muestra y avisa cuando se elige otro filtro.
class AuditoriaPage extends StatelessWidget {
  const AuditoriaPage({
    super.key,
    required this.eventos,
    required this.filtro,
    required this.nombresUsuarios,
    required this.nombresPacientes,
    required this.nombresSedes,
    required this.onElegirFiltro,
  });

  final List<EventoAuditoria> eventos;
  final FiltroAuditoria filtro;

  /// Nombre de cada usuario, de cada paciente y de cada sede, por su id.
  final Map<String, String> nombresUsuarios;
  final Map<String, String> nombresPacientes;
  final Map<String, String> nombresSedes;

  final ValueChanged<FiltroAuditoria> onElegirFiltro;

  FilaEvento _fila(EventoAuditoria e) {
    final usuarioId = e.usuarioId;
    final pacienteId = e.pacienteId;
    final sedeId = e.sedeId;
    return (
      fechaHora: formatoFechaHora(e.fechaHora),
      usuario: usuarioId != null
          ? nombresUsuarios[usuarioId] ?? '—'
          : e.correoIntento ?? '—',
      accion: e.accion.nombre,
      recurso: e.recurso.nombre,
      paciente: pacienteId != null ? nombresPacientes[pacienteId] ?? '—' : '—',
      proposito: e.propositoTexto,
      propositoCompleto: e.proposito?.nombre ?? e.propositoTexto,
      emergencia: e.esEmergencia,
      resultado: e.resultado,
      sede: sedeId != null ? nombresSedes[sedeId] ?? '—' : '—',
      ip: e.ip ?? '—',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cantidad = eventos.length;
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    const encabezado = EncabezadoPagina(
      sobretitulo: 'Trazabilidad · Evento de auditoría',
      titulo: 'Auditoría de accesos',
      subtitulo:
          'Quién accedió, cuándo, a qué recurso, con qué resultado y para '
          'qué propósito. Los registros no se pueden editar.',
    );
    final filtros = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in FiltroAuditoria.values)
          FiltroPildora(
            texto: f.nombre,
            seleccionado: f == filtro,
            onTap: () => onElegirFiltro(f),
          ),
      ],
    );
    return ContenidoPagina(
      children: [
        // En computador los filtros van a la derecha del encabezado
        // (Figma, pantalla 8); en celular, debajo.
        if (escritorio)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: encabezado,
                ),
              ),
              const SizedBox(width: 32),
              filtros,
            ],
          )
        else ...[
          encabezado,
          const SizedBox(height: 22),
          filtros,
        ],
        SizedBox(height: escritorio ? 36 : 22),
        TablaEventos(
          filas: [for (final e in eventos) _fila(e)],
          mensajeVacio: mensajeSinEventos,
        ),
        const SizedBox(height: 22),
        Semantics(
          liveRegion: true,
          child: Text(
            cantidad == 1 ? '1 evento' : '$cantidad eventos',
            style: TextStyle(
              fontSize: escritorio ? 15 : 13,
              color: ColoresVitalys.textoSecundario,
            ),
          ),
        ),
      ],
    );
  }
}
