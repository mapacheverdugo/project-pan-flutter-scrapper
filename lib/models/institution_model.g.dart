// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institution_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstitutionModel _$InstitutionModelFromJson(
  Map<String, dynamic> json,
) => InstitutionModel(
  id: json['id'] as String,
  code: const InstitutionCodeJsonConverter().fromJson(json['code'] as String),
  country: json['country'] as String,
  status: const InstitutionStatusJsonConverter().fromJson(
    json['status'] as String,
  ),
  brandId: json['brandId'] as String,
  brand: InstitutionBrandModel.fromJson(json['brand'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$InstitutionModelToJson(InstitutionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': const InstitutionCodeJsonConverter().toJson(instance.code),
      'country': instance.country,
      'status': const InstitutionStatusJsonConverter().toJson(instance.status),
      'brandId': instance.brandId,
      'brand': instance.brand,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
