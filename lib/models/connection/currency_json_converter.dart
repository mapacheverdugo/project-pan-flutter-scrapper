import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/currency.dart';

class CurrencyJsonConverter extends JsonConverter<Currency, String> {
  const CurrencyJsonConverter();

  @override
  Currency fromJson(String json) {
    return Currency.fromIsoLetters(json);
  }

  @override
  String toJson(Currency object) {
    return object.isoLetters;
  }
}
