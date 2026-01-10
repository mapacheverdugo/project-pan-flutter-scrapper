// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institution_brand_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstitutionBrandModel _$InstitutionBrandModelFromJson(
  Map<String, dynamic> json,
) => InstitutionBrandModel(
  id: json['id'] as String,
  name: json['name'] as String,
  logoPositiveUrl: json['logoPositiveUrl'] as String?,
  logoNegativeUrl: json['logoNegativeUrl'] as String?,
  iconPositiveUrl: json['iconPositiveUrl'] as String?,
  iconNegativeUrl: json['iconNegativeUrl'] as String?,
  iconAltUrl: json['iconAltUrl'] as String?,
  mainColor: json['mainColor'] as String?,
  primaryColor: json['primaryColor'] as String?,
  suggestedIconOnMainColor: json['suggestedIconOnMainColor'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$InstitutionBrandModelToJson(
  InstitutionBrandModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'logoPositiveUrl': instance.logoPositiveUrl,
  'logoNegativeUrl': instance.logoNegativeUrl,
  'iconPositiveUrl': instance.iconPositiveUrl,
  'iconNegativeUrl': instance.iconNegativeUrl,
  'iconAltUrl': instance.iconAltUrl,
  'mainColor': instance.mainColor,
  'primaryColor': instance.primaryColor,
  'suggestedIconOnMainColor': instance.suggestedIconOnMainColor,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
