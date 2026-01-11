import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/billing_status.dart';

class BillingStatusJsonConverter extends JsonConverter<BillingStatus, String> {
  const BillingStatusJsonConverter();

  @override
  BillingStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case "billed":
        return BillingStatus.billed;
      case "unbilled":
        return BillingStatus.unbilled;
      case "default_":
        return BillingStatus.default_;
      default:
        return BillingStatus.billed;
    }
  }

  @override
  String toJson(BillingStatus object) {
    switch (object) {
      case BillingStatus.billed:
        return "billed".toUpperCase();
      case BillingStatus.unbilled:
        return "unbilled".toUpperCase();
      case BillingStatus.default_:
        return "default_".toUpperCase();
    }
  }
}
