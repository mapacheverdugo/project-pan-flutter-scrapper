// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execute_link_token_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecuteLinkTokenResultModel _$ExecuteLinkTokenResultModelFromJson(
  Map<String, dynamic> json,
) => ExecuteLinkTokenResultModel(
  connectionId: json['id'] as String,
  usernameHash: json['usernameHash'] as String,
);

Map<String, dynamic> _$ExecuteLinkTokenResultModelToJson(
  ExecuteLinkTokenResultModel instance,
) => <String, dynamic>{
  'id': instance.connectionId,
  'usernameHash': instance.usernameHash,
};
