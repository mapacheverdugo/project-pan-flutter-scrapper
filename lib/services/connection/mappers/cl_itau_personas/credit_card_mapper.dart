import 'dart:developer';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';

class ClItauPersonasCreditCardMapper {
  static List<ExtractedProductModel> parseCreditCard(String html) {
    try {
      final doc = parse(html);

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
        currency: Currency.clp,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      );

      final usedClp = _readAmount(
        doc,
        selector: '#DeudaNacional',
        currency: Currency.clp,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      );

      final totalClp = _readAmount(
        doc,
        selector: '#CupoTotalNacional',
        currency: Currency.clp,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 0,
        ),
      );

      final availableUsd = _readAmount(
        doc,
        selector: '#CupoDisponibleDolar',
        currency: Currency.usd,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 2,
        ),
      );

      final usedUsd = _readAmount(
        doc,
        selector: '#DeudaInternacional',
        currency: Currency.usd,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 2,
        ),
      );

      final totalUsd = _readAmount(
        doc,
        selector: '#CupoTotalInternacional',
        currency: Currency.usd,
        options: AmountParseOptions(
          thousandSeparator: '.',
          decimalSeparator: ',',
          currencyDecimals: 2,
        ),
      );

      final creditBalances = <ExtractedCreditBalance>[];

      if (availableClp != null && totalClp != null && usedClp != null) {
        creditBalances.add(
          ExtractedCreditBalance(
            currency: Currency.clp,
            creditLimitAmount: totalClp.toInt(),
            availableAmount: availableClp.toInt(),
            usedAmount: usedClp.toInt(),
          ),
        );
      }

      if (availableUsd != null && totalUsd != null && usedUsd != null) {
        creditBalances.add(
          ExtractedCreditBalance(
            currency: Currency.usd,
            creditLimitAmount: totalUsd.toInt(),
            availableAmount: availableUsd.toInt(),
            usedAmount: usedUsd.toInt(),
          ),
        );
      }

      return [
        ExtractedProductModel(
          providerId: productNumber,
          number: productNumber,
          cardBrand: meta.cardBrand,
          cardLast4Digits: meta.cardLast4Digits,
          name: meta.name,
          type: ProductType.creditCard,
          creditBalances: creditBalances,
        ),
      ];
    } catch (e) {
      log('Itau get products error: $e');
      rethrow;
    }
  }

  static _CardMeta _parseCardMetaFromOption(String optionText) {
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

  static num? _readAmount(
    Document doc, {
    required String selector,
    required Currency currency,
    required AmountParseOptions options,
  }) {
    final Element? el = doc.querySelector(selector);
    final String raw = (el?.text ?? '').trim();
    if (raw.isEmpty) return null;

    final amount = Amount.parse(raw, currency, options: options);
    return amount.value;
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
