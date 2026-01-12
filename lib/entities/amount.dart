import 'package:pan_scrapper/entities/currency.dart';

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
    final currencyDecimals = currency.decimalDigits;
    final factor = options.factor;

    text = _removeEverythingButNumberSymbols(text);
    final symbolAtTheEnd = text.endsWith('+') || text.endsWith('-');
    final symbolAtTheStart = text.startsWith('+') || text.startsWith('-');

    final explicitSymbol = symbolAtTheStart
        ? text[0]
        : symbolAtTheEnd
        ? text[text.length - 1]
        : '';

    text = symbolAtTheEnd
        ? text.substring(0, text.length - 1)
        : (symbolAtTheStart ? text.substring(1) : text);

    if (thousandSeparator != null && thousandSeparator.isNotEmpty) {
      text = text.replaceAll(thousandSeparator, '');
    }

    if (decimalSeparator != null && decimalSeparator.isNotEmpty) {
      final numberParts = text.split(decimalSeparator);
      final integerPart = numberParts[0];
      var decimalPart = numberParts.length > 1 ? numberParts[1] : '';

      if (decimalPart.length > currencyDecimals) {
        decimalPart = decimalPart.substring(0, currencyDecimals);
      }

      final paddedDecimalPart = decimalPart.padRight(currencyDecimals, '0');

      text = '$integerPart$paddedDecimalPart';
    }

    final value = num.tryParse('$explicitSymbol$text');
    final invertedFactor = options.invertSign ? -1 : 1;
    final finalValue = value != null
        ? value * (1 / factor) * invertedFactor
        : null;

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
}

class AmountParseOptions {
  final double factor;
  final String? thousandSeparator;
  final String? decimalSeparator;
  final bool invertSign;

  AmountParseOptions({
    this.factor = 1,
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
    this.invertSign = false,
  });
}
