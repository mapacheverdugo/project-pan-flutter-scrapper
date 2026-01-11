import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/services/connection/connection_service.dart';
import 'package:pan_scrapper/services/connection/webview/webview.dart';

class ClBancoFalabellaPersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  ClBancoFalabellaPersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(String username, String password) async {
    final webview = await _webviewFactory();

    try {
      log("BancoFalabellaService auth - opening login page");

      // Navigate to the login page
      await webview.navigate(
        URLRequest(url: WebUri('https://www.bancofalabella.cl/')),
      );

      log("BancoFalabellaService auth after navigate");

      final openFormButtonSelector = '#btn-auth-normal';
      final rutSelector =
          '#auth-mobile #auth-form div:nth-child(1) > div > input';
      final passwordSelector =
          '#auth-mobile #auth-form div:nth-child(2) > div > input';
      final submitButtonSelector = '#auth-mobile #auth-form #desktop-login';

      // Wait for the open form button to be available
      await webview.waitForSelector(
        openFormButtonSelector,
        timeout: Duration(seconds: 30),
        visible: true,
        stable: true,
      );

      await webview.evaluate(buildFocusJS(openFormButtonSelector));

      final res = await webview.evaluate(
        "document.querySelector('$openFormButtonSelector').click();",
      );

      await webview.waitForSelector(
        rutSelector,
        timeout: Duration(seconds: 30),
        visible: true,
        stable: true,
      );

      log("BancoFalabellaService auth form inputs found");

      await webview.evaluate(buildFocusJS(rutSelector));
      await webview.type(
        rutSelector,
        username.toLowerCase(),
        delay: Duration(milliseconds: 100),
        minVariation: Duration(milliseconds: 30),
        maxVariation: Duration(milliseconds: 90),
      );

      await webview.evaluate(buildFocusJS(passwordSelector));
      await webview.type(
        passwordSelector,
        password,
        delay: Duration(milliseconds: 100),
        minVariation: Duration(milliseconds: 30),
        maxVariation: Duration(milliseconds: 90),
      );

      await webview.waitForSelector(
        submitButtonSelector,
        timeout: Duration(seconds: 30),
      );

      // Click submit button
      await webview.tap(submitButtonSelector);

      await Future.delayed(Duration(seconds: 20));

      log("BancoFalabellaService auth submit clicked, waiting...");

      // Extract cookies after login
      final cookies = await webview.cookies(
        urls: [Uri.parse('https://www.bancofalabella.cl/')],
      );

      await webview.close();

      final cookieString = cookies
          .map((e) => '${e.name}=${e.value}')
          .join('; ');

      log("BancoFalabellaService auth completed - cookies extracted");

      return cookieString;
    } catch (e) {
      await webview.close();
      log('BancoFalabella auth error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedProductModel>> getProducts(String credentials) {
    // TODO: implement getProducts
    throw UnimplementedError();
  }

  @override
  Future<List<Transaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    throw UnimplementedError(
      'BancoFalabella depositary account transactions not implemented',
    );
  }

  String buildFocusJS(String selector) {
    final sel = jsonEncode(selector);
    final js =
        """
    var el = document.querySelector($sel);

    var prev = document.activeElement;

  // 1. Simular salida del anterior
  if (prev) {
    prev.dispatchEvent(new FocusEvent('focusout', { bubbles: true, relatedTarget: el }));
    prev.dispatchEvent(new FocusEvent('DOMFocusOut', { bubbles: true, relatedTarget: el }));
  }

  // 2. Simular entrada al nuevo
  el.focus(); // El navegador lanzará 'focus' automáticamente
  
  // Forzar los eventos que burbujean (los que pintan el color)
  el.dispatchEvent(new FocusEvent('focusin', { bubbles: true, relatedTarget: prev }));
  el.dispatchEvent(new FocusEvent('DOMFocusIn', { bubbles: true, relatedTarget: prev }));
  """;
    return js;
  }

  @override
  Future<List<CreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    throw UnimplementedError(
      'BancoFalabella credit card bill periods not implemented',
    );
  }

  @override
  Future<CreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError('BancoFalabella credit card bill not implemented');
  }

  @override
  Future<Uint8List> getCreditCardBillPdf(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError(
      'BancoFalabella credit card bill PDF not implemented',
    );
  }

  @override
  Future<List<Transaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  ) {
    // TODO: implement getCreditCardUnbilledTransactions
    throw UnimplementedError();
  }
}
