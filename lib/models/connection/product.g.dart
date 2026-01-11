// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedProductModel _$ExtractedProductModelFromJson(
  Map<String, dynamic> json,
) => ExtractedProductModel(
  providerId: json['providerId'] as String,
  number: json['number'] as String,
  name: json['name'] as String,
  type: const ProductTypeJsonConverter().fromJson(json['type'] as String),
  cardBrand: _$JsonConverterFromJson<String, CardBrand>(
    json['cardBrand'],
    const CardBrandJsonConverter().fromJson,
  ),
  cardLast4Digits: json['cardLast4Digits'] as String?,
  availableAmount: _$JsonConverterFromJson<Map<String, dynamic>, Amount>(
    json['availableAmount'],
    const AmountJsonConverter().fromJson,
  ),
  creditBalances: (json['creditBalances'] as List<dynamic>?)
      ?.map((e) => ExtractedCreditBalance.fromJson(e as Map<String, dynamic>))
      .toList(),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ExtractedProductModelToJson(
  ExtractedProductModel instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
  'number': instance.number,
  'name': instance.name,
  'type': const ProductTypeJsonConverter().toJson(instance.type),
  'cardBrand': _$JsonConverterToJson<String, CardBrand>(
    instance.cardBrand,
    const CardBrandJsonConverter().toJson,
  ),
  'cardLast4Digits': instance.cardLast4Digits,
  'availableAmount': _$JsonConverterToJson<Map<String, dynamic>, Amount>(
    instance.availableAmount,
    const AmountJsonConverter().toJson,
  ),
  'creditBalances': instance.creditBalances?.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
