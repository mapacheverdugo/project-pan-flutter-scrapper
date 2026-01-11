import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/converters/amount_json_converter.dart';
import 'package:pan_scrapper/entities/amount.dart';

part 'extracted_transaction_installments.g.dart';

@JsonSerializable(explicitToJson: true, converters: [AmountJsonConverter()])
class ExtractedTransactionInstallments {
  final int currentCount;
  final int remainingCount;
  final int totalCount;
  final Amount currentAmount;
  final Amount? originalTransactionAmount;
  final Amount? totalFinalAmount;
  final double? interestRate;
  final String firstInstallmentDate;

  ExtractedTransactionInstallments({
    required this.currentCount,
    required this.remainingCount,
    required this.totalCount,
    required this.currentAmount,
    this.originalTransactionAmount,
    this.totalFinalAmount,
    this.interestRate,
    required this.firstInstallmentDate,
  });

  factory ExtractedTransactionInstallments.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedTransactionInstallmentsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedTransactionInstallmentsToJson(this);
}
