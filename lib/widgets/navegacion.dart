import 'package:flutter/material.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/foco.dart';
import 'package:red_vitalys/widgets/marca.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Desde este ancho los destinos de la barra superior llevan texto.
const double _anchoDestinosCompletos = 1100;

/// Un destino de la navegación: su ícono y su nombre.
typedef DestinoNavegacion = ({IconData icono, String nombre});

/// Barra superior de la galería. En escritorio lleva también los destinos;
/// en celular los destinos van en la [BarraInferior].
class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const BarraSuperior({
    super.key,
    required this.iniciales,
    required this.nombreUsuario,
    required this.sede,
    required this.detalleUsuario,
    required this.onPerfil,
    required this.onSalir,
    this.destinos = const [],
    this.indiceActual = 0,
    this.onDestino,
  });

  final String iniciales;
  final String nombreUsuario;
  final String sede;

  /// Rol y sede, por ejemplo "Médico · Cali Norte", para el menú.
  final String detalleUsuario;
  final VoidCallback onPerfil;
  final VoidCallback onSalir;
  final List<DestinoNavegacion> destinos;
  final int indiceActual;
  final ValueChanged<int>? onDestino;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final escritorio = ancho >= anchoEscritorio;

    // Entre 900 y 1100 px los destinos solo muestran el ícono.
    final soloIconos = ancho < _anchoDestinosCompletos;
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ColoresVitalys.borde)),
          ),
          padding: EdgeInsets.symmetric(horizontal: escritorio ? 32 : 16),
          child: Row(
            children: [
              const MarcaRedVitalys(tamano: 32),
              Expanded(
                child: escritorio
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < destinos.length; i++)
                            _EnlaceDestino(
                              destino: destinos[i],
                              activo: i == indiceActual,
                              soloIcono: soloIconos,
                              onTap: () => onDestino?.call(i),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              if (escritorio)
                // Ancho máximo: los destinos se quedan con el resto.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ChipVitalys(
                      texto: sede,
                      icono: Icons.location_on_outlined,
                      colorFondo: ColoresVitalys.fondoMenta,
                      colorTexto: ColoresVitalys.mentaTexto,
                    ),
                  ),
                ),
              MenuUsuario(
                iniciales: iniciales,
                nombreUsuario: nombreUsuario,
                sede: detalleUsuario,
                onPerfil: onPerfil,
                onSalir: onSalir,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnlaceDestino extends StatelessWidget {
  const _EnlaceDestino({
    required this.destino,
    required this.activo,
    required this.onTap,
    required this.soloIcono,
  });

  final DestinoNavegacion destino;
  final bool activo;
  final VoidCallback onTap;
  final bool soloIcono;

  @override
  Widget build(BuildContext context) {
    final color = activo
        ? ColoresVitalys.primario
        : ColoresVitalys.textoSecundario;
    final enlace = Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        selected: activo,
        button: true,
        label: destino.nombre,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: AnilloFoco(
            child: Material(
              color: activo ? ColoresVitalys.fondoLavanda : Colors.transparent,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: soloIcono ? 14 : 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(destino.icono, size: 20, color: color),
                      if (!soloIcono) ...[
                        const SizedBox(width: 8),
                        Text(
                          destino.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return soloIcono ? Tooltip(message: destino.nombre, child: enlace) : enlace;
  }
}

enum _OpcionMenu { perfil, salir }

/// Menú de usuario de la galería: el avatar abre *Mi perfil* y *Cerrar sesión*.
class MenuUsuario extends StatelessWidget {
  const MenuUsuario({
    super.key,
    required this.iniciales,
    required this.nombreUsuario,
    required this.sede,
    required this.onPerfil,
    required this.onSalir,
  });

  final String iniciales;
  final String nombreUsuario;
  final String sede;
  final VoidCallback onPerfil;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton<_OpcionMenu>(
      tooltip: 'Menú de usuario',
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      onSelected: (o) => switch (o) {
        _OpcionMenu.perfil => onPerfil(),
        _OpcionMenu.salir => onSalir(),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreUsuario,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ColoresVitalys.tinta,
                ),
              ),
              Text(
                sede,
                style: const TextStyle(
                  fontSize: 13,
                  color: ColoresVitalys.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _OpcionMenu.perfil,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline_rounded),
            title: Text('Mi perfil'),
          ),
        ),
        const PopupMenuItem(
          value: _OpcionMenu.salir,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded, color: ColoresVitalys.alerta),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: ColoresVitalys.alertaTexto),
            ),
          ),
        ),
      ],
      child: AvatarIniciales(
        iniciales: iniciales,
        tamano: 48,
        fondo: ColoresVitalys.primario,
        colorTexto: Colors.white,
      ),
    );
    return AnilloFoco(child: menu);
  }
}

/// Barra inferior de la galería, solo en celular.
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.destinos,
    required this.indiceActual,
    required this.onDestino,
  });

  final List<DestinoNavegacion> destinos;
  final int indiceActual;
  final ValueChanged<int> onDestino;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: ColoresVitalys.fondoLavanda,
      surfaceTintColor: Colors.transparent,
      selectedIndex: indiceActual,
      onDestinationSelected: onDestino,
      destinations: [
        for (final d in destinos)
          NavigationDestination(
            icon: Icon(d.icono),
            selectedIcon: Icon(d.icono, color: ColoresVitalys.primario),
            label: d.nombre,
          ),
      ],
    );
  }
}
