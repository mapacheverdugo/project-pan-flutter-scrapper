import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/constants/strings.dart';
import 'package:pan_scrapper/presentation/controllers/connection_notifier.dart';
import 'package:pan_scrapper/presentation/widgets/default_button.dart';
import 'package:pan_scrapper/presentation/widgets/default_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectionWelcomeView extends StatefulWidget {
  const ConnectionWelcomeView({super.key, required this.onContinue});

  final void Function(BuildContext context) onContinue;

  @override
  State<ConnectionWelcomeView> createState() => _ConnectionWelcomeViewState();
}

class _ConnectionWelcomeViewState extends State<ConnectionWelcomeView> {
  @override
  Widget build(BuildContext context) {
    final connectionNotifier = ConnectionProvider.of(context);
    final clientName = connectionNotifier.value.linkIntent.clientName;
    final clientLogoUrl = connectionNotifier.value.linkIntent.clientLogoUrl;

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    clipBehavior: Clip.hardEdge,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/kane-connect-logo.png?alt=media',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (clientLogoUrl != null) ...[
                    const SizedBox(width: 12),

                    Container(
                      clipBehavior: Clip.hardEdge,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        clientLogoUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '$clientName usa $productName para conectar tu cuenta',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              // Info box
              DefaultCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connect in seconds
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Miles de aplicaciones confían en $productName para conectarse rápidamente a instituciones financieras',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Keep data safe
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$productName usa el mejor cifrado para ayudar a proteger tus datos',
                                style: Theme.of(context).textTheme.bodySmall,
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
              Spacer(),
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
                        decorationColor: Theme.of(context).colorScheme.primary,
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
                        decorationColor: Theme.of(context).colorScheme.primary,
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
