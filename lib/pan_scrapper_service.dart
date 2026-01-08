import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/webview/webview.dart';

import 'services/index.dart';

class PanScrapperService {
  final Institution institution;
  final BuildContext context;
  final bool headless;

  late final ConnectionService _client;
  late final Dio _dio;

  PanScrapperService({
    required this.context,
    required this.institution,
    this.headless = true,
  }) {
    _dio = Dio();

    switch (institution) {
      case Institution.bci:
        _client = ClBciPersonasConnectionService(_dio, _getWebview);
        break;
      case Institution.santander:
        _client = ClSantanderPersonasConnectionService(_dio, _getWebview);
        break;
      case Institution.scotiabank:
        _client = ClScotiabankPersonasConnectionService(_dio, _getWebview);
        break;
      case Institution.bancoChile:
        _client = ClBancoChilePersonasConnectionService(_dio, _getWebview);
        break;
      case Institution.itau:
        _client = ClItauPersonasConnectionService(_dio, _getWebview);
        break;
      case Institution.bancoFalabella:
        _client = ClBancoFalabellaPersonasConnectionService(_dio, _getWebview);
        break;
      case Institution.bancoEstado:
        _client = ClBancoEstadoPersonasConnectionService(_dio, _getWebview);
        break;
      default:
        throw Exception('Institution not supported');
    }
  }

  Future<WebviewInstance> _getWebview({String? cookies}) async {
    return await Webview.run(
      headless: headless,
      context: context,
      builder: (context, webview) => Scaffold(appBar: AppBar(), body: webview),
    );
  }

  static Future<List<Institution>> getAvailableInstitutions() async {
    return [
      Institution.santander,
      Institution.itau,
      Institution.scotiabank,
      Institution.bancoChile,
    ];
  }

  Future<String> auth(String username, String password) async {
    return _client.auth(username, password);
  }

  Future<List<Product>> getProducts(String credentials) async {
    return _client.getProducts(credentials);
  }

  Future<List<Transaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    return _client.getDepositaryAccountTransactions(credentials, productId);
  }

  Future<List<CreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    return _client.getCreditCardBillPeriods(credentials, productId);
  }

  Future<CreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    return _client.getCreditCardBill(credentials, productId, periodId);
  }

  Future<List<Transaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  ) async {
    return _client.getCreditCardUnbilledTransactions(
      credentials,
      productId,
      transactionType,
    );
  }
}
