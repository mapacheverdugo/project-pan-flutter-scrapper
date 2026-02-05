import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/constants/strings.dart';
import 'package:pan_scrapper/presentation/controllers/connection_notifier.dart';
import 'package:pan_scrapper/presentation/widgets/default_button.dart';
import 'package:pan_scrapper/presentation/widgets/default_card.dart';
import 'package:pan_scrapper/presentation/widgets/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

const _kaneLogoUrl =
    'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/kane-connect-logo.png?alt=media';

const _logoSize = 48.0;
const _logoAnimationDuration = Duration(milliseconds: 500);

class ConnectionWelcomeView extends StatefulWidget {
  const ConnectionWelcomeView({super.key, required this.onContinue});

  final void Function(BuildContext context) onContinue;

  @override
  State<ConnectionWelcomeView> createState() => _ConnectionWelcomeViewState();
}

class _ConnectionWelcomeViewState extends State<ConnectionWelcomeView> {
  static Widget _logoTransitionBuilder(
    Widget child,
    Animation<double> animation,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  Widget _buildLogoRow({String? clientLogoUrl}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LogoImage(url: _kaneLogoUrl),
        const SizedBox(width: 12),
        if (clientLogoUrl != null)
          _LogoImage(url: clientLogoUrl)
        else
          Container(
            width: _logoSize,
            height: _logoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              Icons.business,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 24,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionNotifier = ConnectionProvider.of(context);
    final isInitialLoading = connectionNotifier.value.isInitialLoading;
    final linkIntent = connectionNotifier.value.linkIntent;
    final clientName = linkIntent?.clientName;
    final clientLogoUrl = linkIntent?.clientLogoUrl;

    return AnimatedSwitcher(
      duration: _logoAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: _logoTransitionBuilder,
      child: isInitialLoading
          ? _buildLoadingContent()
          : _buildLoadedContent(clientName, clientLogoUrl),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoImage(url: _kaneLogoUrl),
          const SizedBox(height: 24),
          const LoadingIndicator(size: 40),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(String? clientName, String? clientLogoUrl) {
    return CustomScrollView(
      key: const ValueKey('loaded'),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildLogoRow(clientLogoUrl: clientLogoUrl),
              const SizedBox(height: 24),
                  Text(
                    '$clientName usa $productName para conectar tu cuenta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  DefaultCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.flash_on,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Conecta en segundos',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Miles de aplicaciones confían en $productName para conectarse rápidamente a instituciones financieras',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Mantén tus datos seguros',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$productName usa las mejores prácticas de seguridad para proteger tus datos',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Spacer(),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        const TextSpan(text: 'Al continuar, aceptas la '),
                        TextSpan(
                          text: 'Política de Privacidad',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => unawaited(
                              launchUrl(
                                Uri.parse('https://kaneapp.cl/privacidad'),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                        ),
                        TextSpan(text: ' de $productName y los '),
                        TextSpan(
                          text: 'Términos y Condiciones',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => unawaited(
                              launchUrl(
                                Uri.parse('https://kaneapp.cl/terminos'),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                        ),
                        const TextSpan(text: ' de uso.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: DefaultButton(
                      text: 'Continuar',
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      size: DefaultButtonSize.lg,
                      onPressed: () {
                        widget.onContinue(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      width: _logoSize,
      height: _logoSize,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: CachedNetworkImage(
        imageUrl: url,
        width: _logoSize,
        height: _logoSize,
        fit: BoxFit.cover,
      ),
    );
  }
}
