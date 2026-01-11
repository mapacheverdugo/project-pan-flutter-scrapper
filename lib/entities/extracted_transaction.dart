import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/converters/amount_json_converter.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/billing_status.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extracted_transaction_installments.dart';

part 'extracted_transaction.g.dart';

@JsonSerializable(explicitToJson: true, converters: [AmountJsonConverter()])
class ExtractedTransaction {
  final String description;
  final Amount amount;
  final String? transactionDate;
  final String? transactionTime;
  final String? processingDate;
  final Amount? originalAmount;
  final String? city;
  final String? country;
  final CurrencyType? billingCurrencyType;
  final BillingStatus? billingStatus;
  final ExtractedTransactionInstallments? installments;

  ExtractedTransaction({
    required this.description,
    required this.amount,
    required this.transactionDate,
    required this.transactionTime,
    required this.processingDate,
    required this.originalAmount,
    required this.city,
    required this.country,
    this.billingCurrencyType,
    this.billingStatus,
    this.installments,
  });

  factory ExtractedTransaction.fromJson(Map<String, dynamic> json) =>
      _$ExtractedTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedTransactionToJson(this);
}
