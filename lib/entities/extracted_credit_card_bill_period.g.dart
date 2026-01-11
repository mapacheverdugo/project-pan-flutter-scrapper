// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extracted_credit_card_bill_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedCreditCardBillPeriod _$ExtractedCreditCardBillPeriodFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillPeriod(
  providerId: json['providerId'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String?,
  currency: const CurrencyJsonConverter().fromJson(json['currency'] as String),
  currencyType: const CurrencyTypeJsonConverter().fromJson(
    json['currencyType'] as String,
  ),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ExtractedCreditCardBillPeriodToJson(
  ExtractedCreditCardBillPeriod instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'currency': const CurrencyJsonConverter().toJson(instance.currency),
  'currencyType': const CurrencyTypeJsonConverter().toJson(
    instance.currencyType,
  ),
  'metadata': instance.metadata,
};
