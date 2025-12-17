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
import 'package:pan_scrapper/helpers/amount_helpers.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
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
      final basePayload = _extractFormFields(form);

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
        final fragDoc = parse(fragmentHtml);

        final parsed = _parseDepositaryProductFromResponse(
          cuentaId: cuentaId,
          doc: fragDoc,
          homeDoc: homeDoc, // por si necesitas el label/nombre desde el home
        );

        if (parsed != null) products.add(parsed);
      }

      return products;
    } catch (e) {
      log('Itau get depositary accounts error: $e');
      rethrow;
    }
  }

  Product? _parseDepositaryProductFromResponse({
    required String cuentaId,
    required Document doc,
    required Document homeDoc,
  }) {
    // Nombre “humano” desde el option del home
    final option = homeDoc.querySelector(
      'select#comboCuentas option[value="$cuentaId"]',
    );
    final optionText = (option?.text ?? '').trim();
    final accountName = optionText.isNotEmpty
        ? optionText.split('##').first.trim()
        : cuentaId;

    // Heurística de tipo:
    // - Si viene bloque de línea de crédito, lo tratamos como credit line
    // - Si no, como cuenta corriente/depositaria
    final hasCreditLineBlock = false;

    if (hasCreditLineBlock) {
      return _parseCreditLineProduct(
        doc,
        fallbackNumber: cuentaId,
        name: accountName,
      );
    } else {
      return _parseCurrentAccountProduct(
        doc,
        fallbackNumber: cuentaId,
        name: accountName,
      );
    }
  }

  Product? _parseCurrentAccountProduct(
    Document doc, {
    required String fallbackNumber,
    required String name,
  }) {
    final rawEl =
        doc.querySelector('#saldoDispCtaCteId span[name="saldoDisponible"]') ??
        doc.querySelector('span[name="saldoDisponible"]');

    final raw = (rawEl?.text ?? '').trim();
    if (raw.isEmpty) return null;

    // Detectar si USD o CLP por texto
    final isUsd = raw.toUpperCase().contains('USD') || raw.contains('US\$');
    final currency = isUsd ? 'USD' : 'CLP';

    final value = Amount.parse(
      raw,
      AmountOptions(
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: isUsd ? 2 : 0,
      ),
    ).value;

    if (value == null) return null;

    return Product(
      id: fallbackNumber,
      number: fallbackNumber,
      name: name,
      type: ProductType.depositaryAccount,
      availableAmount: AvailableAmount(
        currency: currency,
        amount: value.toInt(),
      ),
      creditBalances: null,
      isForSecondaryCardHolder: false,
      cardBrand: null,
      cardLast4Digits: null,
    );
  }

  Product? _parseCreditLineProduct(
    Document doc, {
    required String fallbackNumber,
    required String name,
  }) {
    final root = doc.querySelector('#reloadLineaCreditoConDatos') ?? doc.body;
    if (root == null) return null;

    // Número visible de la línea (si viene)
    final numberText = (root.querySelector('#numLineaCredito')?.text ?? '')
        .trim();
    final number = numberText.isNotEmpty ? numberText : fallbackNumber;

    // Usado: suele ser span[name="cupoUtilizado"]
    final usedRawEl = root.querySelector('span[name="cupoUtilizado"]');
    final usedRaw = (usedRawEl?.text ?? '').trim();
    final used = usedRaw.isNotEmpty
        ? Amount.parse(
            usedRaw,
            AmountOptions(
              thousandSeparator: '.',
              decimalSeparator: ',',
              currencyDecimals: 0,
            ),
          ).value
        : null;

    // Disponible/Total: como no sabemos name exacto, buscamos spans name que contengan "dispon" / "total"
    final available = _readAmountByNameContains(
      root,
      containsAny: const ['dispon'],
    );
    final total = _readAmountByNameContains(root, containsAny: const ['total']);

    if (used == null || available == null || total == null) return null;

    final balance = CreditBalance(
      currency: 'CLP',
      creditLimitAmount: total.toInt(),
      availableAmount: available.toInt(),
      usedAmount: used.toInt(),
    );

    return Product(
      id: fallbackNumber,
      number: number,
      name: name.isNotEmpty ? name : 'Línea de crédito',
      type: ProductType.depositaryAccountCreditLine,
      availableAmount: null,
      creditBalances: [balance],
      isForSecondaryCardHolder: false,
      cardBrand: null,
      cardLast4Digits: null,
    );
  }

  num? _readAmountByNameContains(
    Element root, {
    required List<String> containsAny,
  }) {
    final spans = root.querySelectorAll('span[name]');
    for (final s in spans) {
      final n = (s.attributes['name'] ?? '').toLowerCase();
      if (n.isEmpty) continue;

      if (!containsAny.any((k) => n.contains(k))) continue;

      final raw = s.text.trim();
      if (raw.isEmpty) continue;

      // CLP style (si en tu línea de crédito hubiera USD, ajusta aquí)
      final v = Amount.parse(
        raw,
        AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      ).value;

      if (v != null) return v;
    }
    return null;
  }

  Map<String, dynamic> _extractFormFields(Element form) {
    final fields = <String, dynamic>{};

    // inputs
    for (final input in form.querySelectorAll('input[name]')) {
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
    for (final sel in form.querySelectorAll('select[name]')) {
      final name = sel.attributes['name']?.trim();
      if (name == null || name.isEmpty) continue;

      final selected =
          sel.querySelector('option[selected]') ?? sel.querySelector('option');
      final value = (selected?.attributes['value'] ?? '').trim();
      if (value.isNotEmpty) fields[name] = value;
    }

    return fields;
  }

  Product? _parseSelectedCurrentAccount(Document doc) {
    // En el home, la cuenta corriente viene con un select (comboCuentas)
    // y el saldo disponible se muestra en: #saldoDispCtaCteId span[name=saldoDisponible]
    final select = doc.querySelector('select#comboCuentas');
    final selected = select?.querySelector('option[selected]');
    if (selected == null) return null;

    final optionText = (selected.text).trim();
    final optionValue = (selected.attributes['value'] ?? '').trim();

    final meta = _parseAccountMetaFromOption(optionText);

    final currency = meta.currency; // "CLP" o "USD"

    final available = _readAmountFrom(
      doc,
      selector: '#saldoDispCtaCteId span[name="saldoDisponible"]',
      options: AmountOptions(
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: currency == 'USD' ? 2 : 0,
      ),
    );

    // Si el HTML trae solo la cuenta seleccionada, el saldo corresponde a esa.
    // number: preferimos el value del option (CA_1 / CU_1) no sirve como número real,
    // así que usamos el número enmascarado o fallback.
    final number = (meta.accountMaskedNumber?.isNotEmpty == true)
        ? meta.accountMaskedNumber!
        : (optionValue.isNotEmpty ? optionValue : meta.name);

    if (available == null) {
      // Igual devolvemos el producto si al menos identificamos la cuenta
      return Product(
        id: number,
        number: number,
        name: meta.name,
        type: ProductType.depositaryAccount,
        availableAmount: null,
        creditBalances: null,
        cardBrand: null,
        cardLast4Digits: null,
        isForSecondaryCardHolder: false,
      );
    }

    return Product(
      id: number,
      number: number,
      name: meta.name,
      type: ProductType.depositaryAccount,
      availableAmount: AvailableAmount(
        currency: currency,
        amount: available.toInt(),
      ),
      creditBalances: null,
      cardBrand: null,
      cardLast4Digits: null,
      isForSecondaryCardHolder: false,
    );
  }

  Product? _parseCreditLine(Document doc) {
    // Bloque explícito de línea de crédito cuando hay datos:
    final container = doc.querySelector('#reloadLineaCreditoConDatos');
    if (container == null) return null;

    final number = (container.querySelector('#numLineaCredito')?.text ?? '')
        .trim();
    if (number.isEmpty) return null;

    // Cupo utilizado: se ve como <span name="cupoUtilizado">$ ...</span>
    final used = _readAmountWithin(
      container,
      selector: 'span[name="cupoUtilizado"]',
      options: AmountOptions(
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: 0,
      ),
    );

    // Cupo disponible / total: en tu HTML se alcanza a ver el label,
    // pero el name exacto puede variar. Buscamos de forma robusta por "name".
    final available = _readAmountByHeuristic(
      container,
      nameContains: ['dispon'],
    );
    final total = _readAmountByHeuristic(container, nameContains: ['total']);

    // Moneda: si llegara a venir USD en los textos, la detectamos.
    final currency = _detectCurrencyFromContainer(container) ?? 'CLP';

    if (used == null || available == null || total == null) {
      // Si falta algo, igual puedes optar por no retornar el producto.
      // Yo lo devuelvo solo si al menos existe 'used' y 'available' (ajústalo a tu gusto).
      if (used == null || available == null) return null;
    }

    final creditBalances = <CreditBalance>[];
    if (used != null && available != null && total != null) {
      creditBalances.add(
        CreditBalance(
          currency: currency,
          creditLimitAmount: total.toInt(),
          availableAmount: available.toInt(),
          usedAmount: used.toInt(),
        ),
      );
    }

    return Product(
      id: number,
      number: number,
      name: 'Línea de crédito',
      type: ProductType.depositaryAccountCreditLine,
      availableAmount: null,
      creditBalances: creditBalances.isEmpty ? null : creditBalances,
      cardBrand: null,
      cardLast4Digits: null,
      isForSecondaryCardHolder: false,
    );
  }

  // ---------- Helpers ----------

  num? _readAmountFrom(
    Document doc, {
    required String selector,
    required AmountOptions options,
  }) {
    final el = doc.querySelector(selector);
    final raw = (el?.text ?? '').trim();
    if (raw.isEmpty) return null;
    return Amount.parse(raw, options).value;
  }

  num? _readAmountWithin(
    Element root, {
    required String selector,
    required AmountOptions options,
  }) {
    final el = root.querySelector(selector);
    final raw = (el?.text ?? '').trim();
    if (raw.isEmpty) return null;
    return Amount.parse(raw, options).value;
  }

  /// Busca dentro del contenedor spans con atributo `name`,
  /// y retorna el primer monto cuyo `name` contenga cualquiera de los strings.
  num? _readAmountByHeuristic(
    Element root, {
    required List<String> nameContains,
  }) {
    final spans = root.querySelectorAll('span[name]');
    for (final s in spans) {
      final name = (s.attributes['name'] ?? '').toLowerCase();
      if (name.isEmpty) continue;

      final ok = nameContains.any((k) => name.contains(k.toLowerCase()));
      if (!ok) continue;

      final raw = (s.text).trim();
      if (raw.isEmpty) continue;

      // Detecta USD vs CLP por el texto.
      final currencyDecimals = raw.toUpperCase().contains('USD') ? 2 : 0;

      final value = Amount.parse(
        raw,
        AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: currencyDecimals,
        ),
      ).value;

      if (value != null) return value;
    }
    return null;
  }

  String? _detectCurrencyFromContainer(Element root) {
    final text = root.text.toUpperCase();
    if (text.contains('USD')) return 'USD';
    if (text.contains('\$')) return 'CLP';
    return null;
  }

  _AccountMeta _parseAccountMetaFromOption(String optionText) {
    // En el home, el option suele venir tipo:
    // "Cuenta Corriente ****9009##...algo"
    final parts = optionText.split('##').map((e) => e.trim()).toList();

    final left = parts.isNotEmpty ? parts[0] : optionText;
    final lower = optionText.toLowerCase();

    final isUsd =
        lower.contains('dólar') ||
        lower.contains('dolar') ||
        lower.contains('usd');
    final currency = isUsd ? 'USD' : 'CLP';

    // Extrae el "****9009" si existe
    final masked = RegExp(
      r'(\*{2,}\s*\d{2,})',
    ).firstMatch(left)?.group(1)?.replaceAll(' ', '');

    // Nombre "Cuenta Corriente" / "Cuenta en dólares" (simple)
    final name = left.isNotEmpty
        ? left.replaceAll(RegExp(r'\s+\*+\d+.*$'), '').trim()
        : 'Cuenta';

    return _AccountMeta(
      name: name.isEmpty
          ? (isUsd ? 'Cuenta en dólares' : 'Cuenta Corriente')
          : name,
      accountMaskedNumber: masked,
      currency: currency,
    );
  }

  Future<List<Product>> _getCreditCards(String credentials) async {
    try {
      final response = await _dio.get(
        'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/deuda',
        options: Options(headers: {'Cookie': credentials}),
      );
      final rawHtml = response.data.toString();
      final doc = parse(rawHtml);

      final selectedOption = doc.querySelector('select option[selected]');

      final _CardMeta meta = _parseCardMetaFromOption(
        selectedOption?.text ?? '',
      );

      final String productNumber =
          (selectedOption?.attributes['value']?.trim().isNotEmpty == true)
          ? selectedOption!.attributes['value']!.trim()
          : (meta.cardLast4Digits ?? meta.name);

      final availableClp = _readAmount(
        doc,
        selector: '#CupoDisponiblePesos',
        options: AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      );

      final usedClp = _readAmount(
        doc,
        selector: '#DeudaNacional',
        options: AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      );

      final totalClp = _readAmount(
        doc,
        selector: '#CupoTotalNacional',
        options: AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      );

      final availableUsd = _readAmount(
        doc,
        selector: '#CupoDisponibleDolar',
        options: AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 2,
        ),
      );

      final usedUsd = _readAmount(
        doc,
        selector: '#DeudaInternacional',
        options: AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 2,
        ),
      );

      final totalUsd = _readAmount(
        doc,
        selector: '#CupoTotalInternacional',
        options: AmountOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 2,
        ),
      );

      final creditBalances = <CreditBalance>[];

      if (availableClp != null && totalClp != null && usedClp != null) {
        creditBalances.add(
          CreditBalance(
            currency: 'CLP',
            creditLimitAmount: totalClp.toInt(),
            availableAmount: availableClp.toInt(),
            usedAmount: usedClp.toInt(),
          ),
        );
      }

      if (availableUsd != null && totalUsd != null && usedUsd != null) {
        creditBalances.add(
          CreditBalance(
            currency: 'USD',
            creditLimitAmount: totalUsd.toInt(),
            availableAmount: availableUsd.toInt(),
            usedAmount: usedUsd.toInt(),
          ),
        );
      }

      return [
        Product(
          id: productNumber,
          number: productNumber,
          cardBrand: meta.cardBrand,
          cardLast4Digits: meta.cardLast4Digits,
          name: meta.name,
          type: ProductType.creditCard,
          creditBalances: creditBalances,
          isForSecondaryCardHolder: false,
        ),
      ];
    } catch (e) {
      log('Itau get products error: $e');
      rethrow;
    }
  }

  num? _readAmount(
    Document doc, {
    required String selector,
    required AmountOptions options,
  }) {
    final Element? el = doc.querySelector(selector);
    final String raw = (el?.text ?? '').trim();
    if (raw.isEmpty) return null;

    final amount = Amount.parse(raw, options);
    return amount.value;
  }

  _CardMeta _parseCardMetaFromOption(String optionText) {
    final parts = optionText.split('##').map((e) => e.trim()).toList();

    final String name = (parts.isNotEmpty && parts[0].isNotEmpty)
        ? parts[0]
        : 'Credit Card';

    String? last4;
    if (parts.length >= 2) {
      final match = RegExp(r'(\d{4})\s*$').firstMatch(parts[1]);
      last4 = match?.group(1);
    }

    CardBrand? brand;
    final String combined = parts.join(' ').toLowerCase();
    if (combined.contains('mastercard'))
      brand = CardBrand.mastercard;
    else if (combined.contains('visa'))
      brand = CardBrand.visa;
    else if (combined.contains('amex'))
      brand = CardBrand.amex;
    else if (combined.contains('diners'))
      brand = CardBrand.diners;

    return _CardMeta(name: name, cardLast4Digits: last4, cardBrand: brand);
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

    await _dio.get(
      'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/cuenta-$currencyType',
      options: Options(headers: commonHeaders),
    );

    // Initial request to get the page
    final baseUrl =
        'https://banco.itau.cl/wps/myportal/newolb/web/tarjeta-credito/resumen/cuenta-$currencyType';
    final initialResponse = await _dio.post(
      baseUrl,
      data: {'cuentaIdSelected': productId},
      options: Options(
        headers: commonHeaders,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );

    final initialHtml = initialResponse.data.toString();
    final initialDoc = parse(initialHtml);

    // Extract the initial period from resultShow input
    final resultShowInput = initialDoc.querySelector('#resultShow');
    if (resultShowInput == null) {
      log('Itau: no se encontró el input resultShow para $currencyType');
      return periods;
    }

    final initialPeriodValue = (resultShowInput.attributes['value'] ?? '')
        .trim();
    if (initialPeriodValue.isEmpty) {
      log('Itau: resultShow está vacío para $currencyType');
      return periods;
    }

    // Parse initial period (format: "MM / YYYY")
    final initialPeriod = _parsePeriod(initialPeriodValue);
    if (initialPeriod == null) {
      log('Itau: no se pudo parsear el periodo inicial: $initialPeriodValue');
      return periods;
    }

    // Extract form action URL from the page
    // Also get the actual response URL which contains the portal path
    final responseUrl = initialResponse.realUri.toString();
    final formActionUrl = _extractFormActionUrl(
      initialDoc,
      currencyType,
      responseUrl,
    );
    if (formActionUrl == null) {
      log('Itau: no se encontró la URL del form action para $currencyType');
      return periods;
    }

    // Check initial period
    final hasData = !_hasSinDatos(initialDoc);
    if (hasData) {
      final period = _createBillPeriod(
        productId,
        initialPeriod.month,
        initialPeriod.year,
        currencyType,
      );
      periods.add(period);
    } else {
      // If initial period is empty, stop
      return periods;
    }

    // Navigate backwards month by month
    var currentMonth = initialPeriod.month;
    var currentYear = initialPeriod.year;
    var emptyCount = 0;

    while (emptyCount <= maxEmptyPeriods) {
      // Calculate previous month
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }

      // Check if this period has data
      final periodHasData = await _checkPeriodHasData(
        credentials,
        formActionUrl,
        currentMonth,
        currentYear,
        currencyType,
        commonHeaders,
      );

      if (periodHasData) {
        final period = _createBillPeriod(
          productId,
          currentMonth,
          currentYear,
          currencyType,
        );
        periods.add(period);
        emptyCount = 0; // Reset empty count
      } else {
        emptyCount++;
        if (emptyCount > maxEmptyPeriods) {
          break;
        }
      }
    }

    return periods;
  }

  bool _hasSinDatos(Document doc) {
    final contenido = doc.querySelector('#contenido');
    if (contenido == null) return true;
    final sinDatos = contenido.querySelector('#sinDatos');
    return sinDatos != null;
  }

  Future<bool> _checkPeriodHasData(
    String credentials,
    String formActionUrl,
    int month,
    int year,
    String currencyType,
    Map<String, String> commonHeaders,
  ) async {
    try {
      // Format: "MM / YYYY"
      final resultShow = '${month.toString().padLeft(2, '0')} / $year';
      // Format: YYYYMMDD (using last day of month)
      final lastDayOfMonth = DateTime(year, month + 1, 0).day;
      final periodo =
          '${year}${month.toString().padLeft(2, '0')}${lastDayOfMonth.toString().padLeft(2, '0')}';
      // Format: YYYYMM
      final fecha = '${year}${month.toString().padLeft(2, '0')}';

      // Build the event parameter based on currency type
      final eventParam = currencyType == 'nacional'
          ? 'portlets%2Ftarjeta_credito%2Festado%2FEstadoDeudaNacionalPortlet%21fireEvent%3AForm%3Aip_filtroMesAnoPeriodo_SaveDataSubmitEvent'
          : 'portlets%2Ftarjeta_credito%2Festado%2FEstadoDeudaInternacionalPortlet%21fireEvent%3AForm%3Aip_filtroMesAnoPeriodo_SaveDataSubmitEvent';

      final actionParam = currencyType == 'nacional'
          ? 'al_cambiaPeriodoSeleccionado'
          : 'ljo_getDate.filtroPeriodos';

      // Build the full URL with parameters
      // The formActionUrl should already contain the portal path
      // We need to append the portal-specific parameters
      // Construct the full URL with portal parameters
      // The pattern from curl examples shows: basePath/!ut/p/z1/.../p0/...==/
      // We append the action parameters
      final separator = formActionUrl.contains('?') ? '&' : '?';
      final fullUrl =
          '$formActionUrl${separator}_bowStEvent=$eventParam&bf_action%21$actionParam=bf_keep%21true=bf_model%21${_generateModelId(currencyType)}==/';

      final requestHeaders = Map<String, String>.from(commonHeaders);
      requestHeaders['X-Requested-With'] = 'XMLHttpRequest';
      requestHeaders['Accept'] = '*/*';
      requestHeaders['Sec-Fetch-Dest'] = 'empty';
      requestHeaders['Sec-Fetch-Mode'] = 'cors';
      requestHeaders['Sec-Fetch-Site'] = 'same-origin';

      final data = {
        'resultShow': resultShow,
        'periodo': periodo,
        'fecha': fecha,
        '_bowStEvent':
            'portlets/tarjeta_credito/estado/EstadoDeudaNacionalPortlet\u0021fireEvent:Form:ip_filtroMesAnoPeriodo_SaveDataSubmitEvent',
      };

      final response = await _dio.post(
        fullUrl,
        data: data,
        options: Options(
          headers: requestHeaders,
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
        ),
      );

      final html = response.data.toString();
      final doc = parse(html);
      return !_hasSinDatos(doc);
    } catch (e) {
      log('Itau: error checking period $month/$year for $currencyType: $e');
      return false;
    }
  }

  String _generateModelId(String currencyType) {
    // Generate a random model ID matching the format from curl examples
    // Format: [11-char-hex]_portletsQCPtarjeta_creditoQCPestadoQCPEstadoDeuda[Nacional|Internacional]Portlet
    final random = DateTime.now().millisecondsSinceEpoch;
    final randomHex = random
        .toRadixString(16)
        .padLeft(11, '0')
        .substring(0, 11);
    final portletName = currencyType == 'nacional'
        ? 'EstadoDeudaNacionalPortlet'
        : 'EstadoDeudaInternacionalPortlet';
    return '${randomHex}_portletsQCPtarjeta_creditoQCPestadoQCP$portletName';
  }

  String? _extractFormActionUrl(
    Document doc,
    String currencyType,
    String responseUrl,
  ) {
    // The responseUrl contains the full portal URL, use it as base
    // Try to find a form or link that contains the action URL
    final forms = doc.querySelectorAll('form[action*="cuenta-$currencyType"]');
    if (forms.isNotEmpty) {
      final action = forms.first.attributes['action'];
      if (action != null && action.isNotEmpty) {
        if (action.startsWith('http')) {
          return action;
        } else if (action.startsWith('/')) {
          return 'https://banco.itau.cl$action';
        } else {
          // Relative URL, append to response URL base
          final uri = Uri.parse(responseUrl);
          final base = '${uri.scheme}://${uri.host}${uri.path}';
          return '$base/$action';
        }
      }
    }

    // Try to find links with the portal URL pattern
    final links = doc.querySelectorAll('a[href*="cuenta-$currencyType"]');
    for (final link in links) {
      final href = link.attributes['href'];
      if (href != null && href.contains('!ut/p/')) {
        return href.startsWith('http') ? href : 'https://banco.itau.cl$href';
      }
    }

    // Use the response URL as base (it should contain the portal path)
    // Remove query parameters and fragment
    final uri = Uri.parse(responseUrl);
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  _Period? _parsePeriod(String periodStr) {
    // Format: "MM / YYYY" or "M / YYYY"
    final parts = periodStr.split('/').map((e) => e.trim()).toList();
    if (parts.length != 2) return null;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return null;
    if (month < 1 || month > 12) return null;

    return _Period(month: month, year: year);
  }

  CreditCardBillPeriod _createBillPeriod(
    String productId,
    int month,
    int year,
    String currencyType,
  ) {
    // Use first day of the month as startDate
    final startDate = '${year}-${month.toString().padLeft(2, '0')}-01';
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

class _CardMeta {
  final String name;
  final String? cardLast4Digits;
  final CardBrand? cardBrand;

  _CardMeta({
    required this.name,
    required this.cardLast4Digits,
    required this.cardBrand,
  });
}

class _AccountMeta {
  final String name;
  final String? accountMaskedNumber;
  final String currency;

  _AccountMeta({
    required this.name,
    required this.accountMaskedNumber,
    required this.currency,
  });
}

class _Period {
  final int month;
  final int year;

  _Period({required this.month, required this.year});
}
