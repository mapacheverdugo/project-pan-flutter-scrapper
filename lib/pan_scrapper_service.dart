import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/entities/local_connection.dart';
import 'package:pan_scrapper/services/connection/connection_exception.dart';
import 'package:pan_scrapper/services/connection/connection_service.dart';
import 'package:pan_scrapper/services/connection/webview/webview.dart';
import 'package:pan_scrapper/services/storage/storage_service.dart';

import 'services/index.dart';

class PanScrapperService {
  final LocalConnection connection;
  final BuildContext context;
  final bool headless;

  late final ConnectionService _client;
  late final StorageService _storage;

  PanScrapperService({
    required this.context,
    required this.connection,
    this.headless = false,
  }) {
    _storage = StorageServiceImpl();

    _client = _getClient(
      institutionCode: connection.institutionCode,
      context: context,
      headless: headless,
    );
  }

  static ConnectionService _getClient({
    required InstitutionCode institutionCode,
    required BuildContext context,
    bool headless = false,
  }) {
    final dio = Dio();

    switch (institutionCode) {
      case InstitutionCode.clBciPersonas:
        return ClBciPersonasConnectionService(
          dio,
          () => _getWebview(context, headless: headless),
        );
      case InstitutionCode.clSantanderPersonas:
        return ClSantanderPersonasConnectionService(
          dio,
          () => _getWebview(context, headless: headless),
        );
      case InstitutionCode.clScotiabankPersonas:
        return ClScotiabankPersonasConnectionService(
          dio,
          () => _getWebview(context, headless: headless),
        );
      case InstitutionCode.clBancoChilePersonas:
        return ClBancoChilePersonasConnectionService(
          dio,
          () => _getWebview(context, headless: headless),
        );
      case InstitutionCode.clItauPersonas:
        return ClItauPersonasConnectionService(
          dio,
          ({String? cookies}) =>
              _getWebview(context, headless: headless, cookies: cookies),
        );
      case InstitutionCode.clBancoFalabellaPersonas:
        return ClBancoFalabellaPersonasConnectionService(
          dio,
          () => _getWebview(context, headless: headless),
        );
      case InstitutionCode.clBancoEstadoPersonas:
        return ClBancoEstadoPersonasConnectionService(
          dio,
          () => _getWebview(context, headless: headless),
        );
      default:
        throw Exception('Institution not supported');
    }
  }

  static Future<WebviewInstance> _getWebview(
    BuildContext context, {
    bool headless = true,
    String? cookies,
  }) async {
    return await Webview.run(
      headless: headless,
      context: context,
      builder: (context, webview) => Scaffold(appBar: AppBar(), body: webview),
    );
  }

  static Future<List<Institution>> getAvailableInstitutions() async {
    return [];
  }

  static Future<List<ExtractedProductModel>> initialAuthAndGetProducts(
    BuildContext context,
    InstitutionCode institutionCode,
    String username,
    String password,
  ) async {
    final client = _getClient(
      institutionCode: institutionCode,
      context: context,
      headless: true,
    );
    final credentials = await client.auth(username, password);
    return client.getProducts(credentials);
  }

  Future<String> auth(String username, String password) async {
    final credentials = await _client.auth(username, password);
    await _storage.saveConnectionCredentials(connection.id, credentials);
    return credentials;
  }

  Future<List<ExtractedProductModel>> getProducts() async {
    return authenticatedWrapper(connection.id, _client.getProducts);
  }

  Future<List<ExtractedTransaction>> getDepositaryAccountTransactions(
    String productId,
  ) async {
    return authenticatedWrapper(
      connection.id,
      (credentials) =>
          _client.getDepositaryAccountTransactions(credentials, productId),
    );
  }

  Future<List<ExtractedCreditCardBillPeriod>> getCreditCardBillPeriods(
    String productId,
  ) async {
    return authenticatedWrapper(
      connection.id,
      (credentials) => _client.getCreditCardBillPeriods(credentials, productId),
    );
  }

  Future<CreditCardBill> getCreditCardBill(
    String productId,
    String periodId,
  ) async {
    return authenticatedWrapper(
      connection.id,
      (credentials) =>
          _client.getCreditCardBill(credentials, productId, periodId),
    );
  }

  Future<List<ExtractedTransaction>> getCreditCardUnbilledTransactions(
    String productId,
    CurrencyType transactionType,
  ) async {
    return authenticatedWrapper(
      connection.id,
      (credentials) => _client.getCreditCardUnbilledTransactions(
        credentials,
        productId,
        transactionType,
      ),
    );
  }

  Future<T> authenticatedWrapper<T>(
    String connectionId,
    Future<T> Function(String credentials) function,
  ) async {
    var credentials = await _storage.getConnectionCredentials(connectionId);
    log('authenticatedWrapper stored credentials: $credentials');
    if (credentials == null) {
      log('authenticatedWrapper No credentials found, authenticating');
      credentials = await auth(connection.rawUsername, connection.password);
      log('authenticatedWrapper New credentials: $credentials');
    }

    try {
      final result = await function(credentials);
      return result;
    } on ConnectionException catch (e) {
      if (e.type == ConnectionExceptionType.invalidAuthCredentials ||
          e.type == ConnectionExceptionType.authCredentialsExpired) {
        log(
          'authenticatedWrapper ConnectionExceptionType.invalidAuthCredentials, re-authenticating',
        );
        final newCredentials = await auth(
          connection.rawUsername,
          connection.password,
        );
        log(
          'authenticatedWrapper New credentials after ConnectionExceptionType.invalidAuthCredentials: $newCredentials',
        );
        return authenticatedWrapper(connectionId, function);
      }
      log('authenticatedWrapper ConnectionException: $e');
      rethrow;
    } catch (e) {
      log('authenticatedWrapper Error: $e');
      rethrow;
    }
  }
}
