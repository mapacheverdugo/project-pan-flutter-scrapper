import 'package:pan_scrapper/models/connection/product_type.dart';

extension ProductTypeExtension on ProductType {
  String get label {
    switch (this) {
      case ProductType.depositaryAccount:
        return 'Cuenta Corriente';
      case ProductType.creditCard:
        return 'Tarjeta de Crédito';
      case ProductType.depositaryAccountCreditLine:
        return 'Línea de Crédito';
      case ProductType.unknown:
        return 'Otro';
    }
  }
}
