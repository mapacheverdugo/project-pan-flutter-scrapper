import 'package:json_annotation/json_annotation.dart';

part 'extracted_credit_card_bill_summary.g.dart';

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummaryCardBalance {
  final int? creditLimit;
  final int? usedCredit;
  final int? availableCredit;

  ExtractedCreditCardBillSummaryCardBalance({
    this.creditLimit,
    this.usedCredit,
    this.availableCredit,
  });

  factory ExtractedCreditCardBillSummaryCardBalance.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedCreditCardBillSummaryCardBalanceFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedCreditCardBillSummaryCardBalanceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummaryCurrentInterestRate {
  final double? revolving;
  final double? installmentPurchases;
  final double? cashAdvances;

  ExtractedCreditCardBillSummaryCurrentInterestRate({
    this.revolving,
    this.installmentPurchases,
    this.cashAdvances,
  });

  factory ExtractedCreditCardBillSummaryCurrentInterestRate.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedCreditCardBillSummaryCurrentInterestRateFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedCreditCardBillSummaryCurrentInterestRateToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummaryCae {
  final double? revolving;
  final double? installmentPurchases;
  final double? cashAdvances;

  ExtractedCreditCardBillSummaryCae({
    this.revolving,
    this.installmentPurchases,
    this.cashAdvances,
  });

  factory ExtractedCreditCardBillSummaryCae.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedCreditCardBillSummaryCaeFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedCreditCardBillSummaryCaeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummaryPreviousBillSummary {
  final String? fromDate;
  final String? toDate;
  final int? initialDueAmount;
  final int? totalDueAmount;
  final int? billedAmount;
  final int? paidAmount;
  final int? finalDueAmount;
  final int? pendingDueAmount;

  ExtractedCreditCardBillSummaryPreviousBillSummary({
    this.fromDate,
    this.toDate,
    this.initialDueAmount,
    this.totalDueAmount,
    this.billedAmount,
    this.paidAmount,
    this.finalDueAmount,
    this.pendingDueAmount,
  });

  factory ExtractedCreditCardBillSummaryPreviousBillSummary.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedCreditCardBillSummaryPreviousBillSummaryFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedCreditCardBillSummaryPreviousBillSummaryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummaryNext4MonthsItem {
  final int? number;
  final int? value;

  ExtractedCreditCardBillSummaryNext4MonthsItem({this.number, this.value});

  factory ExtractedCreditCardBillSummaryNext4MonthsItem.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedCreditCardBillSummaryNext4MonthsItemFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedCreditCardBillSummaryNext4MonthsItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge {
  final String? debtAmountUF;
  final String? percentage;

  ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge({
    this.debtAmountUF,
    this.percentage,
  });

  factory ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedCreditCardBillSummaryLatePaymentCostCollectionChargeFromJson(
    json,
  );

  Map<String, dynamic> toJson() =>
      _$ExtractedCreditCardBillSummaryLatePaymentCostCollectionChargeToJson(
        this,
      );
}

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummaryLatePaymentCost {
  final String? defaultInterestRate;
  final List<ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge>?
  collectionCharge;
  final List<String>? notes;

  ExtractedCreditCardBillSummaryLatePaymentCost({
    this.defaultInterestRate,
    this.collectionCharge,
    this.notes,
  });

  factory ExtractedCreditCardBillSummaryLatePaymentCost.fromJson(
    Map<String, dynamic> json,
  ) => _$ExtractedCreditCardBillSummaryLatePaymentCostFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ExtractedCreditCardBillSummaryLatePaymentCostToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExtractedCreditCardBillSummary {
  final String? currentBillDate;
  final ExtractedCreditCardBillSummaryCardBalance? cardBalance;
  final ExtractedCreditCardBillSummaryCardBalance? cashAdvanceBalance;
  final ExtractedCreditCardBillSummaryCurrentInterestRate? currentInterestRate;
  final ExtractedCreditCardBillSummaryCae? cae;
  final double? prepaidCae;
  final String? openingBillingDate;
  final String? closingBillingDate;
  final String? paymentDueDate;
  final ExtractedCreditCardBillSummaryPreviousBillSummary? previousBillSummary;
  final int? totalBilledAmount;
  final int? minimumPaymentAmount;
  final int? prepaidCost;
  final List<ExtractedCreditCardBillSummaryNext4MonthsItem>? next4Months;
  final int? installmentBalance;
  final String? nextBillOpeningBillingDate;
  final String? nextBillClosingBillingDate;
  final ExtractedCreditCardBillSummaryLatePaymentCost? latePaymentCost;
  final Map<String, dynamic>? metadata;

  ExtractedCreditCardBillSummary({
    this.currentBillDate,
    this.cardBalance,
    this.cashAdvanceBalance,
    this.currentInterestRate,
    this.cae,
    this.prepaidCae,
    this.openingBillingDate,
    this.closingBillingDate,
    this.paymentDueDate,
    this.previousBillSummary,
    this.totalBilledAmount,
    this.minimumPaymentAmount,
    this.prepaidCost,
    this.next4Months,
    this.installmentBalance,
    this.nextBillOpeningBillingDate,
    this.nextBillClosingBillingDate,
    this.latePaymentCost,
    this.metadata,
  });

  factory ExtractedCreditCardBillSummary.fromJson(Map<String, dynamic> json) =>
      _$ExtractedCreditCardBillSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractedCreditCardBillSummaryToJson(this);
}
