import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/models/connection/amount_ext.dart';

class AmountJsonConverter extends JsonConverter<Amount, Map<String, dynamic>> {
  const AmountJsonConverter();

  @override
  Amount fromJson(Map<String, dynamic> json) {
    return AmountExt.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Amount object) {
    return object.toJson();
  }
}
