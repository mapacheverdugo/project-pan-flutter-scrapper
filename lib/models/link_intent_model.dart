import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/entities/link_intent.dart';
import 'package:pan_scrapper/models/institution_code_json_converter.dart';

part 'link_intent_model.g.dart';

@JsonSerializable()
class LinkIntentResponseModel {
  final bool success;
  final LinkIntentDataModel data;

  LinkIntentResponseModel({required this.success, required this.data});

  factory LinkIntentResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LinkIntentResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$LinkIntentResponseModelToJson(this);
}

@JsonSerializable(converters: [InstitutionCodeJsonConverter()])
class LinkIntentDataModel {
  @JsonKey(name: 'linkWidgetToken')
  final String linkWidgetToken;

  final String mode;

  @JsonKey(name: 'webhookUrl')
  final String? webhookUrl;

  final String? country;

  @JsonKey(name: 'expiresAt')
  final DateTime? expiresAt;

  @JsonKey(name: 'preselectedInstitutionCode')
  final InstitutionCode? preselectedInstitutionCode;

  @JsonKey(name: 'enableExperimentalInstitutions')
  final bool? enableExperimentalInstitutions;

  @JsonKey(name: 'prefilledUsername')
  final PrefilledUsernameModel? prefilledUsername;

  @JsonKey(name: 'taskId')
  final String? taskId;

  @JsonKey(name: 'clientName')
  final String? clientName;

  LinkIntentDataModel({
    required this.linkWidgetToken,
    required this.mode,
    this.webhookUrl,
    this.country,
    this.expiresAt,
    this.preselectedInstitutionCode,
    this.enableExperimentalInstitutions,
    this.prefilledUsername,
    this.taskId,
    this.clientName,
  });

  factory LinkIntentDataModel.fromJson(Map<String, dynamic> json) =>
      _$LinkIntentDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LinkIntentDataModelToJson(this);

  LinkIntent toEntity() {
    return LinkIntent(
      linkWidgetToken: linkWidgetToken,
      mode: mode,
      webhookUrl: webhookUrl,
      country: country,
      expiresAt: expiresAt,
      preselectedInstitutionCode: preselectedInstitutionCode,
      enableExperimentalInstitutions: enableExperimentalInstitutions,
      prefilledUsername: prefilledUsername?.toEntity(),
      taskId: taskId,
      clientName: clientName,
    );
  }
}

@JsonSerializable()
class PrefilledUsernameModel {
  final String username;
  final bool mandatory;

  PrefilledUsernameModel({required this.username, required this.mandatory});

  factory PrefilledUsernameModel.fromJson(Map<String, dynamic> json) =>
      _$PrefilledUsernameModelFromJson(json);

  Map<String, dynamic> toJson() => _$PrefilledUsernameModelToJson(this);

  /// Converts the model to an entity
  PrefilledUsername toEntity() {
    return PrefilledUsername(username: username, mandatory: mandatory);
  }
}
