class CreditBalance {
  final int creditLimitAmount;
  final String currency;
  final int availableAmount;
  final int usedAmount;

  CreditBalance({
    required this.creditLimitAmount,
    required this.currency,
    required this.availableAmount,
    required this.usedAmount,
  });

  factory CreditBalance.fromJson(Map<String, dynamic> json) {
    return CreditBalance(
      creditLimitAmount: (json['creditLimitAmount'] as num).toInt(),
      currency: json['currency'] as String,
      availableAmount: (json['availableAmount'] as num).toInt(),
      usedAmount: (json['usedAmount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creditLimitAmount': creditLimitAmount,
      'currency': currency,
      'availableAmount': availableAmount,
      'usedAmount': usedAmount,
    };
  }
}

