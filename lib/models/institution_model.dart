import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/converters/institution_code_json_converter.dart';
import 'package:pan_scrapper/converters/institution_status_json_converter.dart';
import 'package:pan_scrapper/entities/institution.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/entities/institution_status.dart';
import 'package:pan_scrapper/models/institution_brand_model.dart';

part 'institution_model.g.dart';

@JsonSerializable(
  converters: [
    InstitutionStatusJsonConverter(),
    InstitutionCodeJsonConverter(),
  ],
)
class InstitutionModel {
  final String id;
  final InstitutionCode code;
  final String country;
  final InstitutionStatus status;

  @JsonKey(name: 'brandId')
  final String brandId;

  final InstitutionBrandModel brand;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  InstitutionModel({
    required this.id,
    required this.code,
    required this.country,
    required this.status,
    required this.brandId,
    required this.brand,
    this.createdAt,
    this.updatedAt,
  });

  factory InstitutionModel.fromEntity(Institution institution) =>
      InstitutionModel(
        id: institution.id,
        code: institution.code,
        country: institution.country,
        status: institution.status,
        brandId: institution.brandId,
        brand: InstitutionBrandModel.fromEntity(institution.brand),
        createdAt: institution.createdAt,
        updatedAt: institution.updatedAt,
      );

  factory InstitutionModel.fromJson(Map<String, dynamic> json) =>
      _$InstitutionModelFromJson(json);

  Map<String, dynamic> toJson() => _$InstitutionModelToJson(this);

  /// Converts the model to an entity
  Institution toEntity() {
    return Institution(
      id: id,
      code: code,
      country: country,
      status: status,
      brandId: brandId,
      brand: brand.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
