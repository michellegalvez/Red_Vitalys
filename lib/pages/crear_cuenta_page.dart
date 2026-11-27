import 'package:flutter/material.dart';
import 'package:red_vitalys/reglas/cuentas.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/barra_volver.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/pagina.dart';

/// Crear una cuenta desde el acceso (F-24, RF-39). Solo guarda lo que se está
/// escribiendo; crearla lo decide la Screen anfitriona con [onCrear], que
/// devuelve el mensaje de error o `null` si se creó.
class CrearCuentaPage extends StatefulWidget {
  const CrearCuentaPage({
    super.key,
    required this.onCrear,
    required this.onVolver,
  });

  final Future<String?> Function({
    required String nombre,
    required String correo,
    required String clave,
  })
  onCrear;
  final VoidCallback onVolver;

  @override
  State<CrearCuentaPage> createState() => _CrearCuentaPageState();
}

class _CrearCuentaPageState extends State<CrearCuentaPage> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _repetida = TextEditingController();
  bool _creando = false;
  bool _creada = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _clave.dispose();
    _repetida.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (_creando) return;
    final problema = validarRegistro(
      nombre: _nombre.text,
      correo: _correo.text,
      clave: _clave.text,
      repetida: _repetida.text,
    );
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }
    setState(() {
      _creando = true;
      _error = null;
    });
    final error = await widget.onCrear(
      nombre: _nombre.text.trim(),
      correo: _correo.text.trim(),
      clave: _clave.text,
    );
    if (!mounted) return;
    setState(() {
      _creando = false;
      _error = error;
      _creada = error == null;
      // Las contraseñas no se conservan si algo falla (F-24, Error).
      _clave.clear();
      _repetida.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Atrás vuelve al acceso, salvo mientras se crea la cuenta.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (hizoPop, _) {
        if (!hizoPop && !_creando) widget.onVolver();
      },
      child: ContenidoPagina(
        children: [
          BarraVolver(
            texto: 'Acceso  /  Crear cuenta',
            onPressed: _creando ? () {} : widget.onVolver,
          ),
          const SizedBox(height: 8),
          const EncabezadoPagina(
            sobretitulo: 'Cuenta nueva',
            titulo: 'Crear cuenta',
            subtitulo:
                'Podrá entrar cuando la Dirección le asigne un rol y las sedes '
                'desde las que trabaja.',
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _creada ? _hecho() : _formulario(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hecho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Aviso(tipo: TipoAviso.informativo, texto: mensajeCuentaCreada),
        const SizedBox(height: 18),
        BotonVitalys(
          texto: 'Volver al acceso',
          icono: Icons.arrow_back_rounded,
          variante: VarianteBoton.secundario,
          onPressed: widget.onVolver,
        ),
      ],
    );
  }

  Widget _formulario() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoTexto(
            etiqueta: 'Nombre completo',
            controller: _nombre,
            habilitado: !_creando,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            etiqueta: 'Correo',
            controller: _correo,
            hint: 'nombre@vitalys.co',
            habilitado: !_creando,
            teclado: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            autocorregir: false,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            etiqueta: 'Contraseña',
            ayuda: 'Al menos 8 caracteres.',
            controller: _clave,
            oculto: true,
            habilitado: !_creando,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            etiqueta: 'Repita la contraseña',
            controller: _repetida,
            oculto: true,
            habilitado: !_creando,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _crear(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Aviso(tipo: TipoAviso.errores, texto: _error!),
          ],
          const SizedBox(height: 22),
          BotonVitalys(
            texto: _creando ? 'Creando cuenta…' : 'Crear cuenta',
            icono: Icons.person_add_alt_1_rounded,
            onPressed: _creando ? null : _crear,
          ),
        ],
      ),
    );
  }
}
