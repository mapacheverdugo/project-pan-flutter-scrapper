import 'package:pan_scrapper/helpers/amount_helpers.dart';
import 'package:pan_scrapper/models/available_amount.dart';
import 'package:pan_scrapper/models/card_brand.dart';
import 'package:pan_scrapper/models/credit_balance.dart';
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
      AvailableAmount? availableAmount;
      final creditBalances = <CreditBalance>[];
      final productId = producto.id;
      final productType = _getProductType(producto.tipo);
      final isCard = productType == ProductType.creditCard;

      if (isCard) {
        final cardBalance = cardsBalancesMap[productId]!;

        for (final cupo in cardBalance.cupos) {
          final currency = cupo.moneda == r'$' ? 'CLP' : cupo.moneda;
          final options = currency == 'CLP'
              ? _nationalOptions
              : _internationalOptions;

          final creditLimit = Amount.parse(cupo.cupo.toString(), options).value;
          final available = Amount.parse(
            cupo.disponible.toString(),
            options,
          ).value;
          final used = cupo.cupo - cupo.disponible;

          if (creditLimit != null && available != null) {
            creditBalances.add(
              CreditBalance(
                creditLimitAmount: creditLimit.toInt(),
                availableAmount: available.toInt(),
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
            ? 'CLP'
            : depositaryBalance.moneda;

        if (depositaryBalance.cupo == 0 || depositaryBalance.cupo == null) {
          availableAmount = AvailableAmount(
            currency: currency,
            amount: Amount.parse(
              depositaryBalance.disponible.toString(),
              _nationalOptions,
            ).value!.toInt(),
          );
        } else {
          final available = Amount.parse(
            depositaryBalance.disponible.toString(),
            _nationalOptions,
          ).value;

          final creditLimit = Amount.parse(
            depositaryBalance.cupo.toString(),
            _nationalOptions,
          ).value;

          if (creditLimit != null && available != null) {
            final used = creditLimit - available;

            creditBalances.add(
              CreditBalance(
                creditLimitAmount: creditLimit.toInt(),
                availableAmount: available.toInt(),
                usedAmount: used.toInt(),
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

  static final _nationalOptions = AmountOptions(
    thousandSeparator: null,
    decimalSeparator: '.',
    currencyDecimals: 0,
  );

  static final _internationalOptions = AmountOptions(
    thousandSeparator: null,
    decimalSeparator: '.',
    currencyDecimals: 2,
  );
}
