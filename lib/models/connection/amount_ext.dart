import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';

extension AmountExt on Amount {
  static Amount fromJson(Map<String, dynamic> json) {
    return Amount(
      value: (json['amount'] as double).toInt(),
      currency: Currency.fromIsoLetters(json['currency'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': value, 'currency': currency.isoLetters};
  }
}
