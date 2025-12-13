class Amount {
  late final num? _value;

  Amount.parse(String text, AmountOptions options) {
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
    _value = value != null ? value * (1 / factor) : null;
  }

  static String _removeEverythingButNumberSymbols(String text) {
    return text.replaceAll(RegExp(r'[^0-9.+-,]'), '');
  }

  num? get value => _value;
}

class AmountOptions {
  final double factor;
  final String? thousandSeparator;
  final String? decimalSeparator;
  final int currencyDecimals;

  AmountOptions({
    this.factor = 1,
    this.thousandSeparator = ',',
    this.decimalSeparator = '.',
    this.currencyDecimals = 0,
  });
}
