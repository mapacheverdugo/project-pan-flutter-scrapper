// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_connection_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalConnectionModel _$LocalConnectionModelFromJson(
  Map<String, dynamic> json,
) => LocalConnectionModel(
  id: json['id'] as String,
  institutionCode: $enumDecode(
    _$InstitutionCodeEnumMap,
    json['institutionCode'],
  ),
  rawUsername: json['rawUsername'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LocalConnectionModelToJson(
  LocalConnectionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'institutionCode': _$InstitutionCodeEnumMap[instance.institutionCode]!,
  'rawUsername': instance.rawUsername,
  'password': instance.password,
};

const _$InstitutionCodeEnumMap = {
  InstitutionCode.clBciPersonas: 'clBciPersonas',
  InstitutionCode.clSantanderPersonas: 'clSantanderPersonas',
  InstitutionCode.clScotiabankPersonas: 'clScotiabankPersonas',
  InstitutionCode.clBancoChilePersonas: 'clBancoChilePersonas',
  InstitutionCode.clItauPersonas: 'clItauPersonas',
  InstitutionCode.clBancoFalabellaPersonas: 'clBancoFalabellaPersonas',
  InstitutionCode.clBancoEstadoPersonas: 'clBancoEstadoPersonas',
  InstitutionCode.unknown: 'unknown',
};
