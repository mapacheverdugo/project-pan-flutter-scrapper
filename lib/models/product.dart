import 'package:pan_scrapper/models/available_amount.dart';
import 'package:pan_scrapper/models/card_brand.dart';
import 'package:pan_scrapper/models/credit_balance.dart';
import 'package:pan_scrapper/models/product_type.dart';

class Product {
  final String id;
  final String number;
  final CardBrand? cardBrand;
  final String? cardLast4Digits;
  final String name;
  final ProductType type;
  final AvailableAmount? availableAmount;
  final List<CreditBalance>? creditBalances;
  final bool isForSecondaryCardHolder;

  Product({
    required this.id,
    required this.number,
    required this.name,
    required this.type,
    this.cardBrand,
    this.cardLast4Digits,
    this.availableAmount,
    this.creditBalances,
    required this.isForSecondaryCardHolder,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      number: json['number'] as String,
      cardBrand: json['cardBrand'] != null
          ? CardBrand.values.firstWhere(
              (e) => e.name == json['cardBrand'],
              orElse: () => CardBrand.other,
            )
          : null,
      cardLast4Digits: json['cardLast4Digits'] as String?,
      name: json['name'] as String,
      type: ProductType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ProductType.unknown,
      ),
      availableAmount: json['availableAmount'] != null
          ? AvailableAmount.fromJson(
              json['availableAmount'] as Map<String, dynamic>,
            )
          : null,
      creditBalances: json['creditBalances'] != null
          ? (json['creditBalances'] as List<dynamic>)
                .map((e) => CreditBalance.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      isForSecondaryCardHolder: json['isForSecondaryCardHolder'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'cardBrand': cardBrand?.name,
      'cardLast4Digits': cardLast4Digits,
      'name': name,
      'type': type.name,
      'availableAmount': availableAmount?.toJson(),
      'creditBalances': creditBalances?.map((e) => e.toJson()).toList(),
      'isForSecondaryCardHolder': isForSecondaryCardHolder,
    };
  }
}
