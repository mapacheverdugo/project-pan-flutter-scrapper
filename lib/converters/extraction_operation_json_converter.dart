import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/extraction_operation.dart';

class ExtractionOperationJsonConverter
    extends JsonConverter<ExtractionOperation, String> {
  const ExtractionOperationJsonConverter();

  @override
  ExtractionOperation fromJson(String json) {
    switch (json.toLowerCase()) {
      case "products":
        return ExtractionOperation.products;
      case "depositary_account_transactions":
        return ExtractionOperation.depositaryAccountTransactions;
      case "credit_card_bill_periods":
        return ExtractionOperation.creditCardBillPeriods;
      case "credit_card_unbilled_transactions":
        return ExtractionOperation.creditCardUnbilledTransactions;
      case "credit_card_bill_details":
        return ExtractionOperation.creditCardBillDetails;
      default:
        return ExtractionOperation.products;
    }
  }

  @override
  String toJson(ExtractionOperation object) {
    switch (object) {
      case ExtractionOperation.products:
        return "products".toUpperCase();
      case ExtractionOperation.depositaryAccountTransactions:
        return "depositary_account_transactions".toUpperCase();
      case ExtractionOperation.creditCardBillPeriods:
        return "credit_card_bill_periods".toUpperCase();
      case ExtractionOperation.creditCardUnbilledTransactions:
        return "credit_card_unbilled_transactions".toUpperCase();
      case ExtractionOperation.creditCardBillDetails:
        return "credit_card_bill_details".toUpperCase();
    }
  }
}
