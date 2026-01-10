import 'package:flutter/material.dart';

class InstitutionBrand {
  final String id;
  final String name;
  final String? logoPositiveUrl;
  final String? logoNegativeUrl;
  final String? iconPositiveUrl;
  final String? iconNegativeUrl;
  final String? iconAltUrl;
  final String? mainColorHex;
  final String? primaryColorHex;
  final String? suggestedIconOnMainColor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InstitutionBrand({
    required this.id,
    required this.name,
    this.logoPositiveUrl,
    this.logoNegativeUrl,
    this.iconPositiveUrl,
    this.iconNegativeUrl,
    this.iconAltUrl,
    this.mainColorHex,
    this.primaryColorHex,
    this.suggestedIconOnMainColor,
    this.createdAt,
    this.updatedAt,
  });

  Color? get mainColor {
    return _colorFromHex(mainColorHex);
  }

  Color? get primaryColor {
    return _colorFromHex(primaryColorHex);
  }

  Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) {
      return null;
    }
    final colorString = hex.replaceAll('#', '');
    return Color(int.parse(colorString, radix: 16) + 0xFF000000);
  }
}
