// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extracted_connection_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedConnectionResultModel _$ExtractedConnectionResultModelFromJson(
  Map<String, dynamic> json,
) => ExtractedConnectionResultModel(
  institutionCode: const InstitutionCodeJsonConverter().fromJson(
    json['institutionCode'] as String,
  ),
  username: json['username'] as String,
  products: (json['products'] as List<dynamic>)
      .map((e) => ExtractedProductModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  credentials: ExtractedConnectionResultCredentialsModel.fromJson(
    json['credentials'] as Map<String, dynamic>,
  ),
  isRemoteSyncEnabled: json['isRemoteSyncEnabled'] as bool? ?? false,
);

Map<String, dynamic> _$ExtractedConnectionResultModelToJson(
  ExtractedConnectionResultModel instance,
) => <String, dynamic>{
  'institutionCode': const InstitutionCodeJsonConverter().toJson(
    instance.institutionCode,
  ),
  'username': instance.username,
  'products': instance.products.map((e) => e.toJson()).toList(),
  'credentials': instance.credentials.toJson(),
  'isRemoteSyncEnabled': instance.isRemoteSyncEnabled,
};

ExtractedConnectionResultCredentialsModel
_$ExtractedConnectionResultCredentialsModelFromJson(
  Map<String, dynamic> json,
) => ExtractedConnectionResultCredentialsModel(
  username: json['username'] as String,
  password: json['password'] as String?,
);

Map<String, dynamic> _$ExtractedConnectionResultCredentialsModelToJson(
  ExtractedConnectionResultCredentialsModel instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
};
