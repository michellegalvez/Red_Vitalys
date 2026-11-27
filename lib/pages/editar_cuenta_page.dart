import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/barra_volver.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pagina.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Cambiar el rol, las sedes y si una cuenta está activa (F-24, RF-40). Solo
/// guarda lo que se está eligiendo; guardar lo decide la Screen anfitriona con
/// [onGuardar], que devuelve el mensaje de error o `null` si se guardó.
class EditarCuentaPage extends StatefulWidget {
  const EditarCuentaPage({
    super.key,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.sedesAsignadas,
    required this.activa,
    required this.sedes,
    required this.onGuardar,
    required this.onVolver,
  });

  final String nombre;
  final String correo;
  final Rol? rol;
  final List<String> sedesAsignadas;
  final bool activa;

  /// Todas las sedes de la red, para asignarlas.
  final List<Sede> sedes;
  final Future<String?> Function({
    required Rol rol,
    required List<String> sedes,
    required bool activa,
  })
  onGuardar;
  final VoidCallback onVolver;

  @override
  State<EditarCuentaPage> createState() => _EditarCuentaPageState();
}

class _EditarCuentaPageState extends State<EditarCuentaPage> {
  late Rol? _rol = widget.rol;
  late final Set<String> _sedes = {...widget.sedesAsignadas};
  late bool _activa = widget.activa;
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    final rol = _rol;
    if (_guardando || rol == null) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await widget.onGuardar(
      rol: rol,
      sedes: [
        for (final s in widget.sedes)
          if (_sedes.contains(s.id)) s.id,
      ],
      activa: _activa,
    );
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Atrás vuelve a la lista, salvo mientras se guarda: así no se pierde lo
    // elegido si falla.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (hizoPop, _) {
        if (!hizoPop && !_guardando) widget.onVolver();
      },
      child: ContenidoPagina(
        children: [
          BarraVolver(
            texto: 'Usuarios  /  ${widget.nombre}',
            onPressed: _guardando ? () {} : widget.onVolver,
          ),
          const SizedBox(height: 8),
          EncabezadoPagina(
            sobretitulo: 'Cuenta',
            titulo: widget.nombre,
            subtitulo: widget.correo,
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: TarjetaVitalys(
                // Las casillas y el interruptor pintan sobre su propia
                // superficie dentro de la tarjeta.
                child: Material(
                  type: MaterialType.transparency,
                  child: _formulario(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorVitalys<Rol>(
          etiqueta: 'Rol',
          hint: 'Elija un rol',
          opciones: [for (final r in Rol.values) (r, r.nombre)],
          valor: _rol,
          onChanged: _guardando ? null : (r) => setState(() => _rol = r),
        ),
        const SizedBox(height: 18),
        Text('Sedes', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text(
          'Las sedes desde las que puede ingresar.',
          style: TextStyle(color: ColoresVitalys.textoSecundario),
        ),
        const SizedBox(height: 6),
        for (final s in widget.sedes)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _sedes.contains(s.id),
            title: Text(s.nombre),
            onChanged: _guardando
                ? null
                : (marcada) => setState(
                    () => marcada == true
                        ? _sedes.add(s.id)
                        : _sedes.remove(s.id),
                  ),
          ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Cuenta activa'),
          subtitle: const Text('Una cuenta desactivada no puede ingresar.'),
          value: _activa,
          onChanged: _guardando ? null : (v) => setState(() => _activa = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Aviso(tipo: TipoAviso.errores, texto: _error!),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: [
            BotonVitalys(
              texto: 'Cancelar',
              variante: VarianteBoton.secundario,
              onPressed: _guardando ? null : widget.onVolver,
            ),
            BotonVitalys(
              texto: _guardando ? 'Guardando…' : 'Guardar',
              icono: Icons.check_rounded,
              onPressed: _guardando || _rol == null ? null : _guardar,
            ),
          ],
        ),
      ],
    );
  }
}
