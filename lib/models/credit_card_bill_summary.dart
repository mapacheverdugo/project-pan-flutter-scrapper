class CreditCardBillSummaryCardBalance {
  final int creditLimit;
  final int usedCredit;
  final int availableCredit;

  CreditCardBillSummaryCardBalance({
    required this.creditLimit,
    required this.usedCredit,
    required this.availableCredit,
  });

  Map<String, dynamic> toJson() {
    return {
      'creditLimit': creditLimit,
      'usedCredit': usedCredit,
      'availableCredit': availableCredit,
    };
  }
}

class CreditCardBillSummaryCurrentInterestRate {
  final double revolving;
  final double installmentPurchases;
  final double? cashAdvances;

  CreditCardBillSummaryCurrentInterestRate({
    required this.revolving,
    required this.installmentPurchases,
    this.cashAdvances,
  });

  Map<String, dynamic> toJson() {
    return {
      'revolving': revolving,
      'installmentPurchases': installmentPurchases,
      if (cashAdvances != null) 'cashAdvances': cashAdvances,
    };
  }
}

class CreditCardBillSummaryCae {
  final double revolving;
  final double installmentPurchases;
  final double cashAdvances;

  CreditCardBillSummaryCae({
    required this.revolving,
    required this.installmentPurchases,
    required this.cashAdvances,
  });

  Map<String, dynamic> toJson() {
    return {
      'revolving': revolving,
      'installmentPurchases': installmentPurchases,
      'cashAdvances': cashAdvances,
    };
  }
}

class CreditCardBillSummaryPreviousBillSummary {
  final String fromDate;
  final String toDate;
  final int? initialDueAmount;
  final int? totalDueAmount;
  final int billedAmount;
  final int paidAmount;
  final int? finalDueAmount;
  final int? pendingDueAmount;

  CreditCardBillSummaryPreviousBillSummary({
    required this.fromDate,
    required this.toDate,
    this.initialDueAmount,
    this.totalDueAmount,
    required this.billedAmount,
    required this.paidAmount,
    this.finalDueAmount,
    this.pendingDueAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromDate': fromDate,
      'toDate': toDate,
      if (initialDueAmount != null) 'initialDueAmount': initialDueAmount,
      if (totalDueAmount != null) 'totalDueAmount': totalDueAmount,
      'billedAmount': billedAmount,
      'paidAmount': paidAmount,
      if (finalDueAmount != null) 'finalDueAmount': finalDueAmount,
      if (pendingDueAmount != null) 'pendingDueAmount': pendingDueAmount,
    };
  }
}

class CreditCardBillSummaryNext4MonthsItem {
  final int number;
  final int? value;

  CreditCardBillSummaryNext4MonthsItem({
    required this.number,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      if (value != null) 'value': value,
    };
  }
}

class CreditCardBillSummaryLatePaymentCostCollectionCharge {
  final String debtAmountUF;
  final String percentage;

  CreditCardBillSummaryLatePaymentCostCollectionCharge({
    required this.debtAmountUF,
    required this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'debtAmountUF': debtAmountUF,
      'percentage': percentage,
    };
  }
}

class CreditCardBillSummaryLatePaymentCost {
  final String defaultInterestRate;
  final List<CreditCardBillSummaryLatePaymentCostCollectionCharge>
      collectionCharge;
  final List<String> notes;

  CreditCardBillSummaryLatePaymentCost({
    required this.defaultInterestRate,
    required this.collectionCharge,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'defaultInterestRate': defaultInterestRate,
      'collectionCharge':
          collectionCharge.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }
}

class CreditCardBillSummary {
  final String currentBillDate;
  final CreditCardBillSummaryCardBalance cardBalance;
  final CreditCardBillSummaryCardBalance? cashAdvanceBalance;
  final CreditCardBillSummaryCurrentInterestRate? currentInterestRate;
  final CreditCardBillSummaryCae? cae;
  final double? prepaidCae;
  final String openingBillingDate;
  final String closingBillingDate;
  final String paymentDueDate;
  final CreditCardBillSummaryPreviousBillSummary? previousBillSummary;
  final int totalBilledAmount;
  final int? minimumPaymentAmount;
  final int? prepaidCost;
  final List<CreditCardBillSummaryNext4MonthsItem> next4Months;
  final int? installmentBalance;
  final String? nextBillOpeningBillingDate;
  final String? nextBillClosingBillingDate;
  final CreditCardBillSummaryLatePaymentCost? latePaymentCost;

  CreditCardBillSummary({
    required this.currentBillDate,
    required this.cardBalance,
    this.cashAdvanceBalance,
    this.currentInterestRate,
    this.cae,
    this.prepaidCae,
    required this.openingBillingDate,
    required this.closingBillingDate,
    required this.paymentDueDate,
    this.previousBillSummary,
    required this.totalBilledAmount,
    this.minimumPaymentAmount,
    this.prepaidCost,
    required this.next4Months,
    this.installmentBalance,
    this.nextBillOpeningBillingDate,
    this.nextBillClosingBillingDate,
    this.latePaymentCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentBillDate': currentBillDate,
      'cardBalance': cardBalance.toJson(),
      if (cashAdvanceBalance != null)
        'cashAdvanceBalance': cashAdvanceBalance!.toJson(),
      if (currentInterestRate != null)
        'currentInterestRate': currentInterestRate!.toJson(),
      if (cae != null) 'cae': cae!.toJson(),
      if (prepaidCae != null) 'prepaidCae': prepaidCae,
      'openingBillingDate': openingBillingDate,
      'closingBillingDate': closingBillingDate,
      'paymentDueDate': paymentDueDate,
      if (previousBillSummary != null)
        'previousBillSummary': previousBillSummary!.toJson(),
      'totalBilledAmount': totalBilledAmount,
      if (minimumPaymentAmount != null)
        'minimumPaymentAmount': minimumPaymentAmount,
      if (prepaidCost != null) 'prepaidCost': prepaidCost,
      'next4Months': next4Months.map((e) => e.toJson()).toList(),
      if (installmentBalance != null) 'installmentBalance': installmentBalance,
      if (nextBillOpeningBillingDate != null)
        'nextBillOpeningBillingDate': nextBillOpeningBillingDate,
      if (nextBillClosingBillingDate != null)
        'nextBillClosingBillingDate': nextBillClosingBillingDate,
      if (latePaymentCost != null) 'latePaymentCost': latePaymentCost!.toJson(),
    };
  }
}

