import 'package:flutter/material.dart';
import 'package:pan_scrapper/constants/strings.dart';
import 'package:pan_scrapper/presentation/controllers/connection_notifier.dart';
import 'package:pan_scrapper/presentation/widgets/default_button.dart';
import 'package:pan_scrapper/presentation/widgets/institution_avatar.dart';
import 'package:pan_scrapper/presentation/widgets/password_form_field.dart';
import 'package:pan_scrapper/presentation/widgets/rut_form_field.dart';

class ConnectionInstitutionLoginView extends StatefulWidget {
  const ConnectionInstitutionLoginView({
    super.key,

    required this.onLoginPressed,
    required this.onResetPasswordPressed,
  });

  final void Function(BuildContext context, String username, String password)
  onLoginPressed;
  final void Function(BuildContext context) onResetPasswordPressed;

  @override
  State<ConnectionInstitutionLoginView> createState() =>
      _ConnectionInstitutionLoginViewState();
}

class _ConnectionInstitutionLoginViewState
    extends State<ConnectionInstitutionLoginView> {
  String? _username;
  String? _password;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final connectionNotifier = ConnectionProvider.of(context);
    final isLoading = connectionNotifier.value.isLoading;
    final institution = connectionNotifier.value.selectedInstitution;
    final institutionName = institution?.name;
    final clientName = connectionNotifier.value.linkIntent.clientName;

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (institution != null) ...[
                    Center(
                      child: InstitutionAvatar(
                        institution: institution,
                        width: 56,
                        height: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Title
                  Text(
                    'Inicia sesión en $institutionName',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Instructions
                  Text(
                    'Ingresa tus credenciales de $institutionName para conectar tu cuenta a $clientName.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  RutFormField(
                    decoration: InputDecoration(labelText: 'RUT'),
                    enabled: !isLoading,
                    ignoreBlank: false,
                    onChanged: (value) {
                      setState(() {
                        _username = value?.clean;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordFormField(
                    decoration: InputDecoration(labelText: 'Contraseña'),
                    enabled: !isLoading,
                    ignoreBlank: false,
                    onChanged: (value) {
                      setState(() {
                        _password = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Spacer(),
                  Text(
                    'Al proporcionar tus credenciales, permites que $productName acceda a tus datos financieros.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: DefaultButton(
                      text: 'Enviar',
                      size: DefaultButtonSize.lg,
                      isLoading: isLoading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_username == null || _password == null) {
                            return;
                          }

                          widget.onLoginPressed(
                            context,
                            _username!,
                            _password!,
                          );
                        }
                      },
                    ),
                  ),
                  /* const SizedBox(height: 16),
            
                  Center(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              // TODO: Handle reset password
                            },
                      child: Text(
                        'Restablecer contraseña',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ), */
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
