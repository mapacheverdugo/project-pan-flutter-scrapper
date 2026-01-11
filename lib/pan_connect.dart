import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/constants/storage_keys.dart';
import 'package:pan_scrapper/entities/local_connection.dart';
import 'package:pan_scrapper/models/connection/extracted_connection_result_model.dart';
import 'package:pan_scrapper/models/institution_model.dart';
import 'package:pan_scrapper/models/link_intent_model.dart';
import 'package:pan_scrapper/models/local_connection_model.dart';
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
    String linkToken,
  ) async {
    final dio = Dio();
    final apiService = ApiServiceImpl(dio);

    try {
      _showLoadingOverlay(context);

      final results = await Future.wait([
        apiService.fetchInstitutions(publicKey: publicKey),
        apiService.fetchLinkIntent(linkToken: linkToken, publicKey: publicKey),
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
                      linkToken: linkToken,
                      publicKey: publicKey,
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

  static Future<List<LocalConnection>> _saveConnection({
    required ExtractedConnectionResultModel connection,
    required String linkToken,
    required String publicKey,
    required String password,
  }) async {
    final dio = Dio();
    final apiService = ApiServiceImpl(dio);
    final storage = StorageServiceImpl();

    final executeLinkTokenResult = await apiService.executeLinkToken(
      linkToken: linkToken,
      connectionResult: connection,
      publicKey: publicKey,
    );

    final currentConnections = await _getSavedConnections();

    currentConnections.add(
      LocalConnectionModel(
        id: executeLinkTokenResult.connectionId,
        institutionCode: connection.institutionCode,
        usernameHash: executeLinkTokenResult.usernameHash,
        rawUsername: connection.username,
        password: password,
      ),
    );

    final newConnectionsJson = jsonEncode(currentConnections);
    await storage.saveString(connectionsKey, newConnectionsJson);

    return currentConnections.map((e) => e.toEntity()).toList();
  }

  static Future<List<LocalConnectionModel>> _getSavedConnections() async {
    final storage = StorageServiceImpl();
    var currentConnections = <LocalConnectionModel>[];

    final connectionsJsonString = await storage.getString(connectionsKey);
    if (connectionsJsonString != null && connectionsJsonString.isNotEmpty) {
      final connectionsJson = jsonDecode(connectionsJsonString);
      currentConnections = connectionsJson
          .map((e) => LocalConnectionModel.fromJson(e))
          .toList();
    }

    return currentConnections;
  }

  static Future<List<LocalConnection>> getSavedConnections() async {
    final currentConnections = await _getSavedConnections();
    return currentConnections.map((e) => e.toEntity()).toList();
  }

  static Future<void> syncLocalConnection(LocalConnection connection) async {}
}
