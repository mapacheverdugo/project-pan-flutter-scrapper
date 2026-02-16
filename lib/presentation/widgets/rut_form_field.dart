import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pan_scrapper/entities/rut.dart';
import 'package:validate_rut/validate_rut.dart';

class RutFormField extends StatefulWidget {
  final ValueChanged<Rut?>? onChanged;
  final Function(String?)? onValidatorError;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final bool enabled;
  final bool ignoreBlank;
  final bool clearable;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final Rut? initialValue;

  const RutFormField({
    Key? key,
    this.onChanged,
    this.onValidatorError,
    this.autovalidateMode,
    this.ignoreBlank = false,
    this.decoration,
    this.enabled = true,
    this.clearable = false,
    this.initialValue,
    this.focusNode,
    this.controller,
    this.textInputAction,
  }) : super(key: key);

  @override
  State<RutFormField> createState() => _RutFormFieldState();
}

class _RutFormFieldState extends State<RutFormField> {
  late final TextEditingController _controller =
      widget.controller ??
      TextEditingController(text: widget.initialValue?.clean ?? "");
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  Rut? _currentValue;

  String? _validator(String? v) {
    if (!widget.ignoreBlank && (v == null || v.isEmpty)) {
      return 'Debe ingresar su RUT';
    }
    if (!Rut(v!).isValid) {
      return 'El RUT ingresado no es válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration =
        widget.decoration ??
        InputDecoration(
          hintText: "RUT",
          label: const Text("RUT"),
          border: const OutlineInputBorder(),
          suffixIcon: widget.clearable && _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _controller.clear();
                    _currentValue = null;
                    widget.onChanged?.call(_currentValue);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.cancel),
                  ),
                )
              : null,
        );

    return TextFormField(
      decoration: inputDecoration,
      controller: _controller,
      focusNode: _focusNode,
      autocorrect: false,

      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      autofillHints: const [AutofillHints.username],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isNotEmpty) {
            return TextEditingValue(
              text: formatRut(newValue.text).toUpperCase(),
            );
          }
          return newValue;
        }),
      ],
      onChanged: (v) {
        _currentValue = v.isNotEmpty ? Rut(removeRutFormatting(v)) : null;
        widget.onChanged?.call(_currentValue);
      },
      autovalidateMode: widget.autovalidateMode,
      keyboardType: Platform.isIOS
          ? TextInputType.text
          : TextInputType.streetAddress,
      textCapitalization: TextCapitalization.none,
      enableSuggestions: Platform.isAndroid,
      validator: (v) {
        final error = _validator(v);
        widget.onValidatorError?.call(error);
        return error;
      },
    );
  }
}
