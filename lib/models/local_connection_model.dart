import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/entities/local_connection.dart';

part 'local_connection_model.g.dart';

@JsonSerializable()
class LocalConnectionModel {
  final String id;
  final InstitutionCode institutionCode;
  final String usernameHash;
  final String rawUsername;
  final String password;

  LocalConnectionModel({
    required this.id,
    required this.institutionCode,
    required this.usernameHash,
    required this.rawUsername,
    required this.password,
  });

  factory LocalConnectionModel.fromJson(Map<String, dynamic> json) =>
      _$LocalConnectionModelFromJson(json);

  factory LocalConnectionModel.fromEntity(LocalConnection connection) =>
      LocalConnectionModel(
        id: connection.id,
        institutionCode: connection.institutionCode,
        usernameHash: connection.usernameHash,
        rawUsername: connection.rawUsername,
        password: connection.password,
      );

  Map<String, dynamic> toJson() => _$LocalConnectionModelToJson(this);

  LocalConnection toEntity() => LocalConnection(
    id: id,
    institutionCode: institutionCode,
    usernameHash: usernameHash,
    rawUsername: rawUsername,
    password: password,
  );
}
