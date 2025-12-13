class CreditBalance {
  final double creditLimitAmount;
  final String currency;
  final double availableAmount;
  final double usedAmount;

  CreditBalance({
    required this.creditLimitAmount,
    required this.currency,
    required this.availableAmount,
    required this.usedAmount,
  });

  factory CreditBalance.fromJson(Map<String, dynamic> json) {
    return CreditBalance(
      creditLimitAmount: (json['creditLimitAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      availableAmount: (json['availableAmount'] as num).toDouble(),
      usedAmount: (json['usedAmount'] as num).toDouble(),
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



