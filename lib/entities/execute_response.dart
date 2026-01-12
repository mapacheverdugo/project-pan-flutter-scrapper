import 'package:json_annotation/json_annotation.dart';

part 'execute_response.g.dart';

@JsonSerializable()
class ExecuteResponse {
  final String id;
  final String exchangeToken;

  ExecuteResponse({required this.id, required this.exchangeToken});

  factory ExecuteResponse.fromJson(Map<String, dynamic> json) =>
      _$ExecuteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExecuteResponseToJson(this);
}
