import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/formularios.dart';
import 'package:red_vitalys/widgets/marca.dart';
import 'package:red_vitalys/widgets/pacientes.dart';
import 'package:red_vitalys/widgets/tarjeta.dart';

/// Los dos pasos del inicio de sesión (F-13): primero se validan el correo
/// y la contraseña, y después se elige la sede entre las asignadas.
enum PasoAcceso { credenciales, sede }

/// Un perfil de prueba del prototipo, para llenar el correo con un toque.
typedef PerfilPrototipo = ({String etiqueta, String correo});

/// Inicio de sesión, como en el Figma: correo, contraseña y la sede desde
/// la que se ingresa en un solo formulario (F-13, F-14, F-15). Solo
/// muestra y avisa: el estado vive en la Screen anfitriona.
class AccesoPage extends StatelessWidget {
  const AccesoPage({
    super.key,
    required this.paso,
    required this.correo,
    required this.contrasena,
    required this.ingresando,
    required this.mensajeError,
    required this.avisoInactividad,
    required this.contrasenaPrototipo,
    required this.perfiles,
    required this.usuario,
    required this.sedes,
    required this.sedeElegida,
    required this.errorSede,
    required this.onIngresar,
    required this.onElegirPerfil,
    required this.onElegirSede,
    required this.onConfirmarSede,
    required this.onVolver,
    this.simularFallas = false,
    this.onSimularFallas,
  });

  final PasoAcceso paso;

  final TextEditingController correo;
  final TextEditingController contrasena;
  final bool ingresando;
  final String? mensajeError;
  final String? avisoInactividad;
  final String contrasenaPrototipo;
  final List<PerfilPrototipo> perfiles;

  /// El usuario ya validado. Solo existe en el paso de la sede.
  final Usuario? usuario;

  /// Las sedes asignadas a ese usuario.
  final List<Sede> sedes;
  final String? sedeElegida;
  final String? errorSede;

  final VoidCallback onIngresar;
  final ValueChanged<String> onElegirPerfil;
  final ValueChanged<String?> onElegirSede;
  final VoidCallback onConfirmarSede;
  final VoidCallback onVolver;

  /// Interruptor de demo *Simular fallas de red*.
  final bool simularFallas;
  final ValueChanged<bool>? onSimularFallas;

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    final formulario = _formulario(context);

    if (escritorio) {
      return Scaffold(
        backgroundColor: ColoresVitalys.fondo,
        body: Row(
          children: [
            const Expanded(flex: 23, child: _PanelVisual(escritorio: true)),
            Expanded(
              flex: 21,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: formulario,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: ColoresVitalys.fondo,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelVisual(escritorio: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 36),
              child: formulario,
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final validado = usuario;
    final enSede = paso == PasoAcceso.sede && validado != null;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            enSede ? 'PASO 2 DE 2' : 'ACCESO INSTITUCIONAL',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: ColoresVitalys.primario,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              enSede ? 'Elija su sede' : 'Ingrese a su sesión',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(height: 22),
          if (enSede) ..._pasoSede(validado) else ..._pasoCredenciales(),
          const SizedBox(height: 20),
          const Aviso(
            tipo: TipoAviso.informativo,
            texto:
                'Cada consulta queda registrada con su usuario, sede y '
                'propósito de uso.',
          ),
          if (!enSede) ...[
            const SizedBox(height: 16),
            _AyudaPrototipo(
              contrasena: contrasenaPrototipo,
              perfiles: perfiles,
              onElegir: onElegirPerfil,
              simularFallas: simularFallas,
              onSimularFallas: onSimularFallas,
            ),
          ],
        ],
      ),
    );
  }

  /// Paso 1: el correo y la contraseña. La sede no aparece todavía.
  List<Widget> _pasoCredenciales() {
    return [
      if (avisoInactividad != null) ...[
        Aviso(
          tipo: TipoAviso.informativo,
          texto: avisoInactividad!,
          anunciar: true,
        ),
        const SizedBox(height: 16),
      ],
      if (mensajeError != null) ...[
        Aviso(tipo: TipoAviso.alerta, texto: mensajeError!),
        const SizedBox(height: 16),
      ],
      CampoTexto(
        etiqueta: 'Correo institucional',
        controller: correo,
        hint: 'nombre@vitalys.co',
        teclado: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
        maxLength: 254,
        autocorregir: false,
        soloLectura: ingresando,
      ),
      const SizedBox(height: 18),
      CampoTexto(
        etiqueta: 'Contraseña',
        controller: contrasena,
        // La contraseña no se muestra mientras se escribe (F-13).
        oculto: true,
        autofillHints: const [AutofillHints.password],
        autocorregir: false,
        textInputAction: TextInputAction.done,
        maxLength: 128,
        soloLectura: ingresando,
        onSubmitted: (_) => onIngresar(),
      ),
      const SizedBox(height: 24),
      BotonVitalys(
        texto: ingresando ? 'Ingresando…' : 'Ingresar',
        expandido: true,
        onPressed: ingresando ? null : onIngresar,
      ),
    ];
  }

  /// Paso 2: con los datos ya verificados, la sede entre las asignadas.
  List<Widget> _pasoSede(Usuario validado) {
    return [
      _UsuarioVerificado(usuario: validado),
      const SizedBox(height: 22),
      SelectorVitalys<String>(
        etiqueta: 'Sede desde la que ingresa',
        ayuda: 'Su acceso depende de la sede y queda registrado.',
        hint: 'Elija una sede',
        error: errorSede,
        valor: sedeElegida,
        opciones: [for (final s in sedes) (s.id, s.nombre)],
        onChanged: onElegirSede,
      ),
      const SizedBox(height: 24),
      BotonVitalys(
        texto: 'Confirmar sede',
        icono: Icons.arrow_forward_rounded,
        expandido: true,
        onPressed: onConfirmarSede,
      ),
      const SizedBox(height: 10),
      BotonVitalys(
        texto: 'Volver',
        variante: VarianteBoton.secundario,
        expandido: true,
        onPressed: onVolver,
      ),
    ];
  }
}

/// Tarjeta que confirma que los datos fueron válidos.
class _UsuarioVerificado extends StatelessWidget {
  const _UsuarioVerificado({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(14),
      radio: TarjetaVitalys.radioFila,
      child: Row(
        children: [
          AvatarIniciales(
            iniciales: usuario.iniciales,
            tamano: 46,
            fondo: ColoresVitalys.primario,
            colorTexto: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${usuario.rol.nombre} · ${usuario.correo}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColoresVitalys.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.verified_rounded,
            color: ColoresVitalys.exito,
            semanticLabel: 'Datos verificados',
          ),
        ],
      ),
    );
  }
}

class _AyudaPrototipo extends StatelessWidget {
  const _AyudaPrototipo({
    required this.contrasena,
    required this.perfiles,
    required this.onElegir,
    required this.simularFallas,
    required this.onSimularFallas,
  });

  final String contrasena;
  final List<PerfilPrototipo> perfiles;
  final ValueChanged<String> onElegir;
  final bool simularFallas;
  final ValueChanged<bool>? onSimularFallas;

  @override
  Widget build(BuildContext context) {
    return TarjetaVitalys(
      relleno: const EdgeInsets.all(16),
      radio: TarjetaVitalys.radioFila,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: ColoresVitalys.textoSecundario,
              ),
              children: [
                const TextSpan(
                  text: 'Prototipo sin servidor.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ColoresVitalys.tinta,
                  ),
                ),
                const TextSpan(text: ' Use la contraseña '),
                TextSpan(
                  text: contrasena,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: ColoresVitalys.tinta,
                  ),
                ),
                const TextSpan(text: ' o rellene un perfil:'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in perfiles)
                BotonVitalys(
                  texto: p.etiqueta,
                  variante: VarianteBoton.pequeno,
                  onPressed: () => onElegir(p.correo),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Simular fallas de red',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text(
                'Para la demo: cada pantalla muestra su carga y falla una vez; '
                'Reintentar la carga.',
                style: TextStyle(fontSize: 12.5),
              ),
              value: simularFallas,
              onChanged: onSimularFallas,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel visual del acceso: la marca, el lema y, en escritorio, lo que
/// ofrece la app.
class _PanelVisual extends StatelessWidget {
  const _PanelVisual({required this.escritorio});

  final bool escritorio;

  @override
  Widget build(BuildContext context) {
    final lema = Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Un paciente.\n'),
          TextSpan(
            text: 'Todas',
            style: TextStyle(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [ColoresVitalys.verdeLima, ColoresVitalys.turquesa],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 60)),
            ),
          ),
          const TextSpan(text: ' las sedes.'),
        ],
      ),
      style: TextStyle(
        fontSize: escritorio ? 64 : 34,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: escritorio ? -2.2 : -1.2,
        color: Colors.white,
      ),
    );
    final descripcion = Text(
      'Seis clínicas, cuarenta centros ambulatorios y una cadena de laboratorios, con un '
      'solo paciente, un solo índice y cada acceso auditado.',
      style: TextStyle(
        fontSize: escritorio ? 18 : 14.5,
        height: 1.5,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MarcaRedVitalys(sobreOscuro: true, tamano: 32),
        if (escritorio) const Spacer(flex: 3) else const SizedBox(height: 26),
        lema,
        SizedBox(height: escritorio ? 22 : 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: descripcion,
        ),
        if (escritorio) ...[const Spacer(flex: 2), const _Beneficios()],
      ],
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        escritorio ? 48 : 20,
        escritorio ? 44 : 18,
        escritorio ? 48 : 20,
        escritorio ? 48 : 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColoresVitalys.violetaHeroInicio,
            ColoresVitalys.violetaHeroFin,
            Color(0xFF2F5FD0),
          ],
          stops: [0, 0.65, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: escritorio
            ? LayoutBuilder(
                // Con poca altura el panel se desplaza en vez de desbordar.
                builder: (context, caja) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: caja.maxHeight),
                    child: IntrinsicHeight(child: contenido),
                  ),
                ),
              )
            : contenido,
      ),
    );
  }
}

/// Lo que ofrece la app, al pie del panel visual de escritorio.
class _Beneficios extends StatelessWidget {
  const _Beneficios();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 22,
      children: [
        _Beneficio(
          icono: Icons.insights_rounded,
          texto: 'Riesgo de reingreso explicado',
        ),
        _Beneficio(
          icono: Icons.apartment_rounded,
          texto: 'Indicadores por sede',
        ),
        _Beneficio(
          icono: Icons.verified_user_outlined,
          texto: 'Cada acceso auditado',
        ),
      ],
    );
  }
}

class _Beneficio extends StatelessWidget {
  const _Beneficio({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 266,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icono, size: 20, color: ColoresVitalys.turquesa),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
