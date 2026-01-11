import 'package:flutter_test/flutter_test.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';

void main() {
  test(
    r'parse amount in CLP with text "$5.000.000" to be equal to 5000000',
    () {
      final amount = Amount.parse(
        r'$5.000.000',
        Currency.clp,
        options: AmountParseOptions(
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
      Currency.usd,
      options: AmountParseOptions(
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
        Currency.usd,
        options: AmountParseOptions(
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
        Currency.clp,
        options: AmountParseOptions(
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
        Currency.clp,
        options: AmountParseOptions(
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
        Currency.clp,
        options: AmountParseOptions(
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
        Currency.clp,
        options: AmountParseOptions(
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
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
          currencyDecimals: 0,
        ),
      );
      expect(amount.value, 35080);
    },
  );

  test(r'parse amount in USD with text "4,05" to be equal to 405', () {
    final amount = Amount.parse(
      '4,05',
      Currency.usd,
      options: AmountParseOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: 2,
      ),
    );
    expect(amount.value, 405);
  });

  test(r'parse amount in CLP with text "2.624.901" to be equal to 2624901', () {
    final amount = Amount.parse(
      '2.624.901',
      Currency.clp,
      options: AmountParseOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
      ),
    );
    expect(amount.value, 2624901);
  });

  test(r'parse amount in USD with text "-4,05" to be equal to -405', () {
    final amount = Amount.parse(
      '-4,05',
      Currency.usd,
      options: AmountParseOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
        currencyDecimals: 2,
      ),
    );
    expect(amount.value, -405);
  });

  test(
    r'parse amount in CLP with text "-2.624.901" to be equal to -2624901',
    () {
      final amount = Amount.parse(
        '-2.624.901',
        Currency.clp,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount.value, -2624901);
    },
  );
}
