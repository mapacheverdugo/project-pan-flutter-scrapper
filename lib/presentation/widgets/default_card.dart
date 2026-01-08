import 'dart:io';

import 'package:flutter/material.dart';

class DefaultCard extends StatelessWidget {
  const DefaultCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      margin: margin,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: borderColor ?? Theme.of(context).colorScheme.outline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: Platform.isIOS
            ? Colors.transparent
            : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(30),
        highlightColor: Platform.isIOS
            ? Colors.transparent
            : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(30),
        child: Container(padding: padding, child: child),
      ),
    );
  }
}
