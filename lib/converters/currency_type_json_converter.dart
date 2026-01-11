import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/currency_type.dart';

class CurrencyTypeJsonConverter extends JsonConverter<CurrencyType, String> {
  const CurrencyTypeJsonConverter();

  @override
  CurrencyType fromJson(String json) {
    switch (json.toLowerCase()) {
      case "national":
        return CurrencyType.national;
      case "international":
        return CurrencyType.international;
      default:
        return CurrencyType.national;
    }
  }

  @override
  String toJson(CurrencyType object) {
    switch (object) {
      case CurrencyType.national:
        return "national".toUpperCase();
      case CurrencyType.international:
        return "international".toUpperCase();
    }
  }
}
