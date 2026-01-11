// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extraction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Extraction _$ExtractionFromJson(Map<String, dynamic> json) => Extraction(
  payload: json['payload'],
  params: json['params'] as Map<String, dynamic>?,
  operation: const ExtractionOperationJsonConverter().fromJson(
    json['operation'] as String,
  ),
);

Map<String, dynamic> _$ExtractionToJson(Extraction instance) =>
    <String, dynamic>{
      'payload': instance.payload,
      'params': instance.params,
      'operation': const ExtractionOperationJsonConverter().toJson(
        instance.operation,
      ),
    };
