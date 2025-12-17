import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
    throw UnimplementedError('Itau credit card bill periods not implemented');
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
