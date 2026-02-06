import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    hide CookieManager;
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/services/connection/connection_exception.dart';
import 'package:pan_scrapper/services/connection/connection_service.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_itau_personas/credit_card_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_itau_personas/credit_card_unbilled_transaction_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_itau_personas/depositary_transaction_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_itau_personas/product_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/common.dart';
import 'package:pan_scrapper/services/connection/webview/webview.dart';
import 'package:pan_scrapper/utils/logger.dart';

class ClItauPersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function({String? cookies}) _webviewFactory;

  ClItauPersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(
    String username,
    String password, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      talker.info("ItauService auth - opening login page");

      webview.addShouldOverrideUrlLoadingListener(
        RegExp(r'https://banco.itau.cl/wps/myportal/newolb/web/home/newhome.*'),
        (navigationAction) async {
          if (!completer.isCompleted) {
            completer.complete('true');
          }
          return NavigationActionPolicy.ALLOW;
        },
      );

      // Navigate to the login page
      await webview.navigate(
        URLRequest(
          url: WebUri('https://banco.itau.cl/wps/portal/newolb/web/login'),
        ),
      );

      talker.info("ItauService auth after navigate");

      final rutSelector = '#loginNameID';
      final passwordSelector = '#pswdId';
      final submitButtonSelector = '#btnLoginPortal';

      // Wait for the RUT input to be available
      await webview.waitForSelector(
        rutSelector,
        timeout: Duration(seconds: 30),
      );

      await webview.type(rutSelector, username);
      await webview.type(passwordSelector, password);

      await webview.tap(submitButtonSelector);

      talker.info("ItauService auth submit clicked, waiting...");

      await completer.future.timeout(
        Duration(seconds: 60),
        onTimeout: () async {
          throw Exception('Timeout waiting for login success');
        },
      );

      final cookies = await webview.cookies(
        urls: [Uri.parse('https://banco.itau.cl/')],
      );

      await webview.close();

      final cookieString = cookies
          .map((e) => '${e.name}=${e.value}')
          .join('; ');

      talker.info("ItauService auth completed - cookies extracted");

      return cookieString;
    } catch (e) {
      await webview.close();
      talker.error('Itau auth error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedProductModel>> getProducts(String credentials) async {
    final depositaryAccounts = await _getDepositaryAccounts(credentials);
    final creditCards = await _getCreditCards(credentials);
    return [...depositaryAccounts, ...creditCards];
  }

  Future<List<_DepositaryAccountData>> _getDepositaryAccountsData(
    String credentials,
  ) async {
    final accounts = <_DepositaryAccountData>[];

    final homeResp = await _dio.get(
      'https://banco.itau.cl/wps/myportal/newolb/web/home/newhome',
      options: Options(
        headers: {'Cookie': credentials},
        followRedirects: true,
        maxRedirects: 10,
      ),
    );

    await _checkDioResponse(homeResp);

    final homeHtml = homeResp.data.toString();

    final homeRespUrl = homeResp.realUri;

    final homeDoc = parse(homeHtml);

    final cuentaIds = homeDoc
        .querySelectorAll('select#comboCuentas option[value]')
        .map((o) => (o.attributes['value'] ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toList();

    if (cuentaIds.isEmpty) return accounts;

    final linkElement = homeDoc.querySelector(
      'a[href*="_gen_call_onChangeCuenta"]',
    );

    final href = linkElement?.attributes['href']?.trim();
    if (href == null) {
      talker.error(
        'Itau: no se encontró el link para cambiar cuenta (comboCuentas).',
      );
      return accounts;
    }

    final form = homeDoc.querySelector('#filterCtaSaldo');
    if (form == null) {
      talker.error(
        'Itau: no se encontró el form para cambiar cuenta (comboCuentas).',
      );
      return accounts;
    }

    final baseUrl = 'https://${homeRespUrl.host}';

    final navStateUrl = homeDoc
        .getElementById('com.ibm.lotus.NavStateUrl')
        ?.attributes['href'];

    final actionUrl = '$baseUrl$href';

    for (final cuentaId in cuentaIds) {
      final basePayload = _extractFormFieldsFromElement(form);

      final commonHeaders = <String, String>{
        'Cookie': credentials,
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': '*/*',
        'Referer': 'https://banco.itau.cl/wps/myportal/newolb/web/home/newhome',
      };

      final payload = Map<String, dynamic>.from(basePayload);
      payload['comboCuentas'] = cuentaId;

      final resp = await _dio.post(
        actionUrl,
        data: payload,
        options: Options(
          headers: commonHeaders,
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
        ),
      );

      await _checkDioResponse(resp);

      final html = resp.data.toString();

      accounts.add(
        _DepositaryAccountData(id: cuentaId, url: navStateUrl, html: html),
      );
    }
    return accounts;
  }

  Future<List<ExtractedProductModel>> _getDepositaryAccounts(
    String credentials,
  ) async {
    try {
      final products = <ExtractedProductModel>[];

      final accounts = await _getDepositaryAccountsData(credentials);

      for (final account in accounts) {
        final parsedProducts =
            ClItauPersonasProductMapper.parseDepositaryProductFromResponse(
              cuentaId: account.id,
              fragmentHtml: account.html,
            );

        products.addAll(parsedProducts);
      }

      return products;
    } catch (e) {
      if (e is DioException) {
        await _checkDioException(e);
      }
      talker.error('Itau get depositary accounts error: $e');
      rethrow;
    }
  }

  /// Extracts form fields (inputs and selects) from any element
  Map<String, dynamic> _extractFormFieldsFromElement(Element element) {
    final fields = <String, dynamic>{};

    // inputs
    for (final input in element.querySelectorAll('input[name]')) {
      final name = input.attributes['name']?.trim();
      if (name == null || name.isEmpty) continue;

      // ignore unchecked radio/checkbox
      final type = (input.attributes['type'] ?? '').toLowerCase();
      if ((type == 'checkbox' || type == 'radio') &&
          !input.attributes.containsKey('checked')) {
        continue;
      }

      fields[name] = (input.attributes['value'] ?? '').trim();
    }

    // selects (si el form tiene selects con selected)
    for (final sel in element.querySelectorAll('select[name]')) {
      final name = sel.attributes['name']?.trim();
      if (name == null || name.isEmpty) continue;

      final selected =
          sel.querySelector('option[selected]') ?? sel.querySelector('option');
      final value = (selected?.attributes['value'] ?? '').trim();
      if (value.isNotEmpty) fields[name] = value;
    }

    return fields;
  }

  Future<List<ExtractedProductModel>> _getCreditCards(
    String credentials,
  ) async {
    try {
      final response = await _dio.get(
        'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/deuda',
        options: Options(headers: {'Cookie': credentials}),
      );
      final html = response.data.toString();

      await _checkDioResponse(response);

      final products = ClItauPersonasCreditCardMapper.parseCreditCard(html);
      return products;
    } catch (e) {
      talker.error('Itau get products error: $e');
      if (e is DioException) {
        await _checkDioException(e);
      }
      rethrow;
    }
  }

  @override
  Future<List<ExtractedTransaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    try {
      final productCodeById = productId.split('_')[0];

      final transactions = <ExtractedTransaction>[];

      final initialUrl = switch (productCodeById) {
        'CA' =>
          'https://banco.itau.cl/wps/myportal/newolb/web/cuentas/cuenta-corriente/cartola-historica',
        'CU' =>
          'https://banco.itau.cl/wps/myportal/newolb/web/cuentas/cuenta-en-dolares/cartola-historica',
        'LC|CA' =>
          'https://banco.itau.cl/wps/myportal/newolb/web/cuentas/linea-credito/cartola-historica',
        _ => null,
      };

      if (initialUrl == null) {
        throw Exception(
          'Itau: no se encontró la URL inicial para $productCodeById',
        );
      }

      final initialResponse = await _dio.get(
        initialUrl,
        options: Options(headers: {'Cookie': credentials}),
      );
      final initialHtml = initialResponse.data.toString();
      final initialDoc = parse(initialHtml);

      final loadedMonthYear = initialDoc
          .querySelector('#resultShow')
          ?.attributes['value']
          ?.trim();

      if (loadedMonthYear == null) {
        throw Exception('Itau: no se encontró el mes y año cargados');
      }

      final baseHref = initialDoc
          .getElementsByTagName('base')[0]
          .attributes['href']
          ?.trim();
      if (baseHref == null) {
        throw Exception('Itau: no se encontró el base href');
      }

      final initialTransactions =
          await _getDepositaryAccountTransactionsFromAllPages(
            initialHtml,
            baseHref,
            credentials,
          );

      transactions.addAll(initialTransactions);

      final uri = initialDoc
          .querySelector('#formularioSelect a')
          ?.attributes['href']
          ?.trim();
      if (uri == null) {
        throw Exception('Itau: no se encontró el link para seleccionar el mes');
      }

      final currentMonth = DateTime.now().month;
      final currentMonthParsed = currentMonth.toString().padLeft(2, '0');
      final currentYear = DateTime.now().year;
      final currentYearParsed = currentYear;

      final previousMonth = currentMonth == 1 ? 12 : currentMonth - 1;
      final previousMonthParsed = previousMonth.toString().padLeft(2, '0');
      final previousMonthYearParsed = currentMonth == 1
          ? currentYear - 1
          : currentYear;

      final isCurrentMonth =
          loadedMonthYear == '$currentMonthParsed / $currentYearParsed';
      final isPreviousMonth =
          loadedMonthYear == '$previousMonthParsed / $previousMonthYearParsed';

      if (!isCurrentMonth && !isPreviousMonth) {
        throw Exception('Itau: no se encontró el mes y año cargados');
      }

      final arg = 'CM';
      final bowStEvent =
          'portlets/cuentas/cartolas/CartolaHistoricaPortlet!fireEvent:Form:ip_cartolaHistorica_SaveDataSubmitEvent';

      final currentMonthData = {
        'al_cartolaHistorica_Arg1': arg,
        '_bowStEvent': bowStEvent,
        'resultShow': '$currentMonthParsed / $currentYearParsed',
        'fecha': '$currentMonthParsed $currentYearParsed',
        'Mes': currentMonthParsed,
        'Anio': currentYearParsed.toString(),
      };

      final previousMonthData = {
        'al_cartolaHistorica_Arg1': arg,
        '_bowStEvent': bowStEvent,
        'resultShow': '$previousMonthParsed / $previousMonthYearParsed',
        'fecha': '$previousMonthParsed $previousMonthYearParsed',
        'Mes': previousMonthParsed,
        'Anio': previousMonthYearParsed.toString(),
      };

      final data = isCurrentMonth ? previousMonthData : currentMonthData;

      final otherMonthUrl = '$baseHref$uri';

      final otherMonthResponse = await _dio.post(
        otherMonthUrl,
        data: data,
        options: Options(
          headers: {'Cookie': credentials, 'Referrer': initialUrl},
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
        ),
      );
      await _checkDioResponse(otherMonthResponse);

      final otherMonthHtml = otherMonthResponse.data.toString();

      transactions.addAll(
        ClItauPersonasDepositaryTransactionMapper.fromCartolaHtml(
          otherMonthHtml,
        ),
      );

      return transactions;
    } catch (e) {
      if (e is DioException) {
        await _checkDioException(e);
      }
      talker.error('Itau get depositary account transactions error: $e');
      rethrow;
    }
  }

  Future<List<ExtractedTransaction>>
  _getDepositaryAccountTransactionsFromAllPages(
    String html,
    String initialUrl,
    String credentials,
  ) async {
    final htmlDoc = parse(html);

    final transactions = <ExtractedTransaction>[];
    final firstPageTransactions =
        ClItauPersonasDepositaryTransactionMapper.fromCartolaHtml(html);

    transactions.addAll(firstPageTransactions);

    if (firstPageTransactions.isNotEmpty) {
      var nextRightOnElement = htmlDoc.querySelector(
        'img[src*="next_right_on.png"]',
      );
      while (nextRightOnElement != null) {
        final nextRightOnElementFather = nextRightOnElement.parent;
        talker.info(
          'Itau: next right on element father: $nextRightOnElementFather',
        );

        if (nextRightOnElementFather == null) {
          nextRightOnElement = null;
          break;
        }

        final uri = nextRightOnElementFather.attributes['href'];

        final nextPageUrl = "$initialUrl$uri";

        final nextPageResponse = await _dio.get(
          nextPageUrl,
          options: Options(headers: {'Cookie': credentials}),
        );

        final nextPageHtml = nextPageResponse.data.toString();
        final nextPageDoc = parse(nextPageHtml);

        final nextPageTransactions =
            ClItauPersonasDepositaryTransactionMapper.fromCartolaHtml(
              nextPageHtml,
            );
        transactions.addAll(nextPageTransactions);

        nextRightOnElement = nextPageDoc.querySelector(
          'img[src*="next_right_on.png"]',
        );
      }
    }

    return transactions;
  }

  @override
  Future<List<ExtractedCreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    try {
      final commonHeaders = <String, String>{
        'Cookie': credentials,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Referer':
            'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/deuda',
        'Origin': 'https://banco.itau.cl',
      };

      // Get periods for both nacional and internacional
      final nacionalPeriods = await _getPeriodsForCurrencyType(
        credentials,
        productId,
        'nacional',
        commonHeaders,
      );

      final internacionalPeriods = await _getPeriodsForCurrencyType(
        credentials,
        productId,
        'internacional',
        commonHeaders,
      );

      return [...nacionalPeriods, ...internacionalPeriods];
    } catch (e) {
      if (e is DioException) {
        await _checkDioException(e);
      }
      talker.error('Itau get credit card bill periods error: $e');
      rethrow;
    }
  }

  Future<List<ExtractedCreditCardBillPeriod>> _getPeriodsForCurrencyType(
    String credentials,
    String productId,
    String currencyType, // 'nacional' or 'internacional'
    Map<String, String> commonHeaders,
  ) async {
    final periods = <ExtractedCreditCardBillPeriod>[];
    const maxEmptyPeriods = 0; // Stop at first empty period

    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));

    final initialResponse = await _dio.get(
      'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/cuenta-$currencyType',
      options: Options(headers: commonHeaders),
    );

    await _checkDioResponse(initialResponse);

    final initialHtml = initialResponse.data.toString();
    final initialDoc = parse(initialHtml);

    final contentLocationUrlPath = initialResponse.headers.value(
      'content-location',
    );
    if (contentLocationUrlPath == null) {
      talker.error(
        'Itau: no se encontró el content-location para $currencyType',
      );
      return periods;
    }

    //await copyHtmlToClipboard(initialHtml);

    final initialResponseUri = initialResponse.realUri;

    final selectAccountFormSelector = 'form[name="comboForm"] a';
    final selectAccountFormElement = initialDoc.querySelector(
      selectAccountFormSelector,
    );
    final selectAccountFormActionUrlPath =
        selectAccountFormElement?.attributes['href'];
    if (selectAccountFormActionUrlPath == null) {
      talker.error(
        'Itau: no se encontró el link para seleccionar la cuenta para $currencyType',
      );
      return periods;
    }

    final selectAccountBaseUrl = contentLocationUrlPath.split('/dz/d5').first;

    final selectAccountFormUrl = initialResponseUri
        .resolve('$selectAccountBaseUrl/$selectAccountFormActionUrlPath')
        .toString();

    final selectedResponse = await _dio.post(
      selectAccountFormUrl,
      data: {'cuentaIdSelected': productId},
      options: Options(
        headers: commonHeaders,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );
    await _checkDioResponse(selectedResponse);
    final selectedResponseUri = selectedResponse.realUri;

    final selectedHtml = selectedResponse.data.toString();
    final selectedDoc = parse(selectedHtml);

    var emptyPeriodsCounter = 0;

    // Extract the initial period from resultShow input
    final periodoInputSelector = currencyType == 'nacional'
        ? '#periodo option'
        : '#periodo option';
    final periodoInput = selectedDoc.querySelector(periodoInputSelector);
    if (periodoInput == null) {
      talker.error('Itau: no se encontró el input periodo para $currencyType');
      return periods;
    }

    final initialPeriodValue = (periodoInput.attributes['value'] ?? '').trim();
    if (initialPeriodValue.isEmpty) {
      talker.error('Itau: resultShow está vacío para $currencyType');
      return periods;
    }

    final initialPeriod = _parsePeriod(initialPeriodValue);
    if (initialPeriod == null) {
      talker.error(
        'Itau: no se pudo parsear el periodo inicial: $initialPeriodValue',
      );
      return periods;
    }

    final isEmptyPeriod = _isEmptyPeriod(selectedHtml);
    if (isEmptyPeriod) {
      emptyPeriodsCounter++;
    } else {
      final period = _createBillPeriod(productId, initialPeriod, currencyType);
      periods.add(period);
    }

    // Extract base form fields from #formularioSelect for period requests
    final bowStEventInput = initialDoc.querySelector(
      '#formularioSelect input[name="_bowStEvent"]',
    );
    final bowStEventValue = bowStEventInput?.attributes['value']?.trim();
    if (bowStEventValue == null) {
      talker.error('Itau: no se encontró el value para _bowStEvent');
      return periods;
    }

    final periodFormFormSelector = currencyType == 'nacional'
        ? '#formularioSelect a[id^="wpf_action_ref_0portletstarjeta_creditoestadoEstadoDeudaNacionalPortlet_"]'
        : '#formularioSelect a[id^="wpf_action_ref_0portletstarjeta_creditoestadoEstadoDeudaInternacionalPortlet_"]';

    final periodFormFormAElement = initialDoc.querySelector(
      periodFormFormSelector,
    );
    final periodFormFormActionUrlPath =
        periodFormFormAElement?.attributes['href'];

    final formularioSelectFormUrl = selectedResponseUri
        .resolve('$contentLocationUrlPath/$periodFormFormActionUrlPath')
        .toString();

    var currentPeriod = initialPeriod;

    while (emptyPeriodsCounter <= maxEmptyPeriods) {
      try {
        final periodToRequest = currentPeriod.previousMonth();

        final response = await _requestPeriodData(
          credentials,
          formularioSelectFormUrl,
          commonHeaders,
          periodToRequest,
          currentPeriod,
          bowStEventValue,
        );

        final html = response.data.toString();
        final doc = parse(html);

        final periodoInput = doc.querySelector(periodoInputSelector);
        if (periodoInput == null) {
          if (currencyType == 'internacional') {
            break;
          }
          return periods;
        }

        final initialPeriodValue = (periodoInput.attributes['value'] ?? '')
            .trim();
        if (initialPeriodValue.isEmpty) {
          talker.error('Itau: resultShow está vacío para $currencyType');
          return periods;
        }

        currentPeriod = _parsePeriod(initialPeriodValue)!;
        final isEmptyPeriod = _isEmptyPeriod(html);
        if (isEmptyPeriod) {
          emptyPeriodsCounter++;
        } else {
          final period = _createBillPeriod(
            productId,
            currentPeriod,
            currencyType,
          );
          periods.add(period);
        }
      } catch (e) {
        talker.error('Itau: error requesting period data: $e');
        emptyPeriodsCounter++;
      }
    }

    return periods;
  }

  bool _isEmptyPeriod(String html) {
    final doc = parse(html);
    final contenido = doc.querySelector('#contenido');
    if (contenido == null) return true;
    final sinDatos = contenido.querySelector('#sinDatos');
    return sinDatos != null;
  }

  Future<Response> _requestPeriodData(
    String credentials,
    String url,
    Map<String, String> commonHeaders,
    _Period requestedPeriod,
    _Period requestedFromPeriod,
    String bowStEventValue,
  ) async {
    final requestHeaders = Map<String, String>.from(commonHeaders);
    requestHeaders['X-Requested-With'] = 'XMLHttpRequest';
    requestHeaders['Accept'] = '*/*';
    requestHeaders['Sec-Fetch-Dest'] = 'empty';
    requestHeaders['Sec-Fetch-Mode'] = 'cors';
    requestHeaders['Sec-Fetch-Site'] = 'same-origin';

    final data = {
      '_bowStEvent': bowStEventValue,
      'resultShow':
          '${requestedPeriod.month.toString().padLeft(2, '0')} / ${requestedPeriod.year}',
      'periodo':
          '${requestedFromPeriod.year}${requestedFromPeriod.month.toString().padLeft(2, '0')}${requestedFromPeriod.day?.toString().padLeft(2, '0')}',
      'fecha':
          '${requestedPeriod.year}${requestedPeriod.month.toString().padLeft(2, '0')}',
    };

    final response = await _dio.post(
      url,
      data: data,
      options: Options(
        headers: requestHeaders,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );
    await _checkDioResponse(response);
    return response;
  }

  _Period? _parsePeriod(String periodStr) {
    final year = int.tryParse(periodStr.substring(0, 4));
    final month = int.tryParse(periodStr.substring(4, 6));
    final day = int.tryParse(periodStr.substring(6, 8));
    if (year == null || month == null || day == null) return null;

    return _Period(month: month, year: year, day: day);
  }

  ExtractedCreditCardBillPeriod _createBillPeriod(
    String productId,
    _Period period,
    String currencyType,
  ) {
    final year = period.year;
    final month = period.month;
    final day = period.day;

    final startDate =
        '$year-${month.toString().padLeft(2, '0')}-${day?.toString().padLeft(2, '0') ?? ''}';
    final currencyTypeEnum = currencyType == 'nacional'
        ? CurrencyType.national
        : CurrencyType.international;

    final currency = currencyTypeEnum == CurrencyType.national
        ? Currency.clp
        : Currency.usd;

    final periodId = '$productId|$startDate|${currencyTypeEnum.name}';

    return ExtractedCreditCardBillPeriod(
      providerId: periodId,
      startDate: startDate,
      endDate: null,
      currency: currency,
      currencyType: currencyTypeEnum,
    );
  }

  @override
  Future<ExtractedCreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError('Itau credit card bill not implemented');
  }

  @override
  Future<Uint8List> getCreditCardBillPdf(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError('Itau credit card bill PDF not implemented');
  }

  @override
  Future<List<ExtractedTransaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  ) async {
    final commonHeaders = <String, String>{
      'Cookie': credentials,
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Referer':
          'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/deuda',
      'Origin': 'https://banco.itau.cl',
    };

    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));

    final initialUrl = switch (transactionType) {
      CurrencyType.national =>
        'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/compras-pesos',
      CurrencyType.international =>
        'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/compras-en-dolares',
    };

    final initialResponse = await _dio.get(
      initialUrl,

      options: Options(headers: commonHeaders),
    );

    await _checkDioResponse(initialResponse);

    final initialHtml = initialResponse.data.toString();
    final initialDoc = parse(initialHtml);

    final baseHref = initialDoc
        .getElementsByTagName('base')[0]
        .attributes['href']
        ?.trim();
    if (baseHref == null) {
      throw Exception('Itau: no se encontró el base href');
    }

    final selectAccountFormSelector = 'form[name="comboForm"] a';
    final selectAccountFormElement = initialDoc.querySelector(
      selectAccountFormSelector,
    );
    final selectAccountFormActionUrlPath =
        selectAccountFormElement?.attributes['href'];
    if (selectAccountFormActionUrlPath == null) {
      talker.error(
        'Itau: no se encontró el link para seleccionar la cuenta para $transactionType',
      );
      return [];
    }

    final selectAccountFormUrl = '$baseHref/$selectAccountFormActionUrlPath';

    final selectedResponse = await _dio.post(
      selectAccountFormUrl,
      data: {'cuentaIdSelected': productId},
      options: Options(
        headers: commonHeaders,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );
    await _checkDioResponse(selectedResponse);

    final selectedHtml = selectedResponse.data.toString();

    final transactions =
        ClItauPersonasCreditCardUnbilledTransactionMapper.fromUnbilledTransactionsHtml(
      selectedHtml,
      transactionType,
    );

    return CommonsMapper.processTransactions(transactions);
  }
}

Future<void> _checkDioResponse(Response<dynamic> response) async {
  final html = response.data.toString();

  final doc = parse(html);
  final errorMessage = doc.querySelector('form[name="exceptionForm"]');
  if (errorMessage != null) {
    throw ConnectionException(ConnectionExceptionType.authCredentialsExpired);
  }
}

Future<void> _checkDioException(DioException exception) async {
  talker.debug('Error fetching Itau: ${exception.response?.statusCode}');
  if (exception.response?.statusCode != null &&
      exception.response!.statusCode! == 400) {
    throw ConnectionException(ConnectionExceptionType.authCredentialsExpired);
  }
  if (exception.response == null && exception.error is RedirectException) {
    throw ConnectionException(ConnectionExceptionType.authCredentialsExpired);
  }
  talker.error('Error fetching Itau: $exception');
}

class _Period extends Equatable {
  final int? day;
  final int month;
  final int year;

  _Period previousMonth() {
    if (month == 1) {
      return _Period(month: 12, year: year - 1, day: null);
    } else {
      return _Period(month: month - 1, year: year, day: null);
    }
  }

  _Period({required this.month, required this.year, required this.day});

  @override
  List<Object?> get props => [day, month, year];
}

class _DepositaryAccountData {
  final String id;
  final String? url;
  final String html;

  _DepositaryAccountData({
    required this.id,
    required this.url,
    required this.html,
  });
}
