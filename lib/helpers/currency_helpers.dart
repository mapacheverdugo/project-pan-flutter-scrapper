// TODO: Import currency and country currency constants when available
// import 'package:pan_scrapper/constants/currencies.dart';
// import 'package:pan_scrapper/constants/countries_currencies.dart';
import 'package:pan_scrapper/helpers/country_helpers.dart';

/// Try to get ISO letter currency code from ISO number
/// [isoNumber] The ISO currency number (e.g., 152)
/// Returns The ISO letter currency code (e.g., "CLP") or null if not found
String? tryGetIsoLettersCurrencyFromIsoNumber(int isoNumber) {
  // TODO: Implement when currencies constants are available
  // Example implementation:
  // final entry = currencies.entries.firstWhere(
  //   (entry) => entry.value.ISOnum == isoNumber,
  //   orElse: () => null,
  // );
  // return entry?.key;
  throw UnimplementedError(
    'tryGetIsoLettersCurrencyFromIsoNumber requires currencies constants',
  );
}

/// Get ISO letter currency code from ISO number, throws error if not found
/// [isoNumber] The ISO currency number
/// Returns The ISO letter currency code
/// Throws Exception if currency not found
String getIsoLettersCurrencyFromIsoNumber(int isoNumber) {
  final currency = tryGetIsoLettersCurrencyFromIsoNumber(isoNumber);
  if (currency == null) {
    throw Exception('Currency not found for isoNumber: $isoNumber');
  }
  return currency;
}

/// Get ISO letter currency code from 2-letter country code
/// [countryIsoCode] The 2-letter country ISO code (e.g., "CL")
/// Returns The ISO letter currency code (e.g., "CLP") or null if not found
String? getIsoLettersCurrencyFrom2LetterCountry(String countryIsoCode) {
  // TODO: Implement when countriesCurrencies constants are available
  // Example implementation:
  // return countriesCurrencies[countryIsoCode];
  throw UnimplementedError(
    'getIsoLettersCurrencyFrom2LetterCountry requires countriesCurrencies constants',
  );
}

/// Get ISO letter currency code from 3-letter country code
/// [countryIsoCode] The 3-letter country ISO code (e.g., "CHL")
/// Returns The ISO letter currency code (e.g., "CLP") or null if not found
String? getIsoLettersCurrencyFrom3LetterCountry(String countryIsoCode) {
  final country2Letter = get2LetterCountryFrom3LetterCountry(countryIsoCode);
  return country2Letter != null
      ? getIsoLettersCurrencyFrom2LetterCountry(country2Letter)
      : null;
}

/// Validate ISO letter currency code
/// [isoLettersCurrency] The ISO letter currency code to validate
/// Returns The validated currency code
/// Throws Exception if currency is invalid
String validateIsoLettersCurrency(String? isoLettersCurrency) {
  if (isoLettersCurrency == null || isoLettersCurrency.isEmpty) {
    throw Exception('Invalid currency');
  }

  // TODO: Implement when countriesCurrencies constants are available
  // final currencyOrNull = countriesCurrencies[isoLettersCurrency];
  // if (currencyOrNull == null) {
  //   throw Exception('Invalid currency');
  // }
  // return currencyOrNull;
  throw UnimplementedError(
    'validateIsoLettersCurrency requires countriesCurrencies constants',
  );
}

