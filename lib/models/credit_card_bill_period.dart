import 'package:pan_scrapper/models/currency_type.dart';

class CreditCardBillPeriod {
  final String id;
  final String startDate;
  final String? endDate;
  final String currency;
  final CurrencyType currencyType;

  CreditCardBillPeriod({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.currency,
    required this.currencyType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'currency': currency,
      'currencyType': currencyType.name,
    };
  }
}

