import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/models/connection/amount_json_converter.dart';
import 'package:pan_scrapper/models/connection/card_brand.dart';
import 'package:pan_scrapper/models/connection/card_brand_json_converter.dart';
import 'package:pan_scrapper/models/connection/credit_balance.dart';
import 'package:pan_scrapper/models/connection/product_type.dart';
import 'package:pan_scrapper/models/connection/product_type_json_converter.dart';

part 'product.g.dart';

@JsonSerializable(
  explicitToJson: true,
  converters: [
    AmountJsonConverter(),
    ProductTypeJsonConverter(),
    CardBrandJsonConverter(),
  ],
)
class ExtractedProductModel {
  final String providerId;
  final String number;
  final String name;
  final ProductType type;
  final CardBrand? cardBrand;
  final String? cardLast4Digits;
  final Amount? availableAmount;
  final List<ExtractedCreditBalance>? creditBalances;
  final Map<String, dynamic>? metadata;

  ExtractedProductModel({
    required this.providerId,
    required this.number,
    required this.name,
    required this.type,
    this.cardBrand,
    this.cardLast4Digits,
    this.availableAmount,
    this.creditBalances,
    this.metadata,
  });

  factory ExtractedProductModel.fromJson(Map<String, dynamic> json) =>
      _$ExtractedProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedProductModelToJson(this);
}
