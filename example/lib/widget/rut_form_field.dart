import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:validate_rut/validate_rut.dart';

class RutFormField extends StatefulWidget {
  final ValueChanged<String?>? onChanged;
  final Function(String?)? onValidatorError;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final bool enabled;
  final bool clearable;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;

  const RutFormField({
    Key? key,
    this.onChanged,
    this.onValidatorError,
    this.autovalidateMode,
    this.decoration,
    this.enabled = true,
    this.clearable = false,
    this.focusNode,
    this.controller,
    this.textInputAction,
  }) : super(key: key);

  @override
  State<RutFormField> createState() => _RutFormFieldState();
}

class _RutFormFieldState extends State<RutFormField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  String? _currentValue;

  @override
  Widget build(BuildContext context) {
    var inputDecoration = widget.decoration ?? InputDecoration();

    if (widget.clearable && _controller.text.isNotEmpty) {
      inputDecoration = inputDecoration.copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () {
            _controller.clear();
            _currentValue = null;
            widget.onChanged?.call(_currentValue);
          },
        ),
      );
    }

    return TextFormField(
      decoration: inputDecoration,
      controller: _controller,
      focusNode: _focusNode,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
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
        _currentValue = v.isNotEmpty ? removeRutFormatting(v) : null;
        widget.onChanged?.call(_currentValue);
      },
      autovalidateMode: widget.autovalidateMode,
      keyboardType: Platform.isIOS
          ? TextInputType.text
          : TextInputType.streetAddress,

      textCapitalization: TextCapitalization.none,
      enableSuggestions: true,
    );
  }
}
