import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pan_scrapper/helpers/amount_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
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
    String productCurrency,
  ) {
    if (model.movements.isEmpty) {
      return [];
    }

    final currency = model.repositioningExit?.divisa ?? productCurrency;
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

        final amount = Amount.parse(movementAmount, AmountOptions(factor: 100));

        final amountValue = amount.value;
        if (amountValue == null) {
          continue; // Skip transactions without amount
        }

        // Generate transaction ID
        final movementNumber = movement.movementNumber ?? '';
        final transactionId = _generateTransactionId(
          transactionDate,
          movementNumber,
          amountValue.toString(),
          description,
        );

        transactions.add(
          Transaction(
            id: transactionId,
            type: TransactionType.default_,
            description: description,
            amount: TransactionAmountRequired(
              amount: amountValue.toInt(),
              currency: currency,
            ),
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            processingDate: processingDate,
            originalAmount: TransactionAmountOptional(
              amount: amountValue.toInt(),
              currency: currency,
            ),
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
