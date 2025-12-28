import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    hide CookieManager;
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/services/mappers/cl_itau_personas/credit_card_mapper.dart';
import 'package:pan_scrapper/services/mappers/cl_itau_personas/product_mapper.dart';
import 'package:pan_scrapper/webview/webview.dart';

class ClItauPersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function({String? cookies}) _webviewFactory;

  ClItauPersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(String username, String password) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      log("ItauService auth - opening login page");

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

      log("ItauService auth after navigate");

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

      log("ItauService auth submit clicked, waiting...");

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

      log("ItauService auth completed - cookies extracted");

      return cookieString;
    } catch (e) {
      await webview.close();
      log('Itau auth error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts(String credentials) async {
    final depositaryAccounts = await _getDepositaryAccounts(credentials);
    final creditCards = await _getCreditCards(credentials);
    return [...depositaryAccounts, ...creditCards];
  }

  Future<List<Product>> _getDepositaryAccounts(String credentials) async {
    try {
      final homeResp = await _dio.get(
        'https://banco.itau.cl/wps/myportal/newolb/web/home/newhome',
        options: Options(headers: {'Cookie': credentials}),
      );

      final products = <Product>[];

      final homeHtml = homeResp.data.toString();
      final homeRespUrl = homeResp.realUri;
      final baseUrl = 'https://${homeRespUrl.host}';
      final homeDoc = parse(homeHtml);

      final cuentaIds = homeDoc
          .querySelectorAll('select#comboCuentas option[value]')
          .map((o) => (o.attributes['value'] ?? '').trim())
          .where((v) => v.isNotEmpty)
          .toList();

      if (cuentaIds.isEmpty) return products;

      final linkElement = homeDoc.querySelector(
        'a[href*="_gen_call_onChangeCuenta"]',
      );

      final href = linkElement?.attributes['href']?.trim();
      if (href == null) {
        log('Itau: no se encontró el link para cambiar cuenta (comboCuentas).');
        return products;
      }

      final actionUrl = '$baseUrl$href';

      final form = homeDoc.querySelector('#filterCtaSaldo');
      if (form == null) {
        log('Itau: no se encontró el form para cambiar cuenta (comboCuentas).');
        return products;
      }

      // 3) Base payload: todos los inputs del form (hidden + text + etc.)
      // Luego sobreescribimos comboCuentas en cada iteración.
      final basePayload = _extractFormFieldsFromElement(form);

      final commonHeaders = <String, String>{
        'Cookie': credentials,
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': '*/*',
        'Referer': 'https://banco.itau.cl/wps/myportal/newolb/web/home/newhome',
      };

      for (final cuentaId in cuentaIds) {
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

        final fragmentHtml = resp.data.toString();

        final parsed =
            ClItauPersonasProductMapper.parseDepositaryProductFromResponse(
              cuentaId: cuentaId,
              fragmentHtml: fragmentHtml,
              homeHtml: homeHtml,
            );

        if (parsed != null) products.add(parsed);
      }

      return products;
    } catch (e) {
      log('Itau get depositary accounts error: $e');
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

  Future<List<Product>> _getCreditCards(String credentials) async {
    try {
      final response = await _dio.get(
        'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/deuda',
        options: Options(headers: {'Cookie': credentials}),
      );
      final html = response.data.toString();
      final products = ClItauPersonasCreditCardMapper.parseCreditCard(html);
      return products;
    } catch (e) {
      log('Itau get products error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    throw UnimplementedError(
      'Itau depositary account transactions not implemented',
    );
  }

  @override
  Future<List<CreditCardBillPeriod>> getCreditCardBillPeriods(
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
      log('Itau get credit card bill periods error: $e');
      rethrow;
    }
  }

  Future<List<CreditCardBillPeriod>> _getPeriodsForCurrencyType(
    String credentials,
    String productId,
    String currencyType, // 'nacional' or 'internacional'
    Map<String, String> commonHeaders,
  ) async {
    final periods = <CreditCardBillPeriod>[];
    const maxEmptyPeriods = 0; // Stop at first empty period

    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));

    final initialResponse = await _dio.get(
      'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/cuenta-$currencyType',
      options: Options(headers: commonHeaders),
    );

    final contentLocationUrlPath = initialResponse.headers.value(
      'content-location',
    );
    if (contentLocationUrlPath == null) {
      log('Itau: no se encontró el content-location para $currencyType');
      return periods;
    }

    final initialHtml = initialResponse.data.toString();
    final initialDoc = parse(initialHtml);

    final initialResponseUri = initialResponse.realUri;

    final selectFormAElement = initialDoc.querySelector(
      'form[name="comboForm"] a[id^="wpf_action_ref_"]',
    );
    final selectFormActionUrlPath = selectFormAElement?.attributes['href'];
    if (selectFormActionUrlPath == null) {
      log(
        'Itau: no se encontró el link para seleccionar la cuenta para $currencyType',
      );
      return periods;
    }

    final selectFormUrl = initialResponseUri
        .resolve('$contentLocationUrlPath/$selectFormActionUrlPath')
        .toString();
    final selectedResponse = await _dio.post(
      selectFormUrl,
      data: {'cuentaIdSelected': productId},
      options: Options(
        headers: commonHeaders,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );
    final selectedResponseUri = selectedResponse.realUri;

    final selectedHtml = selectedResponse.data.toString();
    final selectedDoc = parse(selectedHtml);

    var emptyPeriodsCounter = 0;

    // Extract the initial period from resultShow input
    final periodoInput = selectedDoc.querySelector('#periodo option');
    if (periodoInput == null) {
      log('Itau: no se encontró el input periodo para $currencyType');
      return periods;
    }

    final initialPeriodValue = (periodoInput.attributes['value'] ?? '').trim();
    if (initialPeriodValue.isEmpty) {
      log('Itau: resultShow está vacío para $currencyType');
      return periods;
    }

    final initialPeriod = _parsePeriod(initialPeriodValue);
    if (initialPeriod == null) {
      log('Itau: no se pudo parsear el periodo inicial: $initialPeriodValue');
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
      log('Itau: no se encontró el value para _bowStEvent');
      return periods;
    }

    final formularioSelectFormAElement = initialDoc.querySelector(
      '#formularioSelect a[id^="wpf_action_ref_"]',
    );
    final formularioSelectFormActionUrlPath =
        formularioSelectFormAElement?.attributes['href'];

    final formularioSelectFormUrl = selectedResponseUri
        .resolve('$contentLocationUrlPath/$formularioSelectFormActionUrlPath')
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

        final periodoInput = doc.querySelector('#periodo option');
        if (periodoInput == null) {
          log('Itau: no se encontró el input periodo para $currencyType');
          return periods;
        }

        final initialPeriodValue = (periodoInput.attributes['value'] ?? '')
            .trim();
        if (initialPeriodValue.isEmpty) {
          log('Itau: resultShow está vacío para $currencyType');
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
        log('Itau: error requesting period data: $e');
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

    return _dio.post(
      url,
      data: data,
      options: Options(
        headers: requestHeaders,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );
  }

  _Period? _parsePeriod(String periodStr) {
    final year = int.tryParse(periodStr.substring(0, 4));
    final month = int.tryParse(periodStr.substring(4, 6));
    final day = int.tryParse(periodStr.substring(6, 8));

    if (year == null || month == null || day == null) return null;

    return _Period(month: month, year: year, day: day);
  }

  CreditCardBillPeriod _createBillPeriod(
    String productId,
    _Period period,
    String currencyType,
  ) {
    final year = period.year;
    final month = period.month;
    final day = period.day;

    final startDate =
        '$year-${month.toString().padLeft(2, '0')}-${day?.toString().padLeft(2, '0') ?? ''}';
    final currency = currencyType == 'nacional' ? 'CLP' : 'USD';
    final currencyTypeEnum = currencyType == 'nacional'
        ? CurrencyType.national
        : CurrencyType.international;

    final periodId = '$productId|$startDate|${currencyTypeEnum.name}';

    return CreditCardBillPeriod(
      id: periodId,
      startDate: startDate,
      endDate: null,
      currency: currency,
      currencyType: currencyTypeEnum,
    );
  }

  @override
  Future<CreditCardBill> getCreditCardBill(
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
}

class _Period {
  final int month;
  final int year;
  final int? day;

  _Period previousMonth() {
    if (month == 1) {
      return _Period(month: 12, year: year - 1);
    } else {
      return _Period(month: month - 1, year: year);
    }
  }

  _Period({required this.month, required this.year, this.day});
}
