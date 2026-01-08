import 'dart:math';

import 'package:currency_formatter/currency_formatter.dart';
import 'package:pan_scrapper/models/currency.dart';

extension CurrencyFormatterExt on Currency {
  String format(double amount) {
    return CurrencyFormatter.format(
      amount / pow(10, decimalDigits),
      _settings,
      decimal: decimalDigits,
    );
  }

  CurrencyFormat get _settings => CurrencyFormat(
    symbol: symbolNative,
    decimalSeparator: '.',
    thousandSeparator: ',',
  );
}
