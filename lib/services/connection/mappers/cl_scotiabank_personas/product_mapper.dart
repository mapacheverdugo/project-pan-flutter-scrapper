import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/card_brand.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/product_type.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/connection/credit_balance.dart';
import 'package:pan_scrapper/models/connection/product.dart';
import 'package:pan_scrapper/services/connection/models/cl_scotiabank_personas/card_with_details_model.dart';
import 'package:pan_scrapper/services/connection/models/cl_scotiabank_personas/index.dart';

class ClScotiabankPersonasProductMapper {
  static CardBrand _getCardBrand(String description) {
    if (description.toLowerCase().contains('visa')) {
      return CardBrand.visa;
    } else if (description.toLowerCase().contains('mastercard')) {
      return CardBrand.mastercard;
    } else if (description.toLowerCase().contains('american express')) {
      return CardBrand.amex;
    } else if (description.toLowerCase().contains('diners')) {
      return CardBrand.diners;
    }
    return CardBrand.other;
  }

  static ProductType _getProductType(String type) {
    switch (type) {
      case 'CTACTE':
        return ProductType.depositaryAccount;
      case 'LICRED':
        return ProductType.depositaryAccountCreditLine;
      default:
        return ProductType.unknown;
    }
  }

  static List<ExtractedProductModel> fromDepositaryAccounts(
    List<ClScotiabankPersonasDepositaryAccountResponseModel> accounts,
  ) {
    return accounts.map((account) {
      final productType = _getProductType(account.type);

      final currency = Currency.fromIsoLetters(account.currencyCode);
      final options = currency == Currency.clp
          ? _nationalOptions
          : _internationalOptions;

      final availableAmount = Amount.parse(
        account.amountAvailable,
        currency,
        options: options,
      ).value;

      final creditLimitAmount = Amount.parse(
        account.totalBalance,
        currency,
        options: options,
      ).value;

      final usedAmount = creditLimitAmount - availableAmount;

      final creditBalances = <ExtractedCreditBalance>[];
      if (productType == ProductType.depositaryAccountCreditLine) {
        creditBalances.add(
          ExtractedCreditBalance(
            creditLimitAmount: creditLimitAmount.toInt(),
            availableAmount: availableAmount.toInt(),
            usedAmount: usedAmount.toInt(),
            currency: currency,
          ),
        );
      }

      final productId = createProductId(
        rawDisplayId: account.displayId,
        rawType: account.type,
        rawCurrencyCode: account.currencyCode,
      );

      return ExtractedProductModel(
        providerId: productId,
        number: removeEverythingButNumbers(account.displayId),
        name: account.description,
        type: productType,
        availableAmount: creditBalances.isEmpty
            ? Amount(value: availableAmount.toInt(), currency: currency)
            : null,
        creditBalances: creditBalances,
      );
    }).toList();
  }

  static List<ExtractedProductModel> fromCreditCards(
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
      final creditBalances = <ExtractedCreditBalance>[];

      final nationalAmount = Amount.tryParse(
        details.nationalAmount!,
        Currency.clp,
        options: _nationalOptions,
      )?.value;
      final nationalAmountAvailable = Amount.tryParse(
        details.nationalAmountAvailable!,
        Currency.clp,
        options: _nationalOptions,
      )?.value;
      final internationalAmount = Amount.tryParse(
        details.internationalAmount!,
        Currency.usd,
        options: _internationalOptions,
      )?.value;
      final internationalAmountAvailable = Amount.tryParse(
        details.internationalAmountAvailable!,
        Currency.usd,
        options: _internationalOptions,
      )?.value;

      if (nationalAmount != null && nationalAmountAvailable != null) {
        final usedAmount = nationalAmount - nationalAmountAvailable;
        creditBalances.add(
          ExtractedCreditBalance(
            creditLimitAmount: nationalAmount.toInt(),
            availableAmount: nationalAmountAvailable.toInt(),
            usedAmount: usedAmount.toInt(),
            currency: Currency.clp,
          ),
        );
      }

      if (internationalAmount != null && internationalAmountAvailable != null) {
        final usedAmount = internationalAmount - internationalAmountAvailable;
        creditBalances.add(
          ExtractedCreditBalance(
            creditLimitAmount: internationalAmount.toInt(),
            availableAmount: internationalAmountAvailable.toInt(),
            usedAmount: usedAmount.toInt(),
            currency: Currency.usd,
          ),
        );
      }

      // Create product ID in the format: cardId_CREDITCARD (no currency for credit cards)
      final productId = createProductId(
        rawDisplayId: cardId,
        rawType: 'CREDITCARD',
      );

      return ExtractedProductModel(
        providerId: productId,
        number: cardId,
        name: card.description,
        type: ProductType.creditCard,
        cardBrand: _getCardBrand(card.description),
        cardLast4Digits: last4Digits.isNotEmpty ? last4Digits : null,
        creditBalances: creditBalances.isNotEmpty ? creditBalances : null,
      );
    }).toList();
  }

  static final _nationalOptions = AmountParseOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
  );

  static final _internationalOptions = AmountParseOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
  );

  /// Creates a product ID in the format: displayId_type_currencyCode (for depositary accounts/credit lines)
  /// or displayId_type (for credit cards)
  static String createProductId({
    required String rawDisplayId,
    required String rawType,
    String? rawCurrencyCode,
  }) {
    if (rawCurrencyCode != null && rawCurrencyCode.isNotEmpty) {
      return '${rawDisplayId}_${rawType}_$rawCurrencyCode';
    }
    return '${rawDisplayId}_${rawType}';
  }

  /// Parses a product ID to extract its components
  static ClScotiabankPersonasProductIdMetadata parseProductId(
    String productId,
  ) {
    final parts = productId.split('_');
    return ClScotiabankPersonasProductIdMetadata(
      rawDisplayId: parts.length > 0 ? parts[0] : '',
      rawType: parts.length > 1 ? parts[1] : '',
      rawCurrencyCode: parts.length > 2 ? parts[2] : '',
    );
  }
}
