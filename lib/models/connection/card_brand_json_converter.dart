import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/models/connection/card_brand.dart';

class CardBrandJsonConverter
    extends JsonConverter<CardBrand, String> {
  const CardBrandJsonConverter();

  @override
  CardBrand fromJson(String json) {
    switch (json.toLowerCase()) {
      case "visa":
        return CardBrand.visa;
      case "mastercard":
        return CardBrand.mastercard;
      case "amex":
        return CardBrand.amex;
      case "diners":
        return CardBrand.diners;
      case "other":
        return CardBrand.other;
      default:
        return CardBrand.other;
    }
  }

  @override
  String toJson(CardBrand object) {
    switch (object) {
      case CardBrand.visa:
        return "visa".toUpperCase();
      case CardBrand.mastercard:
        return "mastercard".toUpperCase();
      case CardBrand.amex:
        return "amex".toUpperCase();
      case CardBrand.diners:
        return "diners".toUpperCase();
      case CardBrand.other:
        return "other".toUpperCase();
    }
  }
}
