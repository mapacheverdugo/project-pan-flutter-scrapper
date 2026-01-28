import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/entities/local_connection.dart';

part 'local_connection_model.g.dart';

@JsonSerializable()
class LocalConnectionModel {
  final String id;
  final InstitutionCode institutionCode;
  final String rawUsername;
  final String password;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? lastSyncDateTime;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? lastFullSyncDateTime;

  LocalConnectionModel({
    required this.id,
    required this.institutionCode,
    required this.rawUsername,
    required this.password,
    this.lastSyncDateTime,
    this.lastFullSyncDateTime,
  });

  static DateTime? _dateTimeFromJson(String? json) =>
      json != null ? DateTime.parse(json) : null;

  static String? _dateTimeToJson(DateTime? dateTime) =>
      dateTime?.toIso8601String();

  factory LocalConnectionModel.fromJson(Map<String, dynamic> json) =>
      _$LocalConnectionModelFromJson(json);

  factory LocalConnectionModel.fromEntity(LocalConnection connection) =>
      LocalConnectionModel(
        id: connection.id,
        institutionCode: connection.institutionCode,
        rawUsername: connection.rawUsername,
        password: connection.password,
        lastSyncDateTime: connection.lastSyncDateTime,
        lastFullSyncDateTime: connection.lastFullSyncDateTime,
      );

  Map<String, dynamic> toJson() => _$LocalConnectionModelToJson(this);

  LocalConnection toEntity() => LocalConnection(
    id: id,
    institutionCode: institutionCode,
    rawUsername: rawUsername,
    password: password,
    lastSyncDateTime: lastSyncDateTime,
    lastFullSyncDateTime: lastFullSyncDateTime,
  );
}
