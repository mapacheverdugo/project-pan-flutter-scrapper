import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extraction.dart';
import 'package:pan_scrapper/entities/extraction_operation.dart';
import 'package:pan_scrapper/entities/local_connection.dart';
import 'package:pan_scrapper/entities/product_type.dart';
import 'package:pan_scrapper/models/connection/extracted_connection_result_model.dart';
import 'package:pan_scrapper/models/institution_model.dart';
import 'package:pan_scrapper/models/link_intent_model.dart';
import 'package:pan_scrapper/models/local_connection_model.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';
import 'package:pan_scrapper/presentation/screens/connection_screen.dart';
import 'package:pan_scrapper/services/api/api_service.dart';
import 'package:pan_scrapper/services/storage/storage_service.dart';

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
    String linkWidgetToken, {
    void Function(String exchangeToken, String username)? onSuccess,
  }) async {
    final dio = Dio();
    final apiService = ApiServiceImpl(dio);

    try {
      _showLoadingOverlay(context);

      final results = await Future.wait([
        apiService.fetchInstitutions(publicKey: publicKey),
        apiService.fetchLinkIntent(
          linkWidgetToken: linkWidgetToken,
          publicKey: publicKey,
        ),
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
                  institutions: institutions,
                  linkIntent: linkIntent,
                  onSuccess: (connection, password) async {
                    await _saveConnection(
                      connection: connection,
                      password: password,
                      linkWidgetToken: linkWidgetToken,
                      publicKey: publicKey,
                      onSuccess: onSuccess,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
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

  static Future<void> _saveConnection({
    required ExtractedConnectionResultModel connection,
    required String linkWidgetToken,
    required String publicKey,
    required String password,
    void Function(String exchangeToken, String username)? onSuccess,
  }) async {
    final dio = Dio();
    final apiService = ApiServiceImpl(dio);
    final storage = StorageServiceImpl();

    final executeLinkTokenResult = await apiService.executeLinkWidgetToken(
      linkWidgetToken: linkWidgetToken,
      connectionResult: connection,
      publicKey: publicKey,
    );

    final newConnection = LocalConnectionModel(
      id: executeLinkTokenResult.id,
      institutionCode: connection.institutionCode,
      rawUsername: connection.username,
      password: password,
    );

    await storage.saveNewConnection(newConnection);

    onSuccess?.call(executeLinkTokenResult.exchangeToken, connection.username);
  }

  static Future<List<LocalConnection>> getSavedConnections() async {
    final storage = StorageServiceImpl();
    final currentConnections = await storage.getSavedConnections();
    return currentConnections.map((e) => e.toEntity()).toList();
  }

  static Future<void> syncLocalConnection(
    BuildContext context,
    String linkToken,
    String publicKey,
  ) async {
    final dio = Dio();
    final apiService = ApiServiceImpl(dio);
    final storage = StorageServiceImpl();

    final connectionId = await apiService.validateLinkToken(
      linkToken: linkToken,
      publicKey: publicKey,
    );

    final hasConnections = await storage.hasConnections();
    if (!hasConnections) {
      throw Exception('No connections found');
    }

    final connection = await storage.getConnectionById(connectionId);

    if (connection == null) {
      throw Exception('Connection not found');
    }

    if (!context.mounted) return;

    final panScrapperService = PanScrapperService(
      context: context,
      connection: connection.toEntity(),
    );

    final extractions = <Extraction>[];

    final products = await panScrapperService.getProducts();
    extractions.add(
      Extraction(
        payload: products.map((e) => e.toJson()).toList(),
        params: null,
        operation: ExtractionOperation.products,
      ),
    );

    for (final product in products) {
      try {
        if (product.type == ProductType.depositaryAccount) {
          final transactions = await panScrapperService
              .getDepositaryAccountTransactions(product.providerId);
          extractions.add(
            Extraction(
              payload: transactions.map((e) => e.toJson()).toList(),
              params: {'productId': product.providerId},
              operation: ExtractionOperation.depositaryAccountTransactions,
            ),
          );
        }

        if (product.type == ProductType.creditCard) {
          final periods = await panScrapperService.getCreditCardBillPeriods(
            product.providerId,
          );
          extractions.add(
            Extraction(
              payload: periods.map((e) => e.toJson()).toList(),
              params: {'productId': product.providerId},
              operation: ExtractionOperation.creditCardBillPeriods,
            ),
          );

          final nationalUnbilledTransactions = await panScrapperService
              .getCreditCardUnbilledTransactions(
                product.providerId,
                CurrencyType.national,
              );
          extractions.add(
            Extraction(
              payload: nationalUnbilledTransactions
                  .map((e) => e.toJson())
                  .toList(),
              params: {
                'productId': product.providerId,
                'currencyType': CurrencyType.national.name,
              },
              operation: ExtractionOperation.creditCardUnbilledTransactions,
            ),
          );

          final internationalUnbilledTransactions = await panScrapperService
              .getCreditCardUnbilledTransactions(
                product.providerId,
                CurrencyType.international,
              );
          extractions.add(
            Extraction(
              payload: internationalUnbilledTransactions
                  .map((e) => e.toJson())
                  .toList(),
              params: {
                'productId': product.providerId,
                'currencyType': CurrencyType.international.name,
              },
              operation: ExtractionOperation.creditCardUnbilledTransactions,
            ),
          );
        }
      } catch (e) {
        log('Error extracting ${product.type} transactions: $e');
      }
    }

    await apiService.submitExtractions(
      extractions: extractions,
      publicKey: publicKey,
      linkToken: linkToken,
    );
  }
}
