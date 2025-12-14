import 'package:pan_scrapper/helpers/amount_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/available_amount.dart';
import 'package:pan_scrapper/models/credit_balance.dart';
import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/models/product_type.dart';
import 'package:pan_scrapper/services/models/cl_banco_chile_personas/index.dart';

class ClBancoChilePersonasProductMapper {
  static List<Product> fromProductsAndBalances(
    ClBancoChilePersonasProductsResponseModel rawProducts,
    List<ClBancoChilePersonasDepositaryBalancesResponseModel> depositaryBalances,
    List<ClBancoChilePersonasCardsBalancesResponseModel> cardsBalances,
  ) {
    final productList = <Product>[];

    // Create maps for quick lookup
    final depositaryBalancesMap = <String, ClBancoChilePersonasDepositaryBalancesResponseModel>{};
    for (final balance in depositaryBalances) {
      if (balance.id != null) {
        depositaryBalancesMap[balance.id!] = balance;
      }
    }

    final cardsBalancesMap = <String, ClBancoChilePersonasCardsBalancesResponseModel>{};
    for (final balance in cardsBalances) {
      if (balance.id != null) {
        cardsBalancesMap[balance.id!] = balance;
      }
    }

    // Process each product
    for (final producto in rawProducts.productos) {
      if (producto.id == null) continue;

      final productId = producto.id!;
      final isCard = cardsBalancesMap.containsKey(productId);
      final isDepositary = depositaryBalancesMap.containsKey(productId);

      if (isCard) {
        // Credit card product
        final cardBalance = cardsBalancesMap[productId]!;
        final creditBalances = <CreditBalance>[];

        // Process each currency available in the card balance
        if (cardBalance.cupoTotal != null &&
            cardBalance.cupoDisponible != null &&
            cardBalance.codigoMoneda != null) {
          final currency = cardBalance.codigoMoneda!;
          final options = currency == 'CLP' ? _nationalOptions : _internationalOptions;

          final creditLimit = Amount.parse(cardBalance.cupoTotal!, options).value;
          final available = Amount.parse(cardBalance.cupoDisponible!, options).value;
          final used = cardBalance.cupoUtilizado != null
              ? Amount.parse(cardBalance.cupoUtilizado!, options).value
              : null;

          if (creditLimit != null && available != null) {
            final usedAmount = used ?? (creditLimit - available);
            creditBalances.add(
              CreditBalance(
                creditLimitAmount: creditLimit.toInt(),
                availableAmount: available.toInt(),
                usedAmount: usedAmount.toInt(),
                currency: currency,
              ),
            );
          }
        }

        final mascara = cardBalance.mascara ?? producto.mascara ?? '';
        final last4Digits = mascara.length >= 4
            ? mascara.substring(mascara.length - 4)
            : mascara;

        productList.add(
          Product(
            number: productId,
            name: cardBalance.descripcionLogo ?? producto.descripcionLogo ?? '',
            type: ProductType.creditCard,
            cardLast4Digits: last4Digits.isNotEmpty ? last4Digits : null,
            creditBalances: creditBalances.isNotEmpty ? creditBalances : null,
            isForSecondaryCardHolder: false,
          ),
        );
      } else if (isDepositary) {
        // Depositary account product
        final depositaryBalance = depositaryBalancesMap[productId]!;

        if (depositaryBalance.saldoDisponible != null &&
            depositaryBalance.codigoMoneda != null) {
          final currency = depositaryBalance.codigoMoneda!;
          final options = currency == 'CLP' ? _nationalOptions : _internationalOptions;

          final saldoDisponible = Amount.parse(
            depositaryBalance.saldoDisponible!,
            options,
          ).value;

          if (saldoDisponible != null) {
            final accountNumber = producto.numero ?? depositaryBalance.numero ?? productId;
            
            productList.add(
              Product(
                number: removeEverythingButNumbers(accountNumber),
                name: producto.descripcionLogo ?? '',
                type: ProductType.depositaryAccount,
                availableAmount: AvailableAmount(
                  amount: saldoDisponible.toInt(),
                  currency: currency,
                ),
                isForSecondaryCardHolder: false,
              ),
            );
          }
        }
      } else {
        // Product without balance info - create basic product
        final accountNumber = producto.numero ?? productId;
        productList.add(
          Product(
            number: removeEverythingButNumbers(accountNumber),
            name: producto.descripcionLogo ?? '',
            type: ProductType.depositaryAccount,
            isForSecondaryCardHolder: false,
          ),
        );
      }
    }

    return productList;
  }

  static final _nationalOptions = AmountOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
    currencyDecimals: 0,
  );

  static final _internationalOptions = AmountOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
    currencyDecimals: 2,
  );
}

