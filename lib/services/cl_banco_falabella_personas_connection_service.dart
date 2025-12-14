import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/webview/webview.dart';

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
      );

      await webview.tap(openFormButtonSelector);

      await webview.waitForSelector(
        rutSelector,
        timeout: Duration(seconds: 30),
        visible: true,
      );

      log("BancoFalabellaService auth form inputs found");

      await webview.tap(rutSelector);
      await webview.type(
        rutSelector,
        username.toLowerCase(),
        minVariation: Duration(milliseconds: 1050),
        maxVariation: Duration(milliseconds: 3050),
      );

      await webview.tap(passwordSelector);
      await webview.type(
        passwordSelector,
        password,
        minVariation: Duration(milliseconds: 1050),
        maxVariation: Duration(milliseconds: 3050),
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
  Future<List<Product>> getProducts(String credentials) {
    // TODO: implement getProducts
    throw UnimplementedError();
  }
}
