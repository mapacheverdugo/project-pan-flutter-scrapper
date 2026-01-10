import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/models/institution_model.dart';
import 'package:pan_scrapper/models/link_intent_model.dart';
import 'package:pan_scrapper/presentation/screens/connection_screen.dart';
import 'package:pan_scrapper/services/institutions_api_service.dart';

class PanConnect {
  PanConnect();

  /// Shows a loading overlay with circular progress indicator
  static void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// Hides the loading overlay
  static void _hideLoadingOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static Future<void> launch(
    BuildContext context,
    String publicKey,
    String linkToken, {
    InstitutionCode? selectedInstitutionCode,
  }) async {
    if (selectedInstitutionCode == null) {
      throw Exception('Selected institution is required');
    }

    final dio = Dio();
    final institutionsService = InstitutionsApiService(dio);

    try {
      _showLoadingOverlay(context);

      final results = await Future.wait([
        institutionsService.fetchInstitutions(publicKey: publicKey),
        institutionsService.fetchLinkIntent(linkToken: linkToken),
      ]);

      if (context.mounted) {
        _hideLoadingOverlay(context);
      }

      final institutionsModel = results[0] as List<InstitutionModel>;
      final linkIntentModel = results[1] as LinkIntentResponseModel;

      final institutions = institutionsModel.map((e) => e.toEntity()).toList();
      final linkIntent = linkIntentModel.data.toEntity();

      if (context.mounted) {
        await Navigator.push(
          context,
          PageRouteBuilder(
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeIn;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            pageBuilder: (context, animation, secondaryAnimation) =>
                ConnectionFlowScreen(
                  selectedInstitutionCode: selectedInstitutionCode,
                  institutions: institutions,
                  linkIntent: linkIntent,
                ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoadingOverlay(context);
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch institutions: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      rethrow;
    } finally {
      dio.close();
    }
  }
}
