import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// A shared loading indicator using [SpinKitDoubleBounce] with theme primary color.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.primary;
    return SpinKitDoubleBounce(
      color: effectiveColor,
      size: size,
    );
  }
}
