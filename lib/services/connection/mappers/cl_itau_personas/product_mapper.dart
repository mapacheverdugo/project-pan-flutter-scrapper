import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';

class ClItauPersonasProductMapper {
  static List<ExtractedProductModel> parseDepositaryProductFromResponse({
    required String cuentaId,
    required String fragmentHtml,
  }) {
    final fragmentDoc = parse(fragmentHtml);

    // Nombre “humano” desde el option del home
    final option = fragmentDoc.querySelector(
      'select#comboCuentas option[value="$cuentaId"]',
    );
    final optionText = (option?.text ?? '').trim();

    final creditLineParsed = _parseCreditLineProduct(
      fragmentDoc,
      cuentaId: cuentaId,
    );

    final parsedProduct = _parseCurrentAccountProduct(
      fragmentDoc,
      cuentaId: cuentaId,
      optionText: optionText,
    );

    return [
      if (creditLineParsed != null) creditLineParsed,
      if (parsedProduct != null) parsedProduct,
    ];
  }

  static ExtractedProductModel? _parseCurrentAccountProduct(
    Document doc, {
    required String cuentaId,
    required String optionText,
  }) {
    final accountName = optionText.isNotEmpty
        ? optionText.split('##').first.trim()
        : cuentaId;
    final accountNumber = optionText.isNotEmpty
        ? optionText.split('##')[1].trim()
        : cuentaId;

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
      ),
    );

    if (amount == null) return null;

    return ExtractedProductModel(
      providerId: cuentaId,
      number: accountNumber,
      name: accountName,
      type: ProductType.depositaryAccount,
      availableAmount: amount,
      creditBalances: null,
      cardBrand: null,
      cardLast4Digits: null,
    );
  }

  static ExtractedCreditBalance? _parseCreditLineBalance(Element root) {
    final clpOptions = AmountParseOptions(
      thousandSeparator: '.',
      decimalSeparator: ',',
    );

    final usedRaw =
        (root.querySelector('span[name="cupoUtilizado"]')?.text ?? '').trim();
    final used = usedRaw.isNotEmpty
        ? Amount.tryParse(usedRaw, Currency.clp, options: clpOptions)
        : null;

    final availableRaw =
        (root.querySelector('span[name="cupoDisponible"]')?.text ?? '').trim();
    final available = availableRaw.isNotEmpty
        ? Amount.tryParse(availableRaw, Currency.clp, options: clpOptions)
        : null;

    if (used == null || available == null) return null;

    // Total: si no viene explícito en HTML, se calcula como usado + disponible
    final totalAmount = _readAmountByNameContains(
      root,
      containsAny: const ['total'],
      currency: Currency.clp,
    );
    final total = totalAmount != null
        ? totalAmount.toInt()
        : (used.value + available.value);

    final balance = ExtractedCreditBalance(
      currency: Currency.clp,
      creditLimitAmount: total,
      availableAmount: available.value,
      usedAmount: used.value,
    );

    return balance;
  }

  static ExtractedProductModel? _parseCreditLineProduct(
    Document doc, {
    required String cuentaId,
  }) {
    final root = doc.querySelector('#reloadLineaCreditoConDatos') ?? doc.body;
    if (root == null) return null;

    final accountName = root.querySelector('div.name')?.text.trim() ?? '';
    final accountNumber = root.querySelector('div.number')?.text.trim() ?? '';

    final creditLineBalance = _parseCreditLineBalance(root);
    if (creditLineBalance == null) return null;

    return ExtractedProductModel(
      providerId: "LC|$cuentaId",
      number: accountNumber,
      name: accountName.isNotEmpty ? accountName : '',
      type: ProductType.depositaryAccountCreditLine,
      availableAmount: null,
      creditBalances: [creditLineBalance],
      cardBrand: null,
      cardLast4Digits: null,
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
      final v = Amount.tryParse(
        raw,
        currency,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );

      if (v != null) return v.value;
    }
    return null;
  }
}
