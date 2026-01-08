import 'package:pan_scrapper/models/currency.dart';
import 'package:pan_scrapper/models/currency_ext.dart';

class Amount {
  final Currency currency;
  final int value;

  factory Amount.parse(
    String text,
    Currency currency, {
    AmountParseOptions? options,
  }) {
    options ??= AmountParseOptions();
    final thousandSeparator = options.thousandSeparator;
    final decimalSeparator = options.decimalSeparator;
    final currencyDecimals = options.currencyDecimals;
    final factor = options.factor;

    text = _removeEverythingButNumberSymbols(text);
    final symbolAtTheEnd = text.endsWith('+') || text.endsWith('-');
    final symbolAtTheStart = text.startsWith('+') || text.startsWith('-');

    final explicitSymbol = symbolAtTheStart
        ? text[0]
        : symbolAtTheEnd
        ? text[text.length - 1]
        : '';

    text = symbolAtTheEnd ? text.substring(0, text.length - 1) : text;

    if (thousandSeparator != null && thousandSeparator.isNotEmpty) {
      text = text.replaceAll(thousandSeparator, '');
    }

    if (decimalSeparator != null && decimalSeparator.isNotEmpty) {
      final numberParts = text.split(decimalSeparator);
      final integerPart = numberParts[0];
      final decimalPart = numberParts.length > 1 ? numberParts[1] : '';

      final paddedDecimalPart = decimalPart.padRight(currencyDecimals, '0');

      text = '$integerPart$paddedDecimalPart';
    }

    final value = num.tryParse('$explicitSymbol$text');
    final finalValue = value != null ? value * (1 / factor) : null;

    return Amount(currency: currency, value: finalValue?.toInt() ?? 0);
  }

  static Amount? tryParse(
    String text,
    Currency currency, {
    AmountParseOptions? options,
  }) {
    try {
      return Amount.parse(text, currency, options: options);
    } catch (e) {
      return null;
    }
  }

  Amount({required this.currency, required this.value});

  static String _removeEverythingButNumberSymbols(String text) {
    return text.replaceAll(RegExp(r'[^0-9.+\-,]'), '');
  }

  String get formatted => currency.format(value.toDouble());
  String get formattedWithCurrency => '$formatted ${currency.isoLetters}';
  String get formattedDependingOnCurrency =>
      currency == Currency.clp ? formatted : formattedWithCurrency;

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount(
      currency: Currency.fromIsoLetters(json['currency'] as String),
      value: (json['value'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'currency': currency.isoLetters, 'value': value};
  }
}

class AmountParseOptions {
  final double factor;
  final String? thousandSeparator;
  final String? decimalSeparator;
  final int currencyDecimals;

  AmountParseOptions({
    this.factor = 1,
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
    this.currencyDecimals = 0,
  });
}
