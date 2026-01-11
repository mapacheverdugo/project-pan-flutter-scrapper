import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';

class AmountJsonConverter extends JsonConverter<Amount, Map<String, dynamic>> {
  const AmountJsonConverter();

  @override
  Amount fromJson(Map<String, dynamic> json) {
    return Amount(
      value: (json['amount'] as double).toInt(),
      currency: Currency.fromIsoLetters(json['currency'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson(Amount object) {
    return {'amount': object.value, 'currency': object.currency.isoLetters};
  }
}
