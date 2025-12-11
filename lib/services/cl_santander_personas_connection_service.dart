import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/webview/webview.dart';

class ClSantanderPersonasConnectionService extends ConnectionService {
  late final Dio _dio;

  ClSantanderPersonasConnectionService(this._dio);

  @override
  Future<String> auth(
    WebviewInstance webview,
    String username,
    String password,
  ) async {
    final completer = Completer<String>();

    try {
      log("SantanderService auth before navigate");

      await webview.navigate(
        URLRequest(url: WebUri("https://www.santandermovil.cl/")),
      );

      webview.addAjaxResponseListener(RegExp(r'oauth2/token'), (request) async {
        debugPrint(
          'SantanderService ajaxResponseListener ${request.readyState}',
        );
        if (request.readyState == AjaxRequestReadyState.DONE) {
          final response = request.responseText;
          completer.complete(response);
        }

        return AjaxRequestAction.PROCEED;
      });

      log("SantanderService auth after navigate");

      await webview.waitForSelector('#rut', timeout: Duration(seconds: 60));

      log("SantanderService auth selector #rut founded");

      // aquí simulas login
      await webview.evaluate("""
        const rutInput = document.getElementById("rut");
        const passwordInput = document.getElementById("pass");
        
        rutInput.value = "$username";
        rutInput.dispatchEvent(new Event('input'));
        rutInput.dispatchEvent(new Event('blur'));

        passwordInput.value = "$password";
        passwordInput.dispatchEvent(new Event('input'));
        passwordInput.dispatchEvent(new Event('blur'));

        document.querySelector("div.login > form > div.container-btn-lib > button > span.mat-button-wrapper").click();
      """);

      log("SantanderService auth waiting for completer...");

      // 🚀 aquí esperas hasta que el interceptor resuelva
      final result = await completer.future;

      log("SantanderService auth completed with: $result");

      await webview.close();

      return result;
    } catch (e) {
      await webview.close();
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<String> getProducts(WebviewInstance webview, String credentials) {
    // TODO: implement getProducts
    throw UnimplementedError();
  }
}
