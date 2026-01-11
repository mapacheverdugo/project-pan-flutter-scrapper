import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/models/connection/amount_json_converter.dart';
import 'package:pan_scrapper/models/connection/currency_json_converter.dart';

part 'credit_balance.g.dart';

@JsonSerializable(
  converters: [AmountJsonConverter(), CurrencyJsonConverter()],
  explicitToJson: true,
)
class ExtractedCreditBalance {
  final Amount creditLimitAmount;
  final Currency currency;
  final Amount availableAmount;
  final Amount usedAmount;

  ExtractedCreditBalance({
    required int creditLimitAmount,
    required int availableAmount,
    required int usedAmount,
    required this.currency,
  }) : creditLimitAmount = Amount(currency: currency, value: creditLimitAmount),
       availableAmount = Amount(currency: currency, value: availableAmount),
       usedAmount = Amount(currency: currency, value: usedAmount);

  factory ExtractedCreditBalance.fromJson(Map<String, dynamic> json) =>
      _$ExtractedCreditBalanceFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedCreditBalanceToJson(this);
}
