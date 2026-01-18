import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/services/connection/connection_service.dart';
import 'package:pan_scrapper/services/connection/webview/webview.dart';

class ClBancoEstadoPersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  ClBancoEstadoPersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(String username, String password) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      log("BancoEstadoService auth before navigate");

      // Listen for successful login via AJAX request
      webview.addAjaxResponseListener(
        RegExp(
          r'https://nwm\.bancoestado\.cl/bff/v1/perfilamiento-web-bff/getProfile',
        ),
        (request) async {
          if (!completer.isCompleted) {
            completer.complete('true');
          }
          return AjaxRequestAction.PROCEED;
        },
      );

      await webview.navigate(
        URLRequest(
          url: WebUri(
            'https://www.bancoestado.cl/content/bancoestado-public/cl/es/home/home.html#/login',
          ),
        ),
      );

      log("BancoEstadoService auth after navigate");

      final rutSelector = '#rut';
      final passwordSelector = '#pass';
      final submitButtonSelector = '#btnLogin';

      // Wait for RUT input to be visible
      await webview.waitForSelector(
        rutSelector,
        timeout: Duration(seconds: 30),
        visible: true,
      );

      await Future.delayed(Duration(seconds: 5));

      log("BancoEstadoService auth selector $rutSelector found");

      await webview.tap(rutSelector);
      await webview.type(rutSelector, username);
      await webview.tap(passwordSelector);
      await webview.type(passwordSelector, password);
      await webview.tap(submitButtonSelector);

      log("BancoEstadoService auth waiting for completer...");

      await completer.future;

      final cookies = await webview.cookies(
        urls: [Uri.parse('https://www.bancoestado.cl/')],
      );

      await webview.close();

      final cookieString = cookies
          .map((e) => '${e.name}=${e.value}')
          .join('; ');

      log("BancoEstadoService auth completed with: $cookieString");

      return cookieString;
    } catch (e) {
      await webview.close();
      log('BancoEstado auth error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedProductModel>> getProducts(String credentials) {
    // TODO: implement getProducts
    throw UnimplementedError();
  }

  @override
  Future<List<ExtractedTransaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    throw UnimplementedError(
      'BancoEstado depositary account transactions not implemented',
    );
  }

  @override
  Future<List<ExtractedCreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    throw UnimplementedError(
      'BancoEstado credit card bill periods not implemented',
    );
  }

  @override
  Future<ExtractedCreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError('BancoEstado credit card bill not implemented');
  }

  @override
  Future<Uint8List> getCreditCardBillPdf(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError(
      'BancoEstado credit card bill PDF not implemented',
    );
  }

  @override
  Future<List<ExtractedTransaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  ) {
    // TODO: implement getCreditCardUnbilledTransactions
    throw UnimplementedError();
  }
}
