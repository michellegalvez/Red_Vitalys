import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/busqueda.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Buscar pacientes por nombre o documento (F-01). Solo muestra el nombre y
/// el documento, ningún dato clínico. La búsqueda y lo que se abre al elegir
/// un paciente lo decide la Screen anfitriona.
class BuscarPacientesPage extends StatelessWidget {
  const BuscarPacientesPage({
    super.key,
    required this.busqueda,
    required this.resultados,
    required this.accionAlElegir,
    required this.onBuscar,
    required this.onElegir,
  });

  final String busqueda;

  /// Ya buscados y ordenados de la A a la Z.
  final List<PacienteEnSeguimiento> resultados;

  /// Lo que pasa al elegir uno, según el rol: "Abrir la historia clínica" o
  /// "Ver los datos básicos".
  final String accionAlElegir;
  final ValueChanged<String> onBuscar;
  final ValueChanged<PacienteEnSeguimiento> onElegir;

  @override
  Widget build(BuildContext context) {
    final texto = busqueda.trim();
    final corto = texto.isNotEmpty && !busquedaValida(texto);
    final buscando = busquedaValida(texto);
    return ContenidoPagina(
      children: [
        const EncabezadoPagina(
          sobretitulo: 'Pacientes de toda la red',
          titulo: 'Buscar pacientes',
          subtitulo:
              'Escriba un nombre, un apellido o el número de documento '
              'completo. Se busca sin distinguir mayúsculas ni tildes.',
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Buscador(
              hint: 'Buscar por nombre o documento',
              valor: busqueda,
              ayuda: corto ? mensajeBusquedaCorta : null,
              onChanged: onBuscar,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (!buscando && !corto)
          const _Pista()
        else if (buscando) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              resultados.length == 1
                  ? '1 paciente'
                  : '${resultados.length} pacientes',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: ColoresVitalys.textoSecundario,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (resultados.isEmpty)
            const _SinResultados()
          else
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    for (final p in resultados)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _Resultado(
                          paciente: p,
                          accion: accionAlElegir,
                          onTap: () => onElegir(p),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.paciente,
    required this.accion,
    required this.onTap,
  });

  final PacienteEnSeguimiento paciente;
  final String accion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    return Semantics(
      button: true,
      label: '${p.nombre}, ${p.tipoDocumento} ${p.numeroDocumento}. $accion',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ColoresVitalys.borde),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AvatarIniciales(
                  iniciales: p.iniciales,
                  indiceColor: indiceColorDe(p.id),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.tipoDocumento} ${p.numeroDocumento}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColoresVitalys.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ColoresVitalys.textoSuave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pista extends StatelessWidget {
  const _Pista();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.search_rounded, color: ColoresVitalys.textoSuave),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Los resultados salen aquí, con el nombre y el documento.',
            style: TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ),
      ],
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColoresVitalys.borde),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: ColoresVitalys.textoSuave,
          ),
          SizedBox(height: 12),
          Text(
            mensajeSinResultados,
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresVitalys.textoSecundario),
          ),
        ],
      ),
    );
  }
}
