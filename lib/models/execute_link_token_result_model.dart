import 'package:json_annotation/json_annotation.dart';

part 'execute_link_token_result_model.g.dart';

@JsonSerializable()
class ExecuteLinkTokenResultModel {
  @JsonKey(name: 'id')
  final String connectionId;
  final String usernameHash;

  ExecuteLinkTokenResultModel({
    required this.connectionId,
    required this.usernameHash,
  });

  factory ExecuteLinkTokenResultModel.fromJson(Map<String, dynamic> json) =>
      _$ExecuteLinkTokenResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExecuteLinkTokenResultModelToJson(this);
}
