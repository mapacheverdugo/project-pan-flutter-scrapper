import 'package:pan_scrapper/models/amount.dart';
import 'package:pan_scrapper/models/currency.dart';

class CreditBalance {
  final Amount creditLimitAmount;
  final Currency currency;
  final Amount availableAmount;
  final Amount usedAmount;

  CreditBalance({
    required int creditLimitAmount,
    required int availableAmount,
    required int usedAmount,
    required this.currency,
  }) : creditLimitAmount = Amount(currency: currency, value: creditLimitAmount),
       availableAmount = Amount(currency: currency, value: availableAmount),
       usedAmount = Amount(currency: currency, value: usedAmount);

  factory CreditBalance.fromJson(Map<String, dynamic> json) {
    return CreditBalance(
      creditLimitAmount: (json['creditLimitAmount'] as num).toInt(),
      currency: Currency.fromIsoLetters(json['currency'] as String),
      availableAmount: (json['availableAmount'] as num).toInt(),
      usedAmount: (json['usedAmount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creditLimitAmount': creditLimitAmount,
      'currency': currency.isoLetters,
      'availableAmount': availableAmount,
      'usedAmount': usedAmount,
    };
  }
}
