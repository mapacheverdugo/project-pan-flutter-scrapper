import 'package:pan_scrapper/models/credit_card_bill_summary.dart';
import 'package:pan_scrapper/models/currency_type.dart';
import 'package:pan_scrapper/models/transaction.dart';

class CreditCardBill {
  final String periodId;
  final CurrencyType currencyType;
  final CreditCardBillSummary summary;
  final List<Transaction> transactions;

  CreditCardBill({
    required this.periodId,
    required this.currencyType,
    required this.summary,
    required this.transactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'periodId': periodId,
      'currencyType': currencyType.name,
      'summary': summary.toJson(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }
}

