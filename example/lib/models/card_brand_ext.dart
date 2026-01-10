import 'package:pan_scrapper/entities/card_brand.dart';

extension CardBrandExtension on CardBrand {
  String get label {
    switch (this) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.diners:
        return 'Diners';
      case CardBrand.other:
        return 'Otro';
    }
  }
}
