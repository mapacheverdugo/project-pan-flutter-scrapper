import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/connection/models/cl_santander_personas/index.dart';

class ClSantanderPersonasDepositaryAccountTransactionMapper {
  static List<ExtractedTransactionWithoutProviderId> fromResponseModel(
    ClSantanderPersonasDepositaryAccountTransactionResponseModel model,
    Currency productCurrency,
  ) {
    if (model.movements.isEmpty) {
      return [];
    }

    final transactions = <ExtractedTransactionWithoutProviderId>[];

    for (final movement in model.movements) {
      try {
        final transactionDate = nullIfEmpty(movement.transactionDate);
        if (transactionDate == null) {
          continue; // Skip transactions without date
        }

        final processingDate = nullIfEmpty(movement.accountingDate);
        final transactionTime = nullIfEmpty(movement.operationTime);
        final description = nullIfEmpty(movement.expandedCode) ?? '';

        // Parse amount: negative the number divided by 100
        final movementAmount = movement.movementAmount ?? '';
        if (movementAmount.isEmpty) {
          continue; // Skip transactions without amount
        }

        final amount = Amount.tryParse(
          movementAmount,
          productCurrency,
          options: AmountParseOptions(factor: 100),
        );

        if (amount == null) {
          continue; // Skip transactions without amount
        }

        transactions.add(
          ExtractedTransactionWithoutProviderId(
            description: description,
            amount: amount,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            processingDate: processingDate,
            originalAmount: amount,
            city: null,
            country: null,
          ),
        );
      } catch (e) {
        // Skip transactions that fail to parse
        continue;
      }
    }

    return transactions;
  }
}
