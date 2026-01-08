import 'package:pan_scrapper/models/amount.dart';
import 'package:pan_scrapper/models/billing_status.dart';
import 'package:pan_scrapper/models/currency_type.dart';
import 'package:pan_scrapper/models/transaction_type.dart';

class TransactionInstallments {
  final int currentCount;
  final int remainingCount;
  final int totalCount;
  final Amount currentAmount;
  final Amount? originalTransactionAmount;
  final Amount? totalFinalAmount;
  final double? interestRate;
  final String firstInstallmentDate;

  TransactionInstallments({
    required this.currentCount,
    required this.remainingCount,
    required this.totalCount,
    required this.currentAmount,
    this.originalTransactionAmount,
    this.totalFinalAmount,
    this.interestRate,
    required this.firstInstallmentDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentCount': currentCount,
      'remainingCount': remainingCount,
      'totalCount': totalCount,
      'currentAmount': currentAmount.toJson(),
      if (originalTransactionAmount != null)
        'originalTransactionAmount': originalTransactionAmount!.toJson(),
      if (totalFinalAmount != null)
        'totalFinalAmount': totalFinalAmount!.toJson(),
      if (interestRate != null) 'interestRate': interestRate,
      'firstInstallmentDate': firstInstallmentDate,
    };
  }
}

class Transaction {
  final String id;
  final TransactionType type;
  final String description;
  final Amount amount;
  final CurrencyType? billingCurrencyType;
  final BillingStatus? billingStatus;
  final String? transactionDate;
  final String? transactionTime;
  final String? processingDate;
  final Amount? originalAmount;
  final TransactionInstallments? installments;
  final String? city;
  final String? country;

  Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    this.billingCurrencyType,
    this.billingStatus,
    this.transactionDate,
    this.transactionTime,
    this.processingDate,
    this.originalAmount,
    this.installments,
    this.city,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'amount': amount.toJson(),
      if (billingCurrencyType != null)
        'billingCurrencyType': billingCurrencyType!.name,
      if (billingStatus != null) 'billingStatus': billingStatus!.name,
      if (transactionDate != null) 'transactionDate': transactionDate,
      if (transactionTime != null) 'transactionTime': transactionTime,
      if (processingDate != null) 'processingDate': processingDate,
      if (originalAmount != null) 'originalAmount': originalAmount!.toJson(),
      if (installments != null) 'installments': installments!.toJson(),
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    };
  }
}
