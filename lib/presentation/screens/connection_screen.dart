import 'package:animations/animations.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:pan_scrapper/entities/institution.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/entities/link_intent.dart';
import 'package:pan_scrapper/models/connection/extracted_connection_result_model.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';
import 'package:pan_scrapper/presentation/controllers/connection_notifier.dart';
import 'package:pan_scrapper/presentation/models/connection_step.dart';
import 'package:pan_scrapper/presentation/screens/connection_institution_login_view.dart';
import 'package:pan_scrapper/presentation/screens/connection_select_products_view.dart';
import 'package:pan_scrapper/presentation/screens/connection_welcome_view.dart';
import 'package:pan_scrapper/presentation/widgets/connection_header.dart';

class ConnectionStepLayout extends StatelessWidget {
  final Widget child;
  final ConnectionStep step;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClosePressed;

  const ConnectionStepLayout({
    super.key,
    required this.child,
    required this.step,
    this.onBackPressed,
    this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: ConnectionHeader(
          step: step,
          // Si no pasamos onBackPressed, el Header usa el Navigator.pop por defecto
          onBackPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          onClosePressed:
              onClosePressed ??
              () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class ConnectionFlowScreen extends StatefulWidget {
  final LinkIntent linkIntent;
  final List<Institution> institutions;
  final Function(
    ExtractedConnectionResultModel connectionResult,
    String password,
  )?
  onSuccess;
  final Function(String)? onError;

  const ConnectionFlowScreen({
    super.key,
    required this.linkIntent,
    required this.institutions,
    this.onSuccess,
    this.onError,
  });

  @override
  State<ConnectionFlowScreen> createState() => _ConnectionFlowScreenState();
}

class _ConnectionFlowScreenState extends State<ConnectionFlowScreen> {
  late final ConnectionNotifier _connectionNotifier;

  @override
  void initState() {
    super.initState();
    _connectionNotifier = ConnectionNotifier(
      ConnectionState(
        institutions: widget.institutions,
        linkIntent: widget.linkIntent,
        selectedInstitutionCode: widget.linkIntent.preselectedInstitutionCode,
      ),
    );
  }

  @override
  void dispose() {
    _connectionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionProvider(
      notifier: _connectionNotifier,
      child: ListenableBuilder(
        listenable: _connectionNotifier,
        builder: (context, _) {
          final selectedInstitutionCode =
              _connectionNotifier.value.selectedInstitutionCode;
          return Navigator(
            initialRoute: '/welcome',
            onGenerateRoute: (RouteSettings settings) {
              Widget screen;

              // Mapeo de rutas a pantallas envueltas en el Layout
              switch (settings.name) {
                case '/welcome':
                  screen = ConnectionStepLayout(
                    step: ConnectionStep.welcome,
                    child: ConnectionWelcomeView(
                      onContinue: (context) {
                        Navigator.of(context).pushNamed('/login');
                      },
                    ),
                  );
                  break;

                case '/login':
                  screen = ConnectionStepLayout(
                    step: ConnectionStep.login,
                    child: ConnectionInstitutionLoginView(
                      onLoginPressed: (context, username, password) {
                        _login(
                          context,
                          selectedInstitutionCode!,
                          username,
                          password,
                        );
                      },
                      onResetPasswordPressed: (context) {
                        Navigator.of(context).pushNamed('/reset-password');
                      },
                    ),
                  );
                  break;
                case '/products':
                  screen = ConnectionStepLayout(
                    step: ConnectionStep.products,
                    child: ConnectionSelectProductsView(
                      onContinue: (productIds) {
                        _selectProducts(productIds);
                      },
                    ),
                  );
                  break;

                default:
                  return null;
              }

              // AQUI ESTA EL TRUCO: Usamos PageRouteBuilder para la animación
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) => screen,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.horizontal,
                        child: child,
                      );
                    },
                // Duración de la animación
                transitionDuration: const Duration(milliseconds: 500),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _login(
    BuildContext context,
    InstitutionCode institutionCode,
    String username,
    String password,
  ) async {
    try {
      _connectionNotifier.setLoading(true);

      final credentials = await PanScrapperService(
        context: context,
        institutionCode: institutionCode,
      ).auth(username, password);

      final products = await PanScrapperService(
        context: context,
        institutionCode: institutionCode,
      ).getProducts(credentials);

      _connectionNotifier.setProducts(products);

      _connectionNotifier.setUsername(username);
      _connectionNotifier.setPassword(password);

      if (context.mounted) {
        Navigator.of(context).pushNamed('/products');
      }
    } catch (e) {
      _connectionNotifier.setLoading(false);
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _selectProducts(List<String> productIds) async {
    _connectionNotifier.setLoading(true);

    _connectionNotifier.setSelectedProductIds(productIds);
    final selectedInstitution = _connectionNotifier.value.selectedInstitution;
    final selectedInstitutionCode = selectedInstitution?.code;
    final selectedProducts = _connectionNotifier.value.selectedProducts;
    final username = _connectionNotifier.value.username;
    final password = _connectionNotifier.value.password;

    if (selectedInstitutionCode == null) {
      throw Exception('Selected institution is required');
    }

    if (username == null) {
      throw Exception('Username is required');
    }

    if (password == null) {
      throw Exception('Password is required');
    }

    final connection = ExtractedConnectionResultModel(
      institutionCode: selectedInstitutionCode,
      username: username,
      products: selectedProducts,
      credentials: ExtractedConnectionResultCredentialsModel(
        username: username,
        password: null,
      ),
    );

    widget.onSuccess?.call(connection, password);
  }
}
