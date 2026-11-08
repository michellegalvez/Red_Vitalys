import 'package:flutter/material.dart';
import 'package:red_vitalys/modelos/modelos.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/aviso.dart';
import 'package:red_vitalys/widgets/boton.dart';
import 'package:red_vitalys/widgets/marca.dart';
import 'package:red_vitalys/widgets/proposito.dart';
import 'package:red_vitalys/reglas/reglas.dart';

/// Último paso después de iniciar sesión: el médico declara para qué va a
/// mirar la lista de pacientes con alta reciente (F-06, F-16). Es una
/// pantalla completa porque es el primer momento de la sesión; para abrir a
/// un paciente se usa el pop-up de [DialogoProposito].
///
/// Solo muestra y avisa: el propósito elegido y el error vienen de la Screen.
class PropositoListaPage extends StatelessWidget {
  const PropositoListaPage({
    super.key,
    required this.saludo,
    required this.rol,
    required this.sede,
    required this.fecha,
    required this.totalPacientes,
    required this.conAlerta,
    required this.propositos,
    required this.elegido,
    required this.error,
    required this.quedaraRegistrado,
    required this.onElegir,
    required this.onConfirmar,
    required this.onCancelar,
  });

  /// Por ejemplo "Buenos días, Dra. Camila".
  final String saludo;
  final String rol;
  final String sede;
  final String fecha;
  final int totalPacientes;
  final int conAlerta;
  final List<Proposito> propositos;
  final Proposito? elegido;
  final String? error;
  final String quedaraRegistrado;
  final ValueChanged<Proposito> onElegir;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= anchoEscritorio;
    return Scaffold(
      backgroundColor: Colors.white,
      body: escritorio ? _escritorio() : _celular(),
    );
  }

  // ---------------------------------------------------------------------

  Widget _escritorio() {
    return Row(
      children: [
        Expanded(flex: 9, child: _Bienvenida(page: this, escritorio: true)),
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(48, 32, 48, 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _opciones(compacto: false),
                    ),
                  ),
                ),
              ),
              _pie(const EdgeInsets.fromLTRB(48, 14, 48, 22)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _celular() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bienvenida(page: this, escritorio: false),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                  child: _opciones(compacto: true),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: _pie(const EdgeInsets.fromLTRB(18, 10, 18, 12)),
        ),
      ],
    );
  }

  Widget _pie(EdgeInsets padding) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ColoresVitalys.borde)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BotonVitalys(
            texto: 'Ahora no',
            variante: VarianteBoton.secundario,
            onPressed: onCancelar,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: BotonVitalys(
              texto: 'Ver pacientes',
              icono: Icons.groups_rounded,
              onPressed: onConfirmar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _opciones({required bool compacto}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ÚLTIMO PASO ANTES DE ENTRAR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: ColoresVitalys.primario,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            '¿Para qué va a mirar los pacientes con alta reciente?',
            style: TextStyle(
              fontSize: compacto ? 21 : 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Elija una opción. Se pregunta cada vez que se abre algo.',
          style: TextStyle(
            fontSize: 13.5,
            color: ColoresVitalys.textoSecundario,
          ),
        ),
        const SizedBox(height: 16),
        for (final p in propositos)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: OpcionProposito(
              proposito: p,
              elegido: p == elegido,
              compacto: compacto,
              onTap: () => onElegir(p),
            ),
          ),
        if (elegido == Proposito.urgencia) ...[
          const SizedBox(height: 2),
          const Aviso(
            tipo: TipoAviso.advertencia,
            texto: avisoDeclarandoUrgencia,
            items: [
              'Podrá abrirlo aunque no tenga relación con el paciente.',
              'El auditor lo verá marcado como emergencia.',
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (error != null) ...[
          const SizedBox(height: 2),
          Aviso(tipo: TipoAviso.errores, texto: error!),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        QuedaraRegistrado(
          texto: quedaraRegistrado,
          proposito: elegido?.nombreCorto,
        ),
        if (compacto) ...[
          const SizedBox(height: 10),
          const PorQueSePide(compacto: true),
        ],
      ],
    );
  }
}

/// Panel violeta con el saludo, la sede y el resumen de la lista.
class _Bienvenida extends StatelessWidget {
  const _Bienvenida({required this.page, required this.escritorio});

  final PropositoListaPage page;
  final bool escritorio;

  @override
  Widget build(BuildContext context) {
    final saludo = Text(
      page.saludo,
      style: TextStyle(
        fontSize: escritorio ? 46 : 28,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: escritorio ? -1.6 : -0.9,
        color: Colors.white,
      ),
    );
    final etiquetas = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(icono: Icons.location_on_outlined, texto: page.sede),
        _Chip(icono: Icons.badge_outlined, texto: page.rol),
        _Chip(icono: Icons.schedule_rounded, texto: page.fecha),
      ],
    );
    final resumen = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Dato(
              valor: '${page.totalPacientes}',
              texto: 'pacientes con alta reciente',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Dato(
              valor: '${page.conAlerta}',
              texto: 'con alerta de riesgo',
              resaltado: true,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        escritorio ? 48 : 20,
        escritorio ? 44 : 14,
        escritorio ? 48 : 20,
        escritorio ? 44 : 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColoresVitalys.violetaHeroInicio,
            ColoresVitalys.violetaHeroFin,
            Color(0xFF3B7BE8),
          ],
          stops: [0, 0.65, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MarcaRedVitalys(sobreOscuro: true, tamano: 32),
            if (escritorio)
              const Spacer(flex: 2)
            else
              const SizedBox(height: 22),
            saludo,
            const SizedBox(height: 14),
            etiquetas,
            SizedBox(height: escritorio ? 26 : 16),
            resumen,
            if (escritorio) ...[
              const Spacer(flex: 2),
              const PorQueSePide(compacto: false, oscuro: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: ColoresVitalys.turquesa),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.valor,
    required this.texto,
    this.resaltado = false,
  });

  final String valor;
  final String texto;
  final bool resaltado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: resaltado ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w800,
              color: resaltado ? ColoresVitalys.verdeLima : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
