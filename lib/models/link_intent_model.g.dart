// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_intent_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkIntentResponseModel _$LinkIntentResponseModelFromJson(
  Map<String, dynamic> json,
) => LinkIntentResponseModel(
  success: json['success'] as bool,
  data: LinkIntentDataModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LinkIntentResponseModelToJson(
  LinkIntentResponseModel instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

LinkIntentDataModel _$LinkIntentDataModelFromJson(Map<String, dynamic> json) =>
    LinkIntentDataModel(
      linkWidgetToken: json['linkWidgetToken'] as String,
      mode: json['mode'] as String,
      webhookUrl: json['webhookUrl'] as String?,
      country: json['country'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      preselectedInstitutionCode:
          _$JsonConverterFromJson<String, InstitutionCode>(
            json['preselectedInstitutionCode'],
            const InstitutionCodeJsonConverter().fromJson,
          ),
      enableExperimentalInstitutions:
          json['enableExperimentalInstitutions'] as bool?,
      prefilledUsername: json['prefilledUsername'] == null
          ? null
          : PrefilledUsernameModel.fromJson(
              json['prefilledUsername'] as Map<String, dynamic>,
            ),
      taskId: json['taskId'] as String?,
      clientName: json['clientName'] as String?,
    );

Map<String, dynamic> _$LinkIntentDataModelToJson(
  LinkIntentDataModel instance,
) => <String, dynamic>{
  'linkWidgetToken': instance.linkWidgetToken,
  'mode': instance.mode,
  'webhookUrl': instance.webhookUrl,
  'country': instance.country,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'preselectedInstitutionCode': _$JsonConverterToJson<String, InstitutionCode>(
    instance.preselectedInstitutionCode,
    const InstitutionCodeJsonConverter().toJson,
  ),
  'enableExperimentalInstitutions': instance.enableExperimentalInstitutions,
  'prefilledUsername': instance.prefilledUsername,
  'taskId': instance.taskId,
  'clientName': instance.clientName,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

PrefilledUsernameModel _$PrefilledUsernameModelFromJson(
  Map<String, dynamic> json,
) => PrefilledUsernameModel(
  username: json['username'] as String,
  mandatory: json['mandatory'] as bool,
);

Map<String, dynamic> _$PrefilledUsernameModelToJson(
  PrefilledUsernameModel instance,
) => <String, dynamic>{
  'username': instance.username,
  'mandatory': instance.mandatory,
};
