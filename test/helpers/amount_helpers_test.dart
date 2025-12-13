import 'package:flutter_test/flutter_test.dart';
import 'package:pan_scrapper/helpers/amount_helpers.dart';

void main() {
  test(r'parse amount in CLP with text "$5.000.000"', () {
    final amount = Amount.parse(
      r'$5.000.000',
      AmountOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: 0,
      ),
    );
    expect(amount.value, 5000000);
  });

  test(r'parse amount in USD with text "USD 5.364"', () {
    final amount = Amount.parse(
      r'USD 5.364',
      AmountOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: 2,
      ),
    );
    expect(amount.value, 536400);
  });

  test(r'parse amount in USD with text "USD 4.936,21"', () {
    final amount = Amount.parse(
      r'USD 4.936,21',
      AmountOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: 2,
      ),
    );
    expect(amount.value, 493621);
  });

  // 000000000000000000
  test(r'parse amount in CLP with text "000000000000000000"', () {
    final amount = Amount.parse(
      r'000000000000000000',
      AmountOptions(
        factor: 100,
        thousandSeparator: null,
        decimalSeparator: null,
        currencyDecimals: 0,
      ),
    );
    expect(amount.value, 0);
  });

  // 000000000000924600
  test(r'parse amount in CLP with text "000000000000924600"', () {
    final amount = Amount.parse(
      r'000000000000924600',
      AmountOptions(
        factor: 100,
        thousandSeparator: null,
        decimalSeparator: null,
        currencyDecimals: 0,
      ),
    );
    expect(amount.value, 9246);
  });
}
