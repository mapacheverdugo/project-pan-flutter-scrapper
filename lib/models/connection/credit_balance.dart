import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/converters/currency_json_converter.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';

part 'credit_balance.g.dart';

@JsonSerializable(converters: [CurrencyJsonConverter()], explicitToJson: true)
class ExtractedCreditBalance {
  final int creditLimitAmount;
  final Currency currency;
  final int availableAmount;
  final int usedAmount;

  ExtractedCreditBalance({
    required this.creditLimitAmount,
    required this.availableAmount,
    required this.usedAmount,
    required this.currency,
  });

  Amount get creditLimitAmountModel =>
      Amount(currency: currency, value: creditLimitAmount);
  Amount get availableAmountModel =>
      Amount(currency: currency, value: availableAmount);
  Amount get usedAmountModel => Amount(currency: currency, value: usedAmount);

  factory ExtractedCreditBalance.fromJson(Map<String, dynamic> json) =>
      _$ExtractedCreditBalanceFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedCreditBalanceToJson(this);
}
