import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/services/mappers/cl_banco_chile_personas/product_mapper.dart';
import 'package:pan_scrapper/services/models/cl_banco_chile_personas/index.dart';
import 'package:pan_scrapper/webview/webview.dart';

class ClBancoChilePersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  ClBancoChilePersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(String username, String password) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      log("BancoChileService auth before navigate");

      // Listen for error redirects
      webview.addLoadResourceListener(
        RegExp(
          r'https://login\.portal\.bancochile\.cl/bancochile-web/persona/login/index\.html#/alerta-bloqueo',
        ),
        () {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Credentials blocked'));
          }
        },
      );

      webview.addAjaxResponseListener(
        RegExp(
          r'https://login\.portales\.bancochile\.cl/usernamepassword/login',
        ),
        (request) async {
          final status = request.status;
          if (status != null) {
            if (status == 429) {
              if (!completer.isCompleted) {
                completer.completeError(Exception('Credentials blocked'));
              }
            } else if (status >= 400) {
              if (!completer.isCompleted) {
                completer.completeError(
                  Exception('Auth detected after password'),
                );
              }
            }
          }
          return AjaxRequestAction.PROCEED;
        },
      );

      await webview.navigate(
        URLRequest(
          url: WebUri('https://portalpersonas.bancochile.cl/persona/'),
        ),
      );

      final rutSelector = '#ppriv_per-login-click-input-rut';
      final passwordSelector = '#ppriv_per-login-click-input-password';

      await webview.waitForSelector(
        rutSelector,
        timeout: Duration(seconds: 30),
        visible: true,
      );

      log("BancoChileService auth selector $rutSelector found");

      await webview.type(rutSelector, username);
      await webview.type(passwordSelector, password);

      // Listen for success URL or error selector
      final successCompleter = Completer<bool>();

      webview.addLoadResourceListener(
        RegExp(r'.*portalpersonas\.bancochile\.cl/mibancochile-web/.*'),
        () {
          if (!successCompleter.isCompleted) {
            successCompleter.complete(true);
          }
        },
      );

      // Check for error selector will be done after click

      await webview.click('#ppriv_per-login-click-ingresar-login');

      log("BancoChileService auth waiting for success...");

      // Wait for success with timeout
      try {
        await successCompleter.future.timeout(
          Duration(seconds: 60),
          onTimeout: () async {
            // Check manually for error before timing out
            try {
              final hasError = await webview.evaluate("""
                (function() {
                  const errorElement = document.querySelector('#errorPassword:not([hidden])');
                  return errorElement !== null;
                })();
              """);
              if (hasError == true) {
                throw Exception('Invalid credentials');
              }
            } catch (checkError) {
              if (checkError.toString().contains('Invalid credentials')) {
                rethrow;
              }
            }
            throw Exception('Timeout waiting for login success');
          },
        );
      } catch (e) {
        // Check if it's an error we want to propagate
        if (e.toString().contains('Invalid credentials') ||
            e.toString().contains('blocked')) {
          rethrow;
        }
        // Otherwise check manually for error
        try {
          final hasError = await webview.evaluate("""
            (function() {
              const errorElement = document.querySelector('#errorPassword:not([hidden])');
              return errorElement !== null;
            })();
          """);
          if (hasError == true) {
            throw Exception('Invalid credentials');
          }
        } catch (checkError) {
          if (checkError.toString().contains('Invalid credentials')) {
            rethrow;
          }
        }
        rethrow;
      }

      log("BancoChileService auth login successful, extracting cookies...");

      final cookies = await webview.cookies(
        urls: [Uri.parse('https://portalpersonas.bancochile.cl/')],
      );

      await webview.close();

      final cookieString = cookies
          .map((e) => '${e.name}=${e.value}')
          .join('; ');

      log("BancoChileService auth completed");

      return cookieString;
    } catch (e) {
      await webview.close();
      log('BancoChile auth error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts(String cookiesString) async {
    try {
      final rawProducts = await _getRawProducts(cookiesString);
      final depositaryBalances = await _getDepositaryBalances(cookiesString);
      final cardsBalances = await _getCardsBalances(cookiesString);

      // Map to Product models
      return ClBancoChilePersonasProductMapper.fromProductsAndBalances(
        rawProducts,
        depositaryBalances,
        cardsBalances,
      );
    } catch (e) {
      log('Error fetching BancoChile products: $e');
      rethrow;
    }
  }

  /// Gets raw products
  Future<ClBancoChilePersonasProductsResponseModel> _getRawProducts(
    String cookiesString,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/selectorproductos/selectorProductos/obtenerProductos?incluirTarjetas=true',
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer':
                'https://portalpersonas.bancochile.cl/mibancochile-web/front/persona/index.html',
            'Cookie': cookiesString,
          },
        ),
      );

      return ClBancoChilePersonasProductsResponseModel.fromJson(
        response.data ?? {},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != null &&
          e.response!.statusCode! >= 300 &&
          e.response!.statusCode! < 400) {
        throw Exception('Session corrupted - needs reauth');
      }
      log('Error fetching BancoChile raw products: $e');
      rethrow;
    }
  }

  /// Gets depositary balances
  Future<List<ClBancoChilePersonasDepositaryBalancesResponseModel>>
  _getDepositaryBalances(String cookiesString) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/bff-pp-prod-ctas-saldos/productos/cuentas/saldos',
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': cookiesString,
          },
        ),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (e) =>
                ClBancoChilePersonasDepositaryBalancesResponseModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      log('Error fetching BancoChile depositary balances: $e');
      rethrow;
    }
  }

  /// Gets cards balances
  Future<List<ClBancoChilePersonasCardsBalancesResponseModel>>
  _getCardsBalances(String cookiesString) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/tarjetas/widget/saldos-tarjetas',
        data: <String, dynamic>{},
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': cookiesString,
          },
        ),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (e) => ClBancoChilePersonasCardsBalancesResponseModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      log('Error fetching BancoChile card balances: $e');
      rethrow;
    }
  }
}
