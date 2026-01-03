class AvailableAmount {
  final String currency;
  final int amount;

  AvailableAmount({required this.currency, required this.amount});

  factory AvailableAmount.fromJson(Map<String, dynamic> json) {
    return AvailableAmount(
      currency: json['currency'] as String,
      amount: (json['amount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'currency': currency, 'amount': amount};
  }
}







