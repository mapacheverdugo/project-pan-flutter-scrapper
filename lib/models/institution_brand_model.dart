import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/institution_brand.dart';

part 'institution_brand_model.g.dart';

@JsonSerializable()
class InstitutionBrandModel {
  final String id;
  final String name;

  @JsonKey(name: 'logoPositiveUrl')
  final String? logoPositiveUrl;

  @JsonKey(name: 'logoNegativeUrl')
  final String? logoNegativeUrl;

  @JsonKey(name: 'iconPositiveUrl')
  final String? iconPositiveUrl;

  @JsonKey(name: 'iconNegativeUrl')
  final String? iconNegativeUrl;

  @JsonKey(name: 'iconAltUrl')
  final String? iconAltUrl;

  @JsonKey(name: 'mainColor')
  final String? mainColor;

  @JsonKey(name: 'primaryColor')
  final String? primaryColor;

  @JsonKey(name: 'suggestedIconOnMainColor')
  final String? suggestedIconOnMainColor;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  InstitutionBrandModel({
    required this.id,
    required this.name,
    this.logoPositiveUrl,
    this.logoNegativeUrl,
    this.iconPositiveUrl,
    this.iconNegativeUrl,
    this.iconAltUrl,
    this.mainColor,
    this.primaryColor,
    this.suggestedIconOnMainColor,
    this.createdAt,
    this.updatedAt,
  });

  factory InstitutionBrandModel.fromJson(Map<String, dynamic> json) =>
      _$InstitutionBrandModelFromJson(json);

  Map<String, dynamic> toJson() => _$InstitutionBrandModelToJson(this);

  /// Converts the model to an entity
  InstitutionBrand toEntity() {
    return InstitutionBrand(
      id: id,
      name: name,
      logoPositiveUrl: logoPositiveUrl,
      logoNegativeUrl: logoNegativeUrl,
      iconPositiveUrl: iconPositiveUrl,
      iconNegativeUrl: iconNegativeUrl,
      iconAltUrl: iconAltUrl,
      mainColorHex: mainColor,
      primaryColorHex: primaryColor,
      suggestedIconOnMainColor: suggestedIconOnMainColor,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
