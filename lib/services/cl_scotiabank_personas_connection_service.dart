import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/services/mappers/cl_scotiabank_personas/product_mapper.dart';
import 'package:pan_scrapper/services/models/cl_scotiabank_personas/card_details_response_model.dart';
import 'package:pan_scrapper/services/models/cl_scotiabank_personas/card_with_details_model.dart';
import 'package:pan_scrapper/services/models/cl_scotiabank_personas/index.dart';
import 'package:pan_scrapper/webview/webview.dart';

class ClScotiabankPersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  ClScotiabankPersonasConnectionService(this._dio, this._webviewFactory);

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'es-419,es;q=0.6',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-GPC': '1',
  };

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
        urls: [Uri.parse("https://www.scotiabank.cl/")],
      );

      await webview.close();

      final cookieString = cookies.map((e) => '${e.name}=${e.value}').join(';');

      log("ScotiabankService auth completed with: $cookieString");

      return cookieString;
    } catch (e) {
      await webview.close();
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts(String credentials) async {
    try {
      final referer =
          'https://www.scotiabank.cl/mfe/sweb/mfe-shell-web-cl/mfe/mfe/sweb/mfe-home-cl/';

      // Get passport token
      final token = await _getPassportToken(credentials, referer);

      // Get depositary accounts
      final depositaryAccounts = await _getDepositaryAccount(
        token,
        credentials,
      );

      // Get cards with details
      final cards = await _getCards(token, credentials);
      final cardsWithDetails = await _getCardsWithDetails(
        cards,
        token,
        credentials,
      );

      // Map to Product models
      final parsedDepositaryAccounts =
          ClScotiabankPersonasProductMapper.fromDepositaryAccounts(
            depositaryAccounts,
          );
      final parsedCardsBalances =
          ClScotiabankPersonasProductMapper.fromCreditCards(cardsWithDetails);

      return [...parsedDepositaryAccounts, ...parsedCardsBalances];
    } catch (e) {
      log('Error fetching products: $e');
      rethrow;
    }
  }

  /// Makes a template request to the dotrxajax endpoint
  Future<T> _templateRequest<T>({
    required String cookieString,
    required String template,
    String? referer,
    String? intends,
  }) async {
    final params = <String, dynamic>{
      'TMPL': template,
      'intends': intends ?? '',
    };

    final headers = <String, dynamic>{
      ..._headers,
      'Cookie': cookieString,
      if (referer != null) 'Referer': referer,
    };

    try {
      final response = await _dio.get<T>(
        'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax',
        queryParameters: params,
        options: Options(headers: headers),
      );

      log('templateRequest response.data: ${response.data}');

      return response.data!;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      rethrow;
    }
  }

  /// Gets passport token for API requests
  Future<String> _getPassportToken(String cookieString, String referer) async {
    try {
      final response = await _templateRequest<Map<String, dynamic>>(
        cookieString: cookieString,
        template: '/security/passport.json',
        referer: referer,
      );

      log('getPassportToken response: $response');

      return response['token'] as String;
    } catch (e) {
      log('Error getting passport token: $e');
      rethrow;
    }
  }

  /// Gets depositary accounts
  Future<List<ClScotiabankPersonasDepositaryAccountResponseModel>>
  _getDepositaryAccount(String token, String cookieString) async {
    try {
      final referer =
          'https://www.scotiabank.cl/mfe/sweb/mfe-shell-web-cl/mfe/mfe/sweb/mfe-home-cl/';

      final response = await _dio.get<List<dynamic>>(
        'https://www.scotiabank.cl/api/clservices/bff-home-main-web/v1/accounts',
        options: Options(
          headers: {
            ..._headers,
            'Authorization': 'Bearer $token',
            'Referer': referer,
            'Cookie': cookieString,
          },
        ),
      );

      if (response.data == null) {
        return [];
      }

      return (response.data as List)
          .map(
            (json) =>
                ClScotiabankPersonasDepositaryAccountResponseModel.fromJson(
                  json as Map<String, dynamic>,
                ),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      rethrow;
    }
  }

  /// Gets cards balances
  Future<List<ClScotiabankPersonasCardResponseModel>> _getCards(
    String token,
    String cookieString,
  ) async {
    try {
      final referer =
          'https://www.scotiabank.cl/mfe/sweb/mfe-shell-web-cl/mfe/mfe/sweb/mfe-home-cl/';

      final response = await _dio.get<List<dynamic>>(
        'https://www.scotiabank.cl/api/clservices/bff-home-main-web/v1/cards',
        options: Options(
          headers: {
            ..._headers,
            'Referer': referer,
            'Authorization': 'Bearer $token',
            'Cookie': cookieString,
          },
        ),
      );

      if (response.data == null) {
        return [];
      }

      return (response.data as List)
          .map(
            (json) => ClScotiabankPersonasCardResponseModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      rethrow;
    }
  }

  /// Gets card detail by cardKey
  Future<ClScotiabankPersonasCardDetailsResponseModel> _getCardDetail(
    String token,
    String cardKey,
    String cookieString,
  ) async {
    try {
      final referer =
          'https://www.scotiabank.cl/mfe/sweb/mfe-shell-web-cl/mfe/mfe/sweb/mfe-home-cl/';

      final response = await _dio.get<Map<String, dynamic>>(
        'https://www.scotiabank.cl/api/clservices/bff-home-main-web/v1/cards/$cardKey',
        options: Options(
          headers: {
            ..._headers,
            'Authorization': 'Bearer $token',
            'Referer': referer,
            'Cookie': cookieString,
          },
        ),
      );

      return ClScotiabankPersonasCardDetailsResponseModel.fromJson(
        response.data!,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      rethrow;
    }
  }

  Future<List<ClScotiabankPersonasCardWithDetailsModel>> _getCardsWithDetails(
    List<ClScotiabankPersonasCardResponseModel> cards,
    String token,
    String cookieString,
  ) async {
    final cardsWithDetails = await Future.wait(
      cards.map((card) async {
        final details = await _getCardDetail(token, card.key!, cookieString);
        return ClScotiabankPersonasCardWithDetailsModel(
          card: card,
          details: details,
        );
      }),
    );
    return cardsWithDetails;
  }
}
