import 'package:flutter_test/flutter_test.dart';
import 'package:pan_scrapper/helpers/amount_helpers.dart';

void main() {
  test(
    r'parse amount in CLP with text "$5.000.000" to be equal to 5000000',
    () {
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
    },
  );

  test(r'parse amount in USD with text "USD 5.364" to be equal to 536400', () {
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

  test(
    r'parse amount in USD with text "USD 4.936,21" to be equal to 493621',
    () {
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
    },
  );

  // 000000000000000000
  test(
    r'parse amount in CLP with text "000000000000000000" and factor 100 to be equal to 0',
    () {
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
    },
  );

  // 000000000000924600
  test(
    r'parse amount in CLP with text "000000000000924600" to be equal to 9246',
    () {
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
    },
  );

  // 00000000924600-
  test(
    r'parse amount in CLP with text "00000000924600-" and factor 100 to be equal to -9246',
    () {
      final amount = Amount.parse(
        '00000000924600-',
        AmountOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
          currencyDecimals: 0,
        ),
      );
      expect(amount.value, -9246);
    },
  );

  // 000000003508000
  test(
    r'parse amount in CLP with text "000000003508000" and factor 100 to be equal to 35080',
    () {
      final amount = Amount.parse(
        '000000003508000',
        AmountOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
          currencyDecimals: 0,
        ),
      );
      expect(amount.value, 35080);
    },
  );

  test(
    r'parse amount in CLP with text "000000003508000+" and factor 100 to be equal to 35080',
    () {
      final amount = Amount.parse(
        '000000003508000+',
        AmountOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
          currencyDecimals: 0,
        ),
      );
      expect(amount.value, 35080);
    },
  );
}
