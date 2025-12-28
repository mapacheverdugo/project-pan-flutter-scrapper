import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

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

      final rutSelector = "#login-retail-content-card-form-input-dni-input";
      final passwordSelector =
          "#login-retail-content-card-form-input-password-input";

      await webview.waitForSelector(rutSelector);

      log("ScotiabankService auth selector $rutSelector founded");

      await webview.type(rutSelector, username);
      await webview.type(passwordSelector, password);
      await webview.tap("#login-retail-content-card-form > button");

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

  @override
  Future<List<Transaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    throw UnimplementedError(
      'Scotiabank depositary account transactions not implemented',
    );
  }

  @override
  Future<List<CreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    try {
      final rawId = productId;
      final cardLast4Digits = rawId.length >= 4
          ? rawId.substring(rawId.length - 4)
          : rawId;

      // Get card ID for bill periods
      final cardId = await _getCardIdForBillPeriods(
        credentials,
        cardLast4Digits,
      );
      if (cardId == null) {
        throw Exception('Card not found');
      }

      // Get bill period details
      final billPeriodDetail = await _getCardBillPeriodDetail(
        credentials,
        cardId,
      );

      final periods = <CreditCardBillPeriod>[];
      final lstConsulta =
          billPeriodDetail['lstConsultaEstadoVisaEnc'] as Map<String, dynamic>?;
      if (lstConsulta != null) {
        final tipo = lstConsulta['tipo'] as List<dynamic>? ?? [];
        final fecfac = lstConsulta['fecfac'] as List<dynamic>? ?? [];
        final fecproxpag = lstConsulta['fecproxpag'] as List<dynamic>? ?? [];

        for (int i = 0; i < tipo.length && i < fecfac.length; i++) {
          final type = tipo[i].toString();
          final billingDate = fecfac[i].toString();
          final paymentDueDate = fecproxpag[i].toString();

          if (billingDate == '00000000') continue;

          final currencyType = type == 'I'
              ? CurrencyType.international
              : CurrencyType.national;
          final currency = currencyType == CurrencyType.international
              ? 'USD'
              : 'CLP';

          // Parse DDMMYYYY to YYYY-MM-DD
          final startDate = _parseScotiabankDate(billingDate);
          final endDate = paymentDueDate != '00000000'
              ? _parseScotiabankDate(paymentDueDate)
              : null;

          final periodId = '$cardId|$billingDate|${currencyType.name}';

          periods.add(
            CreditCardBillPeriod(
              id: periodId,
              startDate: startDate,
              endDate: endDate,
              currency: currency,
              currencyType: currencyType,
            ),
          );
        }
      }

      return periods;
    } catch (e) {
      log('Error fetching Scotiabank card bill periods: $e');
      rethrow;
    }
  }

  String _parseScotiabankDate(String dateString) {
    // Format: DDMMYYYY
    if (dateString.length != 8) {
      throw Exception('Invalid date format: $dateString');
    }
    final day = dateString.substring(0, 2);
    final month = dateString.substring(2, 4);
    final year = dateString.substring(4, 8);
    return '$year-$month-$day';
  }

  Future<String?> _getCardIdForBillPeriods(
    String cookieString,
    String cardLast4Digits,
  ) async {
    try {
      final referer =
          'https://www.scotiabank.cl/mfe-simple-account-statement-web-cl/?tab=saldo';

      final response = await _templateRequest<Map<String, dynamic>>(
        cookieString: cookieString,
        template: '/visa/lstTarjetaSaldosEnc.json',
        referer: referer,
        intends: null,
      );

      final l09000 = response['L09000'] as Map<String, dynamic>?;
      final cards = l09000?['cards'] as List<dynamic>? ?? [];

      for (final card in cards) {
        final cardMap = card as Map<String, dynamic>;
        final prd = cardMap['prd'] as String? ?? '';
        if (prd.endsWith(cardLast4Digits)) {
          return cardMap['prdoriid'] as String?;
        }
      }

      return null;
    } catch (e) {
      log('Error getting card ID for bill periods: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getCardBillPeriodDetail(
    String cookieString,
    String prdoriid,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _dio.get<Map<String, dynamic>>(
        'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax?TMPL=%2Fahorro%2FsaldoEnc.json&TRANS=vt_ConsultaEstadoVisaEnc&cta=$prdoriid&_=$timestamp',
        options: Options(headers: {..._headers, 'Cookie': cookieString}),
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching card bill period detail: $e');
      rethrow;
    }
  }

  @override
  Future<CreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError('Scotiabank credit card bill not implemented');
  }

  @override
  Future<Uint8List> getCreditCardBillPdf(
    String credentials,
    String productId,
    String periodId,
  ) async {
    try {
      // Parse periodId: format is "prdoriid|billingDate|currencyType"
      final periodParts = periodId.split('|');
      if (periodParts.length < 3) {
        throw Exception('Invalid period ID format');
      }
      final rawPrdoriid = periodParts[0];
      final rawBillingDate = periodParts[1]; // DDMMYYYY format
      final rawCurrencyType = periodParts[2];

      final currencyType = rawCurrencyType == CurrencyType.national.name
          ? CurrencyType.national
          : CurrencyType.international;

      final referer =
          'https://www.scotiabank.cl/mfe-simple-account-statement-web-cl/?tab=saldo';

      // Get JWT token
      final jwtResponse = await _dio.get<Map<String, dynamic>>(
        'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax?TMPL=%2Fsecurity%2Fjwt.xml&intends=T18000',
        options: Options(
          headers: {..._headers, 'Referer': referer, 'Cookie': credentials},
        ),
      );
      final token = jwtResponse.data?['token'] as String?;
      if (token == null) {
        throw Exception('Failed to get JWT token');
      }

      // Get bill data
      Map<String, dynamic> billData;
      if (currencyType == CurrencyType.national) {
        final fecPag = '00000000';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final llamadaResponse = await _dio.get<Map<String, dynamic>>(
          'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax?TMPL=%2Fahorro%2Ftarjeta.json&_=$timestamp',
          options: Options(headers: {..._headers, 'Cookie': credentials}),
        );
        final llamada = llamadaResponse.data?['Llamada'] as String? ?? '';

        final billResponse = await _dio.get<Map<String, dynamic>>(
          'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax?TMPL=%2Fvisa%2Festctatarpdfant.json&TRANS=vt_ConsultaEstadoVisaAntNacEnc&cta=$rawPrdoriid&FecPag=$fecPag&FecFac=$rawBillingDate&Llamada=$llamada',
          options: Options(headers: {..._headers, 'Cookie': credentials}),
        );
        billData = {
          'lstEstadoNacVisa': billResponse.data?['lstEstadoNacVisaAnt'],
        };
      } else {
        final fecPag = '00000000';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final llamadaResponse = await _dio.get<Map<String, dynamic>>(
          'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax?TMPL=%2Fahorro%2Ftarjeta.json&_=$timestamp',
          options: Options(headers: {..._headers, 'Cookie': credentials}),
        );
        final llamada = llamadaResponse.data?['Llamada'] as String? ?? '';

        final billResponse = await _dio.get<Map<String, dynamic>>(
          'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax?TMPL=%2Fvisa%2FestctatarpdfintEnc.json&TRANS=vt_EstadoVisaIntEncBanDig&cta=$rawPrdoriid&FecPag=$fecPag&FecFac=$rawBillingDate&Llamada=$llamada',
          options: Options(headers: {..._headers, 'Cookie': credentials}),
        );
        billData = {
          'lstEstadoIntVisaAnt': billResponse.data?['lstEstadoIntVisaAntEnc'],
        };
      }

      // Determine template
      final template = currencyType == CurrencyType.national
          ? 'estado_cta_trj'
          : 'estado_cta_trj_int';

      // Prepare form data
      final encodedData = jsonEncode(billData);
      final formData = {
        'format': 'pdf',
        'option': 'inline',
        'template': template,
        'data': encodedData,
      };

      final response = await _dio.post(
        'https://www.scotiabank.cl/app-web-report/getReportSecure',
        data: formData,
        options: Options(
          headers: {
            ..._headers,
            'Referer': referer,
            'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching Scotiabank credit card bill PDF: $e');
      rethrow;
    } catch (e) {
      log('Error fetching Scotiabank credit card bill PDF: $e');
      rethrow;
    }
  }
}
