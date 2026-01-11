import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/models/connection/product.dart';
import 'package:pan_scrapper/models/institution_code_json_converter.dart';

part 'extracted_connection_result_model.g.dart';

@JsonSerializable(
  converters: [InstitutionCodeJsonConverter()],
  explicitToJson: true,
)
class ExtractedConnectionResultModel {
  final InstitutionCode institutionCode;
  final String username;
  final List<ExtractedProductModel> products;
  final ExtractedConnectionResultCredentialsModel credentials;
  final bool isRemoteSyncEnabled;

  ExtractedConnectionResultModel({
    required this.institutionCode,
    required this.username,
    required this.products,
    required this.credentials,
    this.isRemoteSyncEnabled = false,
  });

  factory ExtractedConnectionResultModel.fromJson(Map<String, dynamic> json) =>
      _$ExtractedConnectionResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedConnectionResultModelToJson(this);
}

@JsonSerializable()
class ExtractedConnectionResultCredentialsModel {
  final String username;
  final String? password;

  ExtractedConnectionResultCredentialsModel({
    required this.username,
    required this.password,
  });

  factory ExtractedConnectionResultCredentialsModel.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedConnectionResultCredentialsModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedConnectionResultCredentialsModelToJson(this);
}
