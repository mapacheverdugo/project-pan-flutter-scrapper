import 'package:flutter/material.dart';
import 'package:pan_scrapper/presentation/widgets/loading_indicator.dart';

enum DefaultButtonSize { sm, md, lg }

class DefaultButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final DefaultButtonSize size;

  const DefaultButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.size = DefaultButtonSize.md,
  });

  EdgeInsets get _padding => switch (size) {
    DefaultButtonSize.sm => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    DefaultButtonSize.md => const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    DefaultButtonSize.lg => const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size(0, 0),
          padding: EdgeInsets.zero,
        ),
        onPressed: isLoading ? null : onPressed,
        child: Padding(
          padding: _padding,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: LoadingIndicator(
                    size: 20,
                    color: foregroundColor ??
                        Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(text.toUpperCase()),
        ),
      ),
    );
  }
}
