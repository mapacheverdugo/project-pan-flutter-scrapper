import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/models/connection/product_type.dart';

class ProductTypeJsonConverter extends JsonConverter<ProductType, String> {
  const ProductTypeJsonConverter();

  @override
  ProductType fromJson(String json) {
    switch (json.toLowerCase()) {
      case "depositary_account":
        return ProductType.depositaryAccount;
      case "credit_card":
        return ProductType.creditCard;
      case "depositary_account_credit_line":
        return ProductType.depositaryAccountCreditLine;
      case "unknown":
        return ProductType.unknown;
      default:
        return ProductType.unknown;
    }
  }

  @override
  String toJson(ProductType object) {
    switch (object) {
      case ProductType.depositaryAccount:
        return "depositary_account".toUpperCase();
      case ProductType.creditCard:
        return "credit_card".toUpperCase();
      case ProductType.depositaryAccountCreditLine:
        return "depositary_account_credit_line".toUpperCase();
      case ProductType.unknown:
        return "unknown".toUpperCase();
    }
  }
}
