import 'package:pan_scrapper/helpers/amount_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/available_amount.dart';
import 'package:pan_scrapper/models/credit_balance.dart';
import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/models/product_type.dart';
import 'package:pan_scrapper/services/models/cl_scotiabank_personas/card_with_details_model.dart';
import 'package:pan_scrapper/services/models/cl_scotiabank_personas/index.dart';

class ClScotiabankPersonasProductMapper {
  static List<Product> fromDepositaryAccounts(
    List<ClScotiabankPersonasDepositaryAccountResponseModel> accounts,
  ) {
    return accounts.map((account) {
      return Product(
        number: removeEverythingButNumbers(account.displayId ?? ''),
        name: account.description ?? '',
        type: ProductType.depositaryAccount,
        availableAmount:
            account.amountAvailable != null && account.currencyCode != null
            ? AvailableAmount(
                amount: Amount.parse(
                  account.amountAvailable!,
                  _nationalOptions,
                ).value!.toInt(),
                currency: account.currencyCode!,
              )
            : null,
        isForSecondaryCardHolder: false,
      );
    }).toList();
  }

  static List<Product> fromCreditCards(
    List<ClScotiabankPersonasCardWithDetailsModel> cardsWithDetails,
  ) {
    return cardsWithDetails.map((cardWithDetails) {
      final card = cardWithDetails.card;
      final details = cardWithDetails.details;
      // Extract card number and last 4 digits
      final cardId = card.id ?? '';
      final last4Digits = cardId.length >= 4
          ? cardId.substring(cardId.length - 4)
          : cardId;

      // Extract credit balances from details if available
      // The structure may vary, so we'll need to adjust based on actual API response
      final creditBalances = <CreditBalance>[];

      final nationalAmount = Amount.parse(
        details.nationalAmount!,
        _nationalOptions,
      ).value;
      final nationalAmountAvailable = Amount.parse(
        details.nationalAmountAvailable!,
        _nationalOptions,
      ).value;
      final internationalAmount = Amount.parse(
        details.internationalAmount!,
        _internationalOptions,
      ).value;
      final internationalAmountAvailable = Amount.parse(
        details.internationalAmountAvailable!,
        _internationalOptions,
      ).value;

      if (nationalAmount != null && nationalAmountAvailable != null) {
        final usedAmount = nationalAmount - nationalAmountAvailable;
        creditBalances.add(
          CreditBalance(
            creditLimitAmount: nationalAmount.toInt(),
            availableAmount: nationalAmountAvailable.toInt(),
            usedAmount: usedAmount.toInt(),
            currency: 'CLP',
          ),
        );
      }

      if (internationalAmount != null && internationalAmountAvailable != null) {
        final usedAmount = internationalAmount - internationalAmountAvailable;
        creditBalances.add(
          CreditBalance(
            creditLimitAmount: internationalAmount.toInt(),
            availableAmount: internationalAmountAvailable.toInt(),
            usedAmount: usedAmount.toInt(),
            currency: 'USD',
          ),
        );
      }
      return Product(
        number: cardId,
        name: card.description ?? '',
        type: ProductType.creditCard,
        cardLast4Digits: last4Digits.isNotEmpty ? last4Digits : null,
        creditBalances: creditBalances.isNotEmpty ? creditBalances : null,
        isForSecondaryCardHolder: false,
      );
    }).toList();
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
