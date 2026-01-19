import 'package:flutter_test/flutter_test.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';

void main() {
  test(
    r'tryParse amount in CLP with text "$5.000.000" to be equal to 5000000',
    () {
      final amount = Amount.tryParse(
        r'$5.000.000',
        Currency.clp,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, 5000000);
    },
  );

  test(
    r'tryParse amount in CLP with text "$-2.000.000" to be equal to -2000000',
    () {
      final amount = Amount.tryParse(
        r'$-2.000.000',
        Currency.clp,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, -2000000);
    },
  );

  test(
    r'tryParse amount in USD with text "USD 5.364" to be equal to 536400',
    () {
      final amount = Amount.tryParse(
        r'USD 5.364',
        Currency.usd,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, 536400);
    },
  );

  test(
    r'tryParse amount in USD with text "USD 4.936,21" to be equal to 493621',
    () {
      final amount = Amount.tryParse(
        r'USD 4.936,21',
        Currency.usd,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, 493621);
    },
  );

  // 000000000000000000
  test(
    r'tryParse amount in CLP with text "000000000000000000" and factor 100 to be equal to 0',
    () {
      final amount = Amount.tryParse(
        r'000000000000000000',
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
        ),
      );
      expect(amount?.value, 0);
    },
  );

  // 000000000000924600
  test(
    r'tryParse amount in CLP with text "000000000000924600" to be equal to 9246',
    () {
      final amount = Amount.tryParse(
        r'000000000000924600',
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
        ),
      );
      expect(amount?.value, 9246);
    },
  );

  // 00000000924600-
  test(
    r'tryParse amount in CLP with text "00000000924600-" and factor 100 to be equal to -9246',
    () {
      final amount = Amount.tryParse(
        '00000000924600-',
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
        ),
      );
      expect(amount?.value, -9246);
    },
  );

  // 000000003508000
  test(
    r'tryParse amount in CLP with text "000000003508000" and factor 100 to be equal to 35080',
    () {
      final amount = Amount.tryParse(
        '000000003508000',
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
        ),
      );
      expect(amount?.value, 35080);
    },
  );

  test(
    r'tryParse amount in CLP with text "000000003508000+" and factor 100 to be equal to 35080',
    () {
      final amount = Amount.tryParse(
        '000000003508000+',
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
        ),
      );
      expect(amount?.value, 35080);
    },
  );

  test(r'tryParse amount in USD with text "4,05" to be equal to 405', () {
    final amount = Amount.tryParse(
      '4,05',
      Currency.usd,
      options: AmountParseOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
      ),
    );
    expect(amount?.value, 405);
  });

  test(
    r'tryParse amount in CLP with text "2.624.901" to be equal to 2624901',
    () {
      final amount = Amount.tryParse(
        '2.624.901',
        Currency.clp,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, 2624901);
    },
  );

  test(r'tryParse amount in USD with text "-4,05" to be equal to -405', () {
    final amount = Amount.tryParse(
      '-4,05',
      Currency.usd,
      options: AmountParseOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
      ),
    );
    expect(amount?.value, -405);
  });

  test(
    r'tryParse amount in CLP with text "-2.624.901" to be equal to -2624901',
    () {
      final amount = Amount.tryParse(
        '-2.624.901',
        Currency.clp,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, -2624901);
    },
  );

  test(
    r'tryParse amount in CLP with text "000000000400000000" and factor 100 to be equal to 4000000',
    () {
      final amount = Amount.tryParse(
        '000000000400000000',
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
        ),
      );
      expect(amount?.value, 4000000);
    },
  );

  test(
    r'tryParse amount in CLP with text "000000000000000000" and factor 100 to be equal to 0',
    () {
      final amount = Amount.tryParse(
        '000000000000000000',
        Currency.clp,
        options: AmountParseOptions(
          factor: 100,
          thousandSeparator: null,
          decimalSeparator: null,
        ),
      );
      expect(amount?.value, 0);
    },
  );

  test(
    r'tryParse amount in CLP with text "4573.00" inverted to be equal to -4573',
    () {
      final amount = Amount.tryParse(
        '4573.00',
        Currency.clp,
        options: AmountParseOptions(
          invertSign: true,
          thousandSeparator: null,
          decimalSeparator: '.',
        ),
      );
      expect(amount?.value, -4573);
    },
  );

  // USD -255,49
  test(
    r'tryParse amount in USD with text "USD -255,49" to be equal to -25549',
    () {
      final amount = Amount.tryParse(
        'USD -255,49',
        Currency.usd,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, -25549);
    },
  );

  test(r'tryParse amount in USD with text "USD 0,00" to be equal to 0', () {
    final amount = Amount.tryParse(
      'USD 0,00',
      Currency.usd,

      options: AmountParseOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
      ),
    );
    expect(amount?.value, 0);
  });

  test(
    r'tryParse amount in USD with text "USD 183,90" to be equal to 18390',
    () {
      final amount = Amount.tryParse(
        'USD 183,90',
        Currency.usd,
        options: AmountParseOptions(
          factor: 1,
          thousandSeparator: '.',
          decimalSeparator: ',',
        ),
      );
      expect(amount?.value, 18390);
    },
  );
}
