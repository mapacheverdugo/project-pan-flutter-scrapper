import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/converters/currency_json_converter.dart';
import 'package:pan_scrapper/converters/currency_type_json_converter.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/currency_type.dart';

part 'extracted_credit_card_bill_period.g.dart';

@JsonSerializable(
  explicitToJson: true,
  converters: [CurrencyTypeJsonConverter(), CurrencyJsonConverter()],
)
class ExtractedCreditCardBillPeriod {
  final String providerId;
  final String startDate;
  final String? endDate;
  final Currency currency;
  final CurrencyType currencyType;
  final Map<String, dynamic>? metadata;

  ExtractedCreditCardBillPeriod({
    required this.providerId,
    required this.startDate,
    this.endDate,
    required this.currency,
    required this.currencyType,
    this.metadata,
  });

  factory ExtractedCreditCardBillPeriod.fromJson(Map<String, dynamic> json) =>
      _$ExtractedCreditCardBillPeriodFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedCreditCardBillPeriodToJson(this);
}
