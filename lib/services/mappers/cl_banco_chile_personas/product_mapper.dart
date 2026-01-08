import 'package:pan_scrapper/models/amount.dart';
import 'package:pan_scrapper/models/card_brand.dart';
import 'package:pan_scrapper/models/credit_balance.dart';
import 'package:pan_scrapper/models/currency.dart';
import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/models/product_type.dart';
import 'package:pan_scrapper/services/models/cl_banco_chile_personas/index.dart';

class ClBancoChilePersonasProductMapper {
  static CardBrand _getCardBrand(String label) {
    if (label.toLowerCase().contains('visa')) {
      return CardBrand.visa;
    } else if (label.toLowerCase().contains('mastercard')) {
      return CardBrand.mastercard;
    } else if (label.toLowerCase().contains('american express')) {
      return CardBrand.amex;
    } else if (label.toLowerCase().contains('diners')) {
      return CardBrand.diners;
    }
    return CardBrand.other;
  }

  static ProductType _getProductType(String tipo) {
    switch (tipo) {
      case 'cuentaCorrienteMonedaLocal':
        return ProductType.depositaryAccount;
      case 'linea':
        return ProductType.depositaryAccountCreditLine;
      case 'tarjeta':
        return ProductType.creditCard;
    }

    if (tipo.toLowerCase().contains('cuentaCorriente')) {
      return ProductType.depositaryAccount;
    }

    return ProductType.unknown;
  }

  static List<Product> fromProductsAndBalances(
    ClBancoChilePersonasProductsResponseModel rawProducts,
    List<ClBancoChilePersonasDepositaryBalancesResponseModel>
    depositaryBalances,
    List<ClBancoChilePersonasCardsBalancesResponseModel> cardsBalances,
  ) {
    final productList = <Product>[];

    final rawProductsMap = <String, ClBancoChilePersonasProducto>{};
    for (final product in rawProducts.productos) {
      rawProductsMap[product.id] = product;
    }

    final depositaryBalancesMap =
        <String, ClBancoChilePersonasDepositaryBalancesResponseModel>{};
    for (final balance in depositaryBalances) {
      depositaryBalancesMap[balance.numero] = balance;
    }

    final cardsBalancesMap =
        <String, ClBancoChilePersonasCardsBalancesResponseModel>{};
    for (final balance in cardsBalances) {
      cardsBalancesMap[balance.idProducto] = balance;
    }

    // Process each product
    for (final producto in rawProductsMap.values) {
      Amount? availableAmount;
      final creditBalances = <CreditBalance>[];
      final productId = producto.id;
      final productType = _getProductType(producto.tipo);
      final isCard = productType == ProductType.creditCard;

      if (isCard) {
        final cardBalance = cardsBalancesMap[productId]!;

        for (final cupo in cardBalance.cupos) {
          final currency = cupo.moneda == r'$'
              ? Currency.clp
              : Currency.fromIsoLetters(cupo.moneda);
          final options = currency == Currency.clp
              ? _nationalOptions
              : _internationalOptions;

          final creditLimit = Amount.tryParse(
            cupo.cupo.toString(),
            currency,
            options: options,
          );
          final available = Amount.tryParse(
            cupo.disponible.toString(),
            currency,
            options: options,
          );
          final used = cupo.cupo - cupo.disponible;

          if (creditLimit != null && available != null) {
            creditBalances.add(
              CreditBalance(
                creditLimitAmount: creditLimit.value,
                availableAmount: available.value,
                usedAmount: used.toInt(),
                currency: currency,
              ),
            );
          }
        }
      } else {
        final depositaryBalance = depositaryBalancesMap[producto.numero];

        if (depositaryBalance == null) continue;

        final currency = depositaryBalance.moneda == r'$'
            ? Currency.clp
            : Currency.fromIsoLetters(depositaryBalance.moneda);

        if (depositaryBalance.cupo == 0 || depositaryBalance.cupo == null) {
          availableAmount = Amount.tryParse(
            depositaryBalance.disponible.toString(),
            currency,
            options: _nationalOptions,
          );
        } else {
          final available = Amount.tryParse(
            depositaryBalance.disponible.toString(),
            currency,
            options: _nationalOptions,
          );

          final creditLimit = Amount.tryParse(
            depositaryBalance.cupo.toString(),
            currency,
            options: _nationalOptions,
          );

          if (creditLimit != null && available != null) {
            final used = creditLimit.value - available.value;

            creditBalances.add(
              CreditBalance(
                creditLimitAmount: creditLimit.value,
                availableAmount: available.value,
                usedAmount: used,
                currency: currency,
              ),
            );
          }
        }
      }

      final mascara = producto.mascara;
      final last4Digits = mascara.length >= 4
          ? mascara.substring(mascara.length - 4)
          : mascara;

      productList.add(
        Product(
          id: productId,
          number: productId,
          name: producto.descripcionLogo?.trim() ?? producto.label.trim(),
          type: productType,
          cardLast4Digits: productType == ProductType.creditCard
              ? last4Digits
              : null,
          cardBrand: productType == ProductType.creditCard
              ? _getCardBrand(producto.label)
              : null,
          availableAmount: availableAmount,
          creditBalances: creditBalances.isNotEmpty ? creditBalances : null,
          isForSecondaryCardHolder: false,
        ),
      );
    }

    return productList;
  }

  static final _nationalOptions = AmountParseOptions(
    thousandSeparator: null,
    decimalSeparator: '.',
    currencyDecimals: 0,
  );

  static final _internationalOptions = AmountParseOptions(
    thousandSeparator: null,
    decimalSeparator: '.',
    currencyDecimals: 2,
  );
}
