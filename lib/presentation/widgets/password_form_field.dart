import 'dart:io' show Platform;

import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final Function(String?)? onValidatorError;
  final AutovalidateMode? autovalidateMode;
  final FocusNode? focusNode;
  final bool enabled;
  final bool ignoreBlank;
  final bool clearable;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final String? initialValue;

  const PasswordFormField({
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
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController(text: widget.initialValue);
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late String _currentValue = "";

  bool _isVisible = false;

  String? _validator(String? v) {
    if (!widget.ignoreBlank && (v == null || v.isEmpty)) {
      return 'Debe ingresar su contraseña';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final showClear = widget.clearable && _controller.text.isNotEmpty;
    var inputDecoration =
        widget.decoration ??
        InputDecoration(
          labelText: 'Contraseña',
          border: const OutlineInputBorder(),
        );
    inputDecoration = inputDecoration.copyWith(
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.text.isNotEmpty) ...[
            GestureDetector(
              onTap: () => setState(() => _isVisible = !_isVisible),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  _isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ],
          if (showClear) ...[
            GestureDetector(
              onTap: () {
                _controller.clear();
                _currentValue = "";
                widget.onChanged?.call(_currentValue);
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.clear),
              ),
            ),
          ],
        ],
      ),
    );

    return TextFormField(
      decoration: inputDecoration,
      controller: _controller,
      autocorrect: false,
      obscureText: !_isVisible,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      onChanged: (v) {
        _currentValue = v;
        widget.onChanged?.call(_currentValue);
        if (widget.clearable) setState(() {});
      },
      autofillHints: const [AutofillHints.password],
      autovalidateMode: widget.autovalidateMode,
      focusNode: _focusNode,
      keyboardType: Platform.isIOS ? TextInputType.text : TextInputType.name,
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
