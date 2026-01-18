// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extracted_credit_card_bill_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractedCreditCardBillSummaryCardBalance
_$ExtractedCreditCardBillSummaryCardBalanceFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummaryCardBalance(
  creditLimit: (json['creditLimit'] as num?)?.toInt(),
  usedCredit: (json['usedCredit'] as num?)?.toInt(),
  availableCredit: (json['availableCredit'] as num?)?.toInt(),
);

Map<String, dynamic> _$ExtractedCreditCardBillSummaryCardBalanceToJson(
  ExtractedCreditCardBillSummaryCardBalance instance,
) => <String, dynamic>{
  'creditLimit': instance.creditLimit,
  'usedCredit': instance.usedCredit,
  'availableCredit': instance.availableCredit,
};

ExtractedCreditCardBillSummaryCurrentInterestRate
_$ExtractedCreditCardBillSummaryCurrentInterestRateFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummaryCurrentInterestRate(
  revolving: (json['revolving'] as num?)?.toDouble(),
  installmentPurchases: (json['installmentPurchases'] as num?)?.toDouble(),
  cashAdvances: (json['cashAdvances'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExtractedCreditCardBillSummaryCurrentInterestRateToJson(
  ExtractedCreditCardBillSummaryCurrentInterestRate instance,
) => <String, dynamic>{
  'revolving': instance.revolving,
  'installmentPurchases': instance.installmentPurchases,
  'cashAdvances': instance.cashAdvances,
};

ExtractedCreditCardBillSummaryCae _$ExtractedCreditCardBillSummaryCaeFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummaryCae(
  revolving: (json['revolving'] as num?)?.toDouble(),
  installmentPurchases: (json['installmentPurchases'] as num?)?.toDouble(),
  cashAdvances: (json['cashAdvances'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExtractedCreditCardBillSummaryCaeToJson(
  ExtractedCreditCardBillSummaryCae instance,
) => <String, dynamic>{
  'revolving': instance.revolving,
  'installmentPurchases': instance.installmentPurchases,
  'cashAdvances': instance.cashAdvances,
};

ExtractedCreditCardBillSummaryPreviousBillSummary
_$ExtractedCreditCardBillSummaryPreviousBillSummaryFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummaryPreviousBillSummary(
  fromDate: json['fromDate'] as String?,
  toDate: json['toDate'] as String?,
  initialDueAmount: (json['initialDueAmount'] as num?)?.toInt(),
  totalDueAmount: (json['totalDueAmount'] as num?)?.toInt(),
  billedAmount: (json['billedAmount'] as num?)?.toInt(),
  paidAmount: (json['paidAmount'] as num?)?.toInt(),
  finalDueAmount: (json['finalDueAmount'] as num?)?.toInt(),
  pendingDueAmount: (json['pendingDueAmount'] as num?)?.toInt(),
);

Map<String, dynamic> _$ExtractedCreditCardBillSummaryPreviousBillSummaryToJson(
  ExtractedCreditCardBillSummaryPreviousBillSummary instance,
) => <String, dynamic>{
  'fromDate': instance.fromDate,
  'toDate': instance.toDate,
  'initialDueAmount': instance.initialDueAmount,
  'totalDueAmount': instance.totalDueAmount,
  'billedAmount': instance.billedAmount,
  'paidAmount': instance.paidAmount,
  'finalDueAmount': instance.finalDueAmount,
  'pendingDueAmount': instance.pendingDueAmount,
};

ExtractedCreditCardBillSummaryNext4MonthsItem
_$ExtractedCreditCardBillSummaryNext4MonthsItemFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummaryNext4MonthsItem(
  number: (json['number'] as num?)?.toInt(),
  value: (json['value'] as num?)?.toInt(),
);

Map<String, dynamic> _$ExtractedCreditCardBillSummaryNext4MonthsItemToJson(
  ExtractedCreditCardBillSummaryNext4MonthsItem instance,
) => <String, dynamic>{'number': instance.number, 'value': instance.value};

ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge
_$ExtractedCreditCardBillSummaryLatePaymentCostCollectionChargeFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge(
  debtAmountUF: json['debtAmountUF'] as String?,
  percentage: json['percentage'] as String?,
);

Map<String, dynamic>
_$ExtractedCreditCardBillSummaryLatePaymentCostCollectionChargeToJson(
  ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge instance,
) => <String, dynamic>{
  'debtAmountUF': instance.debtAmountUF,
  'percentage': instance.percentage,
};

ExtractedCreditCardBillSummaryLatePaymentCost
_$ExtractedCreditCardBillSummaryLatePaymentCostFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummaryLatePaymentCost(
  defaultInterestRate: json['defaultInterestRate'] as String?,
  collectionCharge: (json['collectionCharge'] as List<dynamic>?)
      ?.map(
        (e) =>
            ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge.fromJson(
              e as Map<String, dynamic>,
            ),
      )
      .toList(),
  notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ExtractedCreditCardBillSummaryLatePaymentCostToJson(
  ExtractedCreditCardBillSummaryLatePaymentCost instance,
) => <String, dynamic>{
  'defaultInterestRate': instance.defaultInterestRate,
  'collectionCharge': instance.collectionCharge
      ?.map((e) => e.toJson())
      .toList(),
  'notes': instance.notes,
};

ExtractedCreditCardBillSummary _$ExtractedCreditCardBillSummaryFromJson(
  Map<String, dynamic> json,
) => ExtractedCreditCardBillSummary(
  currentBillDate: json['currentBillDate'] as String?,
  cardBalance: json['cardBalance'] == null
      ? null
      : ExtractedCreditCardBillSummaryCardBalance.fromJson(
          json['cardBalance'] as Map<String, dynamic>,
        ),
  cashAdvanceBalance: json['cashAdvanceBalance'] == null
      ? null
      : ExtractedCreditCardBillSummaryCardBalance.fromJson(
          json['cashAdvanceBalance'] as Map<String, dynamic>,
        ),
  currentInterestRate: json['currentInterestRate'] == null
      ? null
      : ExtractedCreditCardBillSummaryCurrentInterestRate.fromJson(
          json['currentInterestRate'] as Map<String, dynamic>,
        ),
  cae: json['cae'] == null
      ? null
      : ExtractedCreditCardBillSummaryCae.fromJson(
          json['cae'] as Map<String, dynamic>,
        ),
  prepaidCae: (json['prepaidCae'] as num?)?.toDouble(),
  openingBillingDate: json['openingBillingDate'] as String?,
  closingBillingDate: json['closingBillingDate'] as String?,
  paymentDueDate: json['paymentDueDate'] as String?,
  previousBillSummary: json['previousBillSummary'] == null
      ? null
      : ExtractedCreditCardBillSummaryPreviousBillSummary.fromJson(
          json['previousBillSummary'] as Map<String, dynamic>,
        ),
  totalBilledAmount: (json['totalBilledAmount'] as num?)?.toInt(),
  minimumPaymentAmount: (json['minimumPaymentAmount'] as num?)?.toInt(),
  prepaidCost: (json['prepaidCost'] as num?)?.toInt(),
  next4Months: (json['next4Months'] as List<dynamic>?)
      ?.map(
        (e) => ExtractedCreditCardBillSummaryNext4MonthsItem.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  installmentBalance: (json['installmentBalance'] as num?)?.toInt(),
  nextBillOpeningBillingDate: json['nextBillOpeningBillingDate'] as String?,
  nextBillClosingBillingDate: json['nextBillClosingBillingDate'] as String?,
  latePaymentCost: json['latePaymentCost'] == null
      ? null
      : ExtractedCreditCardBillSummaryLatePaymentCost.fromJson(
          json['latePaymentCost'] as Map<String, dynamic>,
        ),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ExtractedCreditCardBillSummaryToJson(
  ExtractedCreditCardBillSummary instance,
) => <String, dynamic>{
  'currentBillDate': instance.currentBillDate,
  'cardBalance': instance.cardBalance?.toJson(),
  'cashAdvanceBalance': instance.cashAdvanceBalance?.toJson(),
  'currentInterestRate': instance.currentInterestRate?.toJson(),
  'cae': instance.cae?.toJson(),
  'prepaidCae': instance.prepaidCae,
  'openingBillingDate': instance.openingBillingDate,
  'closingBillingDate': instance.closingBillingDate,
  'paymentDueDate': instance.paymentDueDate,
  'previousBillSummary': instance.previousBillSummary?.toJson(),
  'totalBilledAmount': instance.totalBilledAmount,
  'minimumPaymentAmount': instance.minimumPaymentAmount,
  'prepaidCost': instance.prepaidCost,
  'next4Months': instance.next4Months?.map((e) => e.toJson()).toList(),
  'installmentBalance': instance.installmentBalance,
  'nextBillOpeningBillingDate': instance.nextBillOpeningBillingDate,
  'nextBillClosingBillingDate': instance.nextBillClosingBillingDate,
  'latePaymentCost': instance.latePaymentCost?.toJson(),
  'metadata': instance.metadata,
};
