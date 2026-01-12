import 'package:pan_scrapper/entities/extracted_transaction.dart';

class CommonsMapper {
  static const String _separator = '|';

  static String _getTransactionId(
    ExtractedTransactionWithoutProviderId transaction,
    String date,
    String? time,
  ) {
    return '$date$_separator${time ?? ''}$_separator${transaction.description}$_separator${transaction.amount.value}';
  }

  static List<ExtractedTransaction> processTransactions(
    List<ExtractedTransactionWithoutProviderId?> transactions,
  ) {
    final mapIdAndQuantity = <String, int>{};

    final transactionsWithNulls = transactions.map((transaction) {
      if (transaction == null) {
        return null;
      }

      if (transaction.amount.value == 0) {
        return null;
      }

      final date = transaction.transactionDate ?? transaction.processingDate;
      final time = transaction.transactionTime;

      if (date == null || date.isEmpty) {
        return null;
      }

      final id = _getTransactionId(transaction, date, time);
      final quantity = mapIdAndQuantity[id] ?? 0;
      mapIdAndQuantity[id] = quantity + 1;
      final idWithQuantity = '${id}$_separator$quantity';

      return ExtractedTransaction(
        providerId: idWithQuantity,
        description: transaction.description,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
        transactionTime: transaction.transactionTime,
        processingDate: transaction.processingDate,
        originalAmount: transaction.originalAmount,
        city: transaction.city,
        country: transaction.country,
      );
    }).toList();

    return transactionsWithNulls.whereType<ExtractedTransaction>().toList();
  }
}
