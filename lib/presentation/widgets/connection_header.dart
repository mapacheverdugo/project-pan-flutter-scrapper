import 'package:flutter/material.dart';
import 'package:pan_scrapper/constants/strings.dart';
import 'package:pan_scrapper/entities/institution.dart';
import 'package:pan_scrapper/presentation/controllers/connection_notifier.dart';
import 'package:pan_scrapper/presentation/models/connection_step.dart';

class ConnectionHeader extends StatelessWidget implements PreferredSizeWidget {
  const ConnectionHeader({
    super.key,
    required this.step,
    this.selectedInstitution,
    this.forceSelection = false,
    this.onBackPressed,
    this.onClosePressed,
  });
  final ConnectionStep step;
  final Institution? selectedInstitution;
  final bool forceSelection;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClosePressed;

  static double preferredHeightFor(BuildContext context, Size preferredSize) {
    return (AppBarTheme.of(context).toolbarHeight ?? kToolbarHeight);
  }

  double get _progressValue =>
      (1 / ConnectionStep.values.length) * (step.index + 0.5);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  bool _showBackButton(bool isLoading) =>
      step != ConnectionStep.welcome && !isLoading;
  bool _showCloseButton(bool isLoading) => !isLoading;
  bool get _showProgress => step != ConnectionStep.welcome;
  bool get _showTitle => step != ConnectionStep.welcome;

  @override
  Widget build(BuildContext context) {
    final connectionNotifier = ConnectionProvider.of(context);
    final isLoading = connectionNotifier.value.isLoading;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: _showTitle ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 0),
                        child: Text(
                          productName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    AnimatedOpacity(
                      opacity: _showBackButton(isLoading) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 0),
                      child: GestureDetector(
                        onTap: onBackPressed,
                        child: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                    Spacer(),
                    AnimatedOpacity(
                      opacity: _showCloseButton(isLoading) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: GestureDetector(
                        onTap: onClosePressed,
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: _showProgress ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              tween: Tween<double>(begin: 0, end: _progressValue),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
