import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/webview/webview.dart';

class ClScotiabankPersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  ClScotiabankPersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(String username, String password) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      log("ScotiabankService auth before navigate");

      await webview.navigate(
        URLRequest(url: WebUri("https://www.scotiabank.cl/login/personas/")),
      );

      webview.addAjaxResponseListener(
        RegExp(
          r'https://www.scotiabank.cl/api/clservices/bff-home-main-web/v1/accounts',
        ),
        (request) async {
          completer.complete('true');
          return AjaxRequestAction.PROCEED;
        },
      );

      log("ScotiabankService auth after navigate");

      final rutSelector = "input[name='Validate_rut']";
      final passwordSelector = "input[name='pin']";

      await webview.waitForSelector("input[name='Validate_rut']");

      log("ScotiabankService auth selector $rutSelector founded");

      await webview.type(rutSelector, username);
      await webview.type(passwordSelector, password);
      await webview.tap("button[type='default']");

      log("ScotiabankService auth waiting for completer...");

      await completer.future;

      final cookies = await webview.cookies(
        urls: [Uri.parse("https://scotiabank.cl/")],
      );

      await webview.close();

      final cookieString = cookies
          .map((e) => '${e.name}: ${e.value}')
          .join('; ');

      log("ScotiabankService auth completed with: $cookieString");

      return cookieString;
    } catch (e) {
      await webview.close();
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts(String credentials) {
    // TODO: implement getProducts
    throw UnimplementedError();
  }
}
