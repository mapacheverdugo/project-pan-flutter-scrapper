// TODO: Import countries constants when available
// import 'package:pan_scrapper/constants/countries.dart';

/// Get 2-letter country code from 3-letter ISO country code
/// [iso3Letter] The 3-letter ISO country code (e.g., "CHL")
/// Returns The 2-letter country code (e.g., "CL") or null if not found
String? get2LetterCountryFrom3LetterCountry(String iso3Letter) {
  // TODO: Implement when countries constants are available
  // Example implementation:
  // final country = countries.firstWhere(
  //   (country) => country.let3 == iso3Letter,
  //   orElse: () => null,
  // );
  // return country?.let2;
  throw UnimplementedError(
    'get2LetterCountryFrom3LetterCountry requires countries constants',
  );
}

