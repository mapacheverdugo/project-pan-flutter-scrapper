import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.text, this.maxHeight = 100.0});
  final String text;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(text),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        height: maxHeight,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
            textAlign: TextAlign.left,
            softWrap: true,
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}
