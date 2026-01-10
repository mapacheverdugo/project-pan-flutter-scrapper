import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/institution_brand.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/entities/institution_status.dart';

class Institution {
  final String id;
  final InstitutionCode code;
  final String country;
  final InstitutionStatus status;
  final String brandId;
  final InstitutionBrand brand;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Institution({
    required this.id,
    required this.code,
    required this.country,
    required this.status,
    required this.brandId,
    required this.brand,
    this.createdAt,
    this.updatedAt,
  });

  // Helper methods
  String get name => brand.name;

  String? get logoPositiveUrl => brand.logoPositiveUrl;

  String? get logoNegativeUrl => brand.logoNegativeUrl;

  String? get iconPositiveUrl => brand.iconPositiveUrl;

  String? get iconNegativeUrl => brand.iconNegativeUrl;

  String? get iconAltUrl => brand.iconAltUrl;

  Color? get mainColor => brand.mainColor;

  Color? get primaryColor => brand.primaryColor;

  String? get suggestedIconOnMainColor => brand.suggestedIconOnMainColor;
}
