import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/extracted_transaction.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({super.key, required this.transaction});

  final ExtractedTransactionWithoutProviderId transaction;

  String? get _transactionDateTime {
    var str = transaction.transactionDate;

    if (str != null && transaction.transactionTime != null) {
      str += ' ${transaction.transactionTime}';
    }

    return str;
  }

  String? get _countryCity {
    var str = "";
    str += transaction.country ?? '';

    if (transaction.city != null) {
      if (str.isNotEmpty) {
        str += ' | ';
      }

      str += transaction.city!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transaction.description,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 4),
          Text(
            'Amount: ${transaction.amount.formattedDependingOnCurrency} ${transaction.amount.currency}',
          ),
          if (transaction.originalAmount != null)
            Text(
              'Original Amount: ${transaction.originalAmount?.formattedDependingOnCurrency} ${transaction.originalAmount?.currency}',
            ),
          if (_transactionDateTime != null) Text('Date: $_transactionDateTime'),
          if (transaction.processingDate != null)
            Text('Processing Date: ${transaction.processingDate}'),
          if (_countryCity != null) Text('Country/City: $_countryCity'),
        ],
      ),
    );
  }
}
