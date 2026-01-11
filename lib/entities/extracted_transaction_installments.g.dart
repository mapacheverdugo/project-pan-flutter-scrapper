// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extracted_transaction_installments.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedTransactionInstallments _$ExtractedTransactionInstallmentsFromJson(
  Map<String, dynamic> json,
) => ExtractedTransactionInstallments(
  currentCount: (json['currentCount'] as num).toInt(),
  remainingCount: (json['remainingCount'] as num).toInt(),
  totalCount: (json['totalCount'] as num).toInt(),
  currentAmount: const AmountJsonConverter().fromJson(
    json['currentAmount'] as Map<String, dynamic>,
  ),
  originalTransactionAmount:
      _$JsonConverterFromJson<Map<String, dynamic>, Amount>(
        json['originalTransactionAmount'],
        const AmountJsonConverter().fromJson,
      ),
  totalFinalAmount: _$JsonConverterFromJson<Map<String, dynamic>, Amount>(
    json['totalFinalAmount'],
    const AmountJsonConverter().fromJson,
  ),
  interestRate: (json['interestRate'] as num?)?.toDouble(),
  firstInstallmentDate: json['firstInstallmentDate'] as String,
);

Map<String, dynamic> _$ExtractedTransactionInstallmentsToJson(
  ExtractedTransactionInstallments instance,
) => <String, dynamic>{
  'currentCount': instance.currentCount,
  'remainingCount': instance.remainingCount,
  'totalCount': instance.totalCount,
  'currentAmount': const AmountJsonConverter().toJson(instance.currentAmount),
  'originalTransactionAmount':
      _$JsonConverterToJson<Map<String, dynamic>, Amount>(
        instance.originalTransactionAmount,
        const AmountJsonConverter().toJson,
      ),
  'totalFinalAmount': _$JsonConverterToJson<Map<String, dynamic>, Amount>(
    instance.totalFinalAmount,
    const AmountJsonConverter().toJson,
  ),
  'interestRate': instance.interestRate,
  'firstInstallmentDate': instance.firstInstallmentDate,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
