import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/carga.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/perfil.dart';

/// Nota del perfil sobre la sede y el propósito (F-22 paso 4).
const String notaPerfil =
    'El acceso también depende de la sede desde la que ingresó y del '
    'propósito que declare en cada consulta.';

/// Perfil (F-22): los datos de la cuenta, la sede de la sesión, lo que el
/// rol puede hacer según la tabla de permisos de F-18 y los propósitos que
/// puede declarar. Ofrece *Cerrar sesión* (F-23).
///
/// Solo muestra lo que le pasa la Screen y avisa con [onCerrarSesion].
class PerfilPage extends StatelessWidget {
  const PerfilPage({
    super.key,
    required this.datos,
    required this.permisos,
    required this.propositos,
    required this.onCerrarSesion,
    this.simularFallas = false,
    this.cerrandoSesion = false,
    this.errorCierre,
  });

  final List<DatoPerfil> datos;
  final List<PermisoPerfil> permisos;
  final List<String> propositos;
  final VoidCallback onCerrarSesion;

  /// Modo demo: muestra "Cargando perfil…" y su error con *Reintentar*.
  final bool simularFallas;

  /// Está cerrando la sesión (F-23): el botón queda deshabilitado.
  final bool cerrandoSesion;

  /// Por qué no se pudo cerrar la sesión, si falló (F-23).
  final String? errorCierre;

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    final botonCerrar = BotonVitalys(
      texto: cerrandoSesion ? 'Cerrando sesión…' : 'Cerrar sesión',
      icono: Icons.logout_rounded,
      variante: VarianteBoton.secundario,
      onPressed: cerrandoSesion ? null : onCerrarSesion,
    );
    final cuenta = [
      TarjetaDatosPerfil(datos: datos),
      const SizedBox(height: 18),
      const Text(
        notaPerfil,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: ColoresVitalys.textoSecundario,
        ),
      ),
      const SizedBox(height: 18),
      Align(alignment: Alignment.centerLeft, child: botonCerrar),
    ];
    final rol = [
      const _Titulo('Qué puede hacer con su rol'),
      const SizedBox(height: 14),
      ListaPermisos(permisos: permisos),
      const SizedBox(height: 28),
      const _Titulo('Propósitos que puede declarar'),
      const SizedBox(height: 14),
      ChipsPropositos(
        propositos: propositos,
        mensajeVacio: 'Su rol no declara propósitos.',
      ),
    ];

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (escritorio)
          // En computador: una sola columna angosta a la izquierda, con los
          // datos en 3 columnas (Figma, pantalla 9).
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TarjetaDatosPerfil(datos: datos, columnas: 3),
                  const SizedBox(height: 40),
                  ...rol,
                  const SizedBox(height: 22),
                  ...cuenta.skip(2),
                ],
              ),
            ),
          )
        else ...[
          // En celular: la cuenta, lo que puede hacer y, al final, la nota
          // y el cierre de sesión, como en el Figma.
          cuenta.first,
          const SizedBox(height: 30),
          ...rol,
          const SizedBox(height: 24),
          ...cuenta.skip(2),
        ],
      ],
    );
    return ContenidoPagina(
      children: [
        const EncabezadoPagina(sobretitulo: 'Su cuenta', titulo: 'Perfil'),
        if (errorCierre != null) ...[
          const SizedBox(height: 14),
          Aviso(tipo: TipoAviso.errores, texto: errorCierre!),
        ],
        const SizedBox(height: 24),
        CargaSimulada(
          simular: simularFallas,
          textoCargando: 'Cargando perfil…',
          textoError: 'No se pudo cargar su perfil',
          accionesEnError: [botonCerrar],
          child: contenido,
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(texto, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
