import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/converters/currency_type_json_converter.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extracted_credit_card_bill_summary.dart';
import 'package:pan_scrapper/entities/extracted_transaction.dart';

part 'extracted_credit_card_bill.g.dart';

@JsonSerializable(
  explicitToJson: true,
  converters: [CurrencyTypeJsonConverter()],
)
class ExtractedCreditCardBill {
  final String periodId;
  final CurrencyType currencyType;
  final ExtractedCreditCardBillSummary? summary;
  final List<ExtractedTransactionWithoutProviderId>? transactions;

  ExtractedCreditCardBill({
    required this.periodId,
    required this.currencyType,
    required this.summary,
    required this.transactions,
  });

  factory ExtractedCreditCardBill.fromJson(Map<String, dynamic> json) =>
      _$ExtractedCreditCardBillFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedCreditCardBillToJson(this);
}
