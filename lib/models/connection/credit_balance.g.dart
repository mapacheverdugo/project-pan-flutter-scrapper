// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedCreditBalance _$ExtractedCreditBalanceFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditBalance(
  creditLimitAmount: (json['creditLimitAmount'] as num).toInt(),
  availableAmount: (json['availableAmount'] as num).toInt(),
  usedAmount: (json['usedAmount'] as num).toInt(),
  currency: const CurrencyJsonConverter().fromJson(json['currency'] as String),
);

Map<String, dynamic> _$ExtractedCreditBalanceToJson(
  ExtractedCreditBalance instance,
) => <String, dynamic>{
  'creditLimitAmount': instance.creditLimitAmount,
  'currency': const CurrencyJsonConverter().toJson(instance.currency),
  'availableAmount': instance.availableAmount,
  'usedAmount': instance.usedAmount,
};
