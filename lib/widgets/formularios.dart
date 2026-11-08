import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:red_vitalys/tema/tema.dart';
import 'package:red_vitalys/widgets/foco.dart';

const _radioCampo = BorderRadius.all(Radius.circular(18));

InputDecoration _decoracion({
  String? hint,
  String? error,
  Widget? prefijo,
  Widget? sufijo,
  bool habilitado = true,
}) {
  OutlineInputBorder borde(Color c, [double w = 1.2]) => OutlineInputBorder(
    borderRadius: _radioCampo,
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: ColoresVitalys.textoSuave),
    errorText: error,
    errorMaxLines: 3,
    prefixIcon: prefijo,
    suffixIcon: sufijo,
    filled: true,
    fillColor: habilitado ? Colors.white : ColoresVitalys.fondoLavanda,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    enabledBorder: borde(ColoresVitalys.bordeControl),
    disabledBorder: borde(ColoresVitalys.borde),
    focusedBorder: borde(ColoresVitalys.primario, 1.8),
    errorBorder: borde(ColoresVitalys.alerta),
    focusedErrorBorder: borde(ColoresVitalys.alerta, 1.8),
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {this.ayuda});

  final String texto;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (ayuda != null) ...[
            const SizedBox(height: 4),
            Text(
              ayuda!,
              style: const TextStyle(
                fontSize: 13,
                color: ColoresVitalys.textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Campo de texto de la galería, con su etiqueta, ayuda y error.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.hint,
    this.ayuda,
    this.error,
    this.oculto = false,
    this.sufijo,
    this.habilitado = true,
    this.soloLectura = false,
    this.lineas = 1,
    this.teclado,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
    this.maxLength,
    this.autocorregir,
  });

  final String etiqueta;
  final TextEditingController controller;
  final String? hint;
  final String? ayuda;
  final String? error;
  final bool oculto;
  final Widget? sufijo;

  /// Sin habilitar, el campo se ve y no se puede editar.
  final bool habilitado;

  /// Se puede enfocar y leer, pero no editar (no pierde el foco).
  final bool soloLectura;

  /// Líneas visibles del campo (más de una para textos largos).
  final int lineas;
  final TextInputType? teclado;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  /// Largo máximo; el contador no se muestra.
  final int? maxLength;
  final bool? autocorregir;

  @override
  Widget build(BuildContext context) {
    final campo = Semantics(
      label: etiqueta,
      hint: ayuda,
      textField: true,
      child: TextField(
        controller: controller,
        enabled: habilitado,
        readOnly: soloLectura,
        minLines: lineas,
        maxLines: oculto ? 1 : lineas,
        obscureText: oculto,
        autocorrect: autocorregir ?? !oculto,
        enableSuggestions: !oculto,
        keyboardType: teclado,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        maxLength: maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        buildCounter: (
          _, {
          required currentLength,
          required isFocused,
          maxLength,
        }) => null,
        onSubmitted: onSubmitted,
        decoration: _decoracion(
          hint: hint,
          error: error,
          sufijo: sufijo,
          habilitado: habilitado,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: _Etiqueta(etiqueta, ayuda: ayuda)),
        campo,
      ],
    );
  }
}

/// Selector (lista desplegable) de la galería.
class SelectorVitalys<T> extends StatelessWidget {
  const SelectorVitalys({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onChanged,
    this.etiqueta,
    this.ayuda,
    this.hint,
    this.error,
  });

  /// Pares de valor y texto que se muestra.
  final List<(T, String)> opciones;
  final T? valor;

  /// Sin `onChanged` el selector queda deshabilitado.
  final ValueChanged<T?>? onChanged;
  final String? etiqueta;
  final String? ayuda;
  final String? hint;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final campo = DropdownButtonFormField<T>(
      key: ValueKey('${etiqueta ?? hint}-${opciones.length}'),
      initialValue: valor,
      isExpanded: true,
      borderRadius: _radioCampo,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: _decoracion(
        hint: hint,
        error: error,
        habilitado: onChanged != null,
      ),
      hint: hint == null ? null : Text(hint!, overflow: TextOverflow.ellipsis),
      items: [
        for (final (v, texto) in opciones)
          DropdownMenuItem<T>(
            value: v,
            child: Text(texto, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
    final conEtiqueta = Semantics(
      label: etiqueta ?? hint,
      hint: ayuda,
      container: true,
      child: campo,
    );
    if (etiqueta == null) return conEtiqueta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: _Etiqueta(etiqueta!, ayuda: ayuda)),
        conEtiqueta,
      ],
    );
  }
}

/// Buscador de la galería: un campo con lupa.
class Buscador extends StatefulWidget {
  const Buscador({
    super.key,
    required this.hint,
    required this.valor,
    required this.onChanged,
    this.ayuda,
  });

  final String hint;
  final String valor;
  final ValueChanged<String> onChanged;
  final String? ayuda;

  @override
  State<Buscador> createState() => _BuscadorState();
}

class _BuscadorState extends State<Buscador> {
  // Solo guarda lo que se escribe en el campo; el texto de la búsqueda
  // vive en la Screen anfitriona.
  late final TextEditingController _controller = TextEditingController(
    text: widget.valor,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: widget.hint,
          textField: true,
          child: TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            maxLength: 100,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            textInputAction: TextInputAction.search,
            decoration:
                _decoracion(
                  hint: widget.hint,
                  prefijo: const Icon(Icons.search_rounded),
                ).copyWith(
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    borderSide: BorderSide(
                      color: ColoresVitalys.bordeControl,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    borderSide: BorderSide(
                      color: ColoresVitalys.primario,
                      width: 1.8,
                    ),
                  ),
                ),
          ),
        ),
        if (widget.ayuda != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 18),
            child: Text(
              widget.ayuda!,
              style: const TextStyle(
                fontSize: 13,
                color: ColoresVitalys.textoSecundario,
              ),
            ),
          ),
      ],
    );
  }
}

/// Filtro en píldora de la galería, por ejemplo "Con alerta (4)".
class FiltroPildora extends StatelessWidget {
  const FiltroPildora({
    super.key,
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: seleccionado,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnilloFoco(
              child: Material(
                color: seleccionado ? ColoresVitalys.tinta : Colors.white,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: seleccionado
                        ? ColoresVitalys.tinta
                        : ColoresVitalys.bordeControl,
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      texto,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: seleccionado
                            ? Colors.white
                            : ColoresVitalys.tinta,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
