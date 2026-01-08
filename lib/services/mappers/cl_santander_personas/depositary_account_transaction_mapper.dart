import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/currency.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/models/cl_santander_personas/index.dart';

class ClSantanderPersonasDepositaryAccountTransactionMapper {
  /// Parses a number string that may have a symbol (+ or -) at the end
  static double _parseNumberWithSymbolAtEnd(String text) {
    final symbolAtTheEnd = text.endsWith('+') || text.endsWith('-');
    final numberText = symbolAtTheEnd
        ? text.substring(0, text.length - 1)
        : text;
    final symbolText = symbolAtTheEnd ? text.substring(text.length - 1) : '';
    final parsedNumber = double.tryParse(numberText) ?? 0.0;
    return symbolText == '-' ? -parsedNumber : parsedNumber;
  }

  /// Generates a unique transaction ID from transaction data
  static String _generateTransactionId(
    String transactionDate,
    String movementNumber,
    String amount,
    String description,
  ) {
    final combined = '$transactionDate|$movementNumber|$amount|$description';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  static List<Transaction> fromResponseModel(
    ClSantanderPersonasDepositaryAccountTransactionResponseModel model,
    Currency productCurrency,
  ) {
    if (model.movements.isEmpty) {
      return [];
    }

    final currency =
        Currency.tryFromIsoLetters(model.repositioningExit?.divisa) ??
        productCurrency;
    final transactions = <Transaction>[];

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
          Currency.clp,
          options: AmountParseOptions(factor: 100),
        );

        if (amount == null) {
          continue; // Skip transactions without amount
        }

        // Generate transaction ID
        final movementNumber = movement.movementNumber ?? '';
        final transactionId = _generateTransactionId(
          transactionDate,
          movementNumber,
          amount.value.toString(),
          description,
        );

        transactions.add(
          Transaction(
            id: transactionId,
            type: TransactionType.default_,
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
