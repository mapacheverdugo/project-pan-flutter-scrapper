import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/services/connection/connection_exception.dart';
import 'package:pan_scrapper/services/connection/connection_service.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_scotiabank_personas/credit_card_unbilled_transaction_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_scotiabank_personas/depositary_transaction_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_scotiabank_personas/product_mapper.dart';
import 'package:pan_scrapper/services/connection/models/cl_scotiabank_personas/card_details_response_model.dart';
import 'package:pan_scrapper/services/connection/models/cl_scotiabank_personas/card_with_details_model.dart';
import 'package:pan_scrapper/services/connection/models/cl_scotiabank_personas/index.dart';
import 'package:pan_scrapper/services/connection/webview/webview.dart';

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
        urls: [
          Uri.parse("https://www.scotiabank.cl/"),
          Uri.parse("https://banco.scotiabank.cl"),
        ],
      );

      await webview.close();

      final cookieString = cookies
          .map((e) => '${e.name}=${e.value}')
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
  Future<List<ExtractedProductModel>> getProducts(String credentials) async {
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
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
      }
      rethrow;
    }
  }

  /// Gets passport token for API requests
  Future<String> _getPassportToken(
    String cookieString,
    String referer, {
    String? intends,
  }) async {
    try {
      final response = await _templateRequest<Map<String, dynamic>>(
        cookieString: cookieString,
        template: '/security/passport.json',
        referer: referer,
        intends: intends,
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
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
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
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
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
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
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
  Future<List<ExtractedTransaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    try {
      // Parse product ID to get type
      final productIdMetadata =
          ClScotiabankPersonasProductMapper.parseProductId(productId);

      final rawType = productIdMetadata.rawType;
      final isCreditLine = rawType == 'LICRED';

      // Get session data to find the account prd
      final sessionData = await _getSessionData(credentials);

      // Get prd from T01000 for depositary accounts or T01100 for credit lines
      final sessionKey = isCreditLine ? 'T01100' : 'T01000';
      final sessionEntry = sessionData[sessionKey] as Map<String, dynamic>?;

      if (sessionEntry == null) {
        throw Exception('Session entry $sessionKey not found');
      }

      final prd = sessionEntry['prd'];
      if (prd == null) {
        throw Exception('Account prd not found in session for $sessionKey');
      }

      // Handle prd as string or list
      final cta = prd is List ? prd.first.toString() : prd.toString();

      // Determine codprd based on type
      final codprd = isCreditLine ? '02000' : '01000';

      // Calculate date range: today - 45 days to today + 3 days
      final now = DateTime.now();
      final startDateTime = now.subtract(const Duration(days: 45));
      final endDateTime = now.add(const Duration(days: 3));

      final startDateString = startDateTime.toIso8601String().split('T')[0];
      final endDateString = endDateTime.toIso8601String().split('T')[0];

      final startDateParts = startDateString.split('-');
      final endDateParts = endDateString.split('-');

      // Format dates as YYYYMMDD
      final fecini = startDateParts.join('');
      final fecfin = endDateParts.join('');

      final codtrs = isCreditLine ? "T01100" : "T01000";
      final trans = "vt_TraeCartolaHistCtaCte";
      final tmpl = "/admin/ftp.html";

      // Extract date components: startDateParts is [year, month, day]
      final idd = startDateParts[2]; // day
      final imm = startDateParts[1]; // month
      final iaa = startDateParts[0]; // year

      final fdd = endDateParts[2]; // day
      final fmm = endDateParts[1]; // month
      final faa = endDateParts[0]; // year

      // Build request parameters map for the new download endpoint
      final params = <String, String>{
        'TRANS': trans,
        'TMPL': tmpl,
        'XFMT': '1',
        'cta': cta,
        'codtrs': codtrs,
        'codprd': codprd,
        'fecini': fecini,
        'fecfin': fecfin,
      };

      // Build referer URL - credit lines need date components and Aceptar params
      final downloadReferer = isCreditLine
          ? 'https://www.scotiabank.cl/cgi-bin/transac/dotrx?codprd=$codprd&codtrs=$codtrs&fecini=$fecini&fecfin=$fecfin&TRANS=vt_CartolaHistCtaCte&TMPL=%2Fctacte%2Fdetcartolahis.html&cta=$cta&idd=$idd&imm=$imm&iaa=$iaa&fdd=$fdd&fmm=$fmm&faa=$faa&Aceptar.x=32&Aceptar.y=12'
          : 'https://www.scotiabank.cl/cgi-bin/transac/dotrx?codprd=$codprd&codtrs=$codtrs&fecini=$fecini&fecfin=$fecfin&TRANS=vt_CartolaHistCtaCte&TMPL=%2Fctacte%2Fdetcartolahis.html&cta=$cta';

      final response = await _dio.get<String>(
        'https://www.scotiabank.cl/api/sweb/jo-scotiaweb-cgi-java/download',
        queryParameters: params,
        options: Options(
          headers: {
            ..._headers,
            'Cookie': credentials,
            'Referer': downloadReferer,
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'es-419,es;q=0.9,en;q=0.8',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'same-origin',
            'Sec-Fetch-User': '?1',
            'Upgrade-Insecure-Requests': '1',
          },
          responseType: ResponseType.plain,
        ),
      );

      final data = response.data ?? '';
      log(
        'Scotiabank depositary account transactions data length: ${data.length}',
      );

      // Parse and map transactions
      return ClScotiabankPersonasDepositaryTransactionMapper.fromResponse(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
      }
      log('Error fetching Scotiabank depositary account transactions: $e');
      rethrow;
    } catch (e) {
      log('Error fetching Scotiabank depositary account transactions: $e');
      rethrow;
    }
  }

  /// Gets session data from /admin/session.json
  Future<Map<String, dynamic>> _getSessionData(String cookieString) async {
    try {
      final referer =
          'https://www.scotiabank.cl/mfe/sweb/mfe-shell-web-cl/mfe/mfe/sweb/mfe-home-cl/';

      final response = await _dio.get<Map<String, dynamic>>(
        'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax',
        queryParameters: {'TMPL': '/admin/session.json'},
        options: Options(
          headers: {..._headers, 'Cookie': cookieString, 'Referer': referer},
        ),
      );

      return response.data ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
      }
      log('Error getting session data: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedCreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    try {
      // Parse product ID to get displayId (cardId)
      final productIdMetadata =
          ClScotiabankPersonasProductMapper.parseProductId(productId);
      final rawId = productIdMetadata.rawDisplayId;
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

      final periods = <ExtractedCreditCardBillPeriod>[];
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
              ? Currency.usd
              : Currency.clp;

          // Parse DDMMYYYY to YYYY-MM-DD
          final startDate = _parseScotiabankDate(billingDate);
          final endDate = paymentDueDate != '00000000'
              ? _parseScotiabankDate(paymentDueDate)
              : null;

          final periodId = '$cardId|$billingDate|${currencyType.name}';

          periods.add(
            ExtractedCreditCardBillPeriod(
              providerId: periodId,
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
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
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
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
      }
      log('Error fetching Scotiabank credit card bill PDF: $e');
      rethrow;
    } catch (e) {
      log('Error fetching Scotiabank credit card bill PDF: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedTransaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  ) async {
    try {
      // Parse product ID to get displayId (cardId)
      final productIdMetadata =
          ClScotiabankPersonasProductMapper.parseProductId(productId);
      final rawId = productIdMetadata.rawDisplayId;
      final cardLast4Digits = rawId.length >= 4
          ? rawId.substring(rawId.length - 4)
          : rawId;

      final referer =
          'https://www.scotiabank.cl/mfe-simple-account-statement-web-cl/?tab=movimientos-no-facturados';

      // Get card list to find the card by last 4 digits
      final cardsResponse = await _templateRequest<Map<String, dynamic>>(
        cookieString: credentials,
        template: '/visa/lstTarjetaSaldosEnc.json',
        referer: referer,
        intends: null,
      );

      final l09000 = cardsResponse['L09000'] as Map<String, dynamic>?;
      final cards = l09000?['cards'] as List<dynamic>? ?? [];

      // Find the card matching last 4 digits
      String? prdoriid;
      for (final card in cards) {
        final cardMap = card as Map<String, dynamic>;
        final prd = cardMap['prd'] as String? ?? '';
        if (prd.endsWith(cardLast4Digits)) {
          prdoriid = cardMap['prdoriid'] as String?;
          break;
        }
      }

      if (prdoriid == null) {
        throw Exception('Card not found for last 4 digits: $cardLast4Digits');
      }

      // Get unbilled transactions
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _dio.get<Map<String, dynamic>>(
        'https://www.scotiabank.cl/cgi-bin/transac/dotrxajax',
        queryParameters: {
          'TMPL': '/ahorro/saldoNFEnc.json',
          'TRANS': 'vt_UltimosMovVisaEnc',
          'visa': prdoriid,
          'rellamado': '0',
          '_': timestamp.toString(),
        },
        options: Options(
          headers: {..._headers, 'Referer': referer, 'Cookie': credentials},
        ),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from unbilled transactions endpoint');
      }

      // Parse response
      final responseModel =
          ClScotiabankPersonasCardUnbilledTransactionsResponseModel.fromJson(
            data,
          );

      return ClScotiabankPersonasCreditCardUnbilledTransactionMapper.fromResponseModel(
        responseModel,
        transactionType,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ConnectionException(
          ConnectionExceptionType.authCredentialsExpired,
        );
      }
      log('Error fetching Scotiabank credit card unbilled transactions: $e');
      rethrow;
    } catch (e) {
      log('Error fetching Scotiabank credit card unbilled transactions: $e');
      rethrow;
    }
  }
}
