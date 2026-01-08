import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/models/currency.dart';
import 'package:pan_scrapper/models/index.dart';

class ClItauPersonasProductMapper {
  static Product? parseDepositaryProductFromResponse({
    required String cuentaId,
    required String fragmentHtml,
    required String homeHtml,
  }) {
    final fragmentDoc = parse(fragmentHtml);
    final homeDoc = parse(homeHtml);

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
        fragmentDoc,
        fallbackNumber: cuentaId,
        name: accountName,
      );
    } else {
      return _parseCurrentAccountProduct(
        fragmentDoc,
        fallbackNumber: cuentaId,
        name: accountName,
      );
    }
  }

  static Product? _parseCurrentAccountProduct(
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
    final currency = isUsd ? Currency.usd : Currency.clp;

    final amount = Amount.tryParse(
      raw,
      currency,
      options: AmountParseOptions(
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: isUsd ? 2 : 0,
      ),
    );

    if (amount == null) return null;

    return Product(
      id: fallbackNumber,
      number: fallbackNumber,
      name: name,
      type: ProductType.depositaryAccount,
      availableAmount: amount,
      creditBalances: null,
      isForSecondaryCardHolder: false,
      cardBrand: null,
      cardLast4Digits: null,
    );
  }

  static Product? _parseCreditLineProduct(
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
            Currency.clp,
            options: AmountParseOptions(
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
      currency: Currency.clp,
    );
    final total = _readAmountByNameContains(
      root,
      containsAny: const ['total'],
      currency: Currency.clp,
    );

    if (used == null || available == null || total == null) return null;

    final balance = CreditBalance(
      currency: Currency.clp,
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
      currency: currency,
      options: AmountParseOptions(
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
      availableAmount: available,
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

    final currency = _detectCurrencyFromContainer(container) ?? Currency.clp;

    // Cupo utilizado: se ve como <span name="cupoUtilizado">$ ...</span>
    final used = _readAmountWithin(
      container,
      selector: 'span[name="cupoUtilizado"]',
      currency: currency,
      options: AmountParseOptions(
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

    if (used == null || available == null || total == null) {
      return null;
    }

    final creditBalances = <CreditBalance>[];
    creditBalances.add(
      CreditBalance(
        currency: currency,
        creditLimitAmount: total.value,
        availableAmount: available.value,
        usedAmount: used.value,
      ),
    );

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

  static num? _readAmountByNameContains(
    Element root, {
    required List<String> containsAny,
    required Currency currency,
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
        currency,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      ).value;

      if (v != null) return v;
    }
    return null;
  }

  Amount? _readAmountFrom(
    Document doc, {
    required String selector,
    required Currency currency,
    required AmountParseOptions options,
  }) {
    final el = doc.querySelector(selector);
    final raw = (el?.text ?? '').trim();
    if (raw.isEmpty) return null;
    return Amount.tryParse(raw, currency, options: options);
  }

  Amount? _readAmountWithin(
    Element root, {
    required String selector,
    required Currency currency,
    required AmountParseOptions options,
  }) {
    final el = root.querySelector(selector);
    final raw = (el?.text ?? '').trim();
    if (raw.isEmpty) return null;
    return Amount.tryParse(raw, currency, options: options);
  }

  /// Busca dentro del contenedor spans con atributo `name`,
  /// y retorna el primer monto cuyo `name` contenga cualquiera de los strings.
  Amount? _readAmountByHeuristic(
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

      final currency = raw.toUpperCase().contains('USD')
          ? Currency.usd
          : Currency.clp;

      // Detecta USD vs CLP por el texto.
      final currencyDecimals = currency == Currency.usd ? 2 : 0;

      return Amount.tryParse(
        raw,
        currency,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: currencyDecimals,
        ),
      );
    }
    return null;
  }

  Currency? _detectCurrencyFromContainer(Element root) {
    final text = root.text.toUpperCase();
    if (text.contains('USD')) return Currency.usd;
    if (text.contains('\$')) return Currency.clp;
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
    final currency = isUsd ? Currency.usd : Currency.clp;

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
}

class _AccountMeta {
  final String name;
  final String? accountMaskedNumber;
  final Currency currency;

  _AccountMeta({
    required this.name,
    required this.accountMaskedNumber,
    required this.currency,
  });
}
