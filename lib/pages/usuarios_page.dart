import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/reglas/cuentas.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/carga.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Una cuenta como la muestra la lista de usuarios.
typedef CuentaVista = ({
  String id,
  String nombre,
  String correo,
  String rol,
  String sedes,
  bool activa,
  bool pendiente,
});

/// Las cuentas que gestiona el director (F-24, RF-40), primero las pendientes.
/// Solo muestra y avisa: qué cuenta se abre lo decide la Screen anfitriona.
class UsuariosPage extends StatelessWidget {
  const UsuariosPage({
    super.key,
    required this.cuentas,
    required this.soloPendientes,
    required this.onFiltrar,
    required this.onElegir,
    this.cargando = false,
    this.hayError = false,
    this.onReintentar,
  });

  final List<CuentaVista> cuentas;
  final bool soloPendientes;
  final ValueChanged<bool> onFiltrar;
  final ValueChanged<String> onElegir;
  final bool cargando;
  final bool hayError;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final visibles = [
      for (final c in cuentas)
        if (!soloPendientes || c.pendiente) c,
    ];
    final pendientes = cuentas.where((c) => c.pendiente).length;
    return ContenidoPagina(
      children: [
        const EncabezadoPagina(
          sobretitulo: 'Dirección · Cuentas',
          titulo: 'Usuarios',
          subtitulo:
              'Apruebe las cuentas nuevas asignándoles un rol y sus sedes, y '
              'cambie o desactive las demás. Cada cambio queda registrado.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FiltroPildora(
              texto: 'Todas',
              seleccionado: !soloPendientes,
              onTap: () => onFiltrar(false),
            ),
            FiltroPildora(
              texto: 'Pendientes ($pendientes)',
              seleccionado: soloPendientes,
              onTap: () => onFiltrar(true),
            ),
          ],
        ),
        const SizedBox(height: 18),
        CargaRemota(
          cargando: cargando,
          hayError: hayError,
          onReintentar: onReintentar ?? () {},
          textoCargando: 'Cargando usuarios…',
          textoError: mensajeFallaCuentas,
          child: visibles.isEmpty
              ? EstadoVacio(
                  titulo: soloPendientes
                      ? mensajeSinPendientes
                      : 'No hay cuentas.',
                  icono: Icons.how_to_reg_outlined,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final c in visibles)
                      _Cuenta(cuenta: c, onTap: () => onElegir(c.id)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Cuenta extends StatelessWidget {
  const _Cuenta({required this.cuenta, required this.onTap});

  final CuentaVista cuenta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = cuenta;
    final estado = c.pendiente
        ? 'Pendiente'
        : (c.activa ? 'Activa' : 'Desactivada');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: '${c.nombre}, ${c.correo}, $estado. Abrir',
        excludeSemantics: true,
        child: Material(
          color: ColoresVitalys.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: c.pendiente
                  ? ColoresVitalys.primario
                  : ColoresVitalys.borde,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      ChipVitalys(
                        texto: estado,
                        colorFondo: c.pendiente
                            ? ColoresVitalys.fondoLavanda
                            : (c.activa
                                  ? ColoresVitalys.fondo
                                  : ColoresVitalys.borde),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.correo,
                    style: const TextStyle(
                      color: ColoresVitalys.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.pendiente
                        ? 'Sin rol asignado ni sedes'
                        : '${c.rol} · ${c.sedes}',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El nombre que se muestra para un rol en la lista.
String nombreDeRol(Rol? rol) => rol?.nombre ?? 'Sin rol';
