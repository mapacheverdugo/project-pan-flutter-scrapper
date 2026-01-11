// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extracted_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedTransaction _$ExtractedTransactionFromJson(
  Map<String, dynamic> json,
) => ExtractedTransaction(
  description: json['description'] as String,
  amount: const AmountJsonConverter().fromJson(
    json['amount'] as Map<String, dynamic>,
  ),
  transactionDate: json['transactionDate'] as String?,
  transactionTime: json['transactionTime'] as String?,
  processingDate: json['processingDate'] as String?,
  originalAmount: _$JsonConverterFromJson<Map<String, dynamic>, Amount>(
    json['originalAmount'],
    const AmountJsonConverter().fromJson,
  ),
  city: json['city'] as String?,
  country: json['country'] as String?,
  billingCurrencyType: $enumDecodeNullable(
    _$CurrencyTypeEnumMap,
    json['billingCurrencyType'],
  ),
  billingStatus: $enumDecodeNullable(
    _$BillingStatusEnumMap,
    json['billingStatus'],
  ),
  installments: json['installments'] == null
      ? null
      : ExtractedTransactionInstallments.fromJson(
          json['installments'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ExtractedTransactionToJson(
  ExtractedTransaction instance,
) => <String, dynamic>{
  'description': instance.description,
  'amount': const AmountJsonConverter().toJson(instance.amount),
  'transactionDate': instance.transactionDate,
  'transactionTime': instance.transactionTime,
  'processingDate': instance.processingDate,
  'originalAmount': _$JsonConverterToJson<Map<String, dynamic>, Amount>(
    instance.originalAmount,
    const AmountJsonConverter().toJson,
  ),
  'city': instance.city,
  'country': instance.country,
  'billingCurrencyType': _$CurrencyTypeEnumMap[instance.billingCurrencyType],
  'billingStatus': _$BillingStatusEnumMap[instance.billingStatus],
  'installments': instance.installments?.toJson(),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$CurrencyTypeEnumMap = {
  CurrencyType.national: 'national',
  CurrencyType.international: 'international',
};

const _$BillingStatusEnumMap = {
  BillingStatus.billed: 'billed',
  BillingStatus.unbilled: 'unbilled',
  BillingStatus.default_: 'default_',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
