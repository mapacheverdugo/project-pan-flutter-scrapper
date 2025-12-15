class TransactionAmountOptional {
  final int? amount;
  final String? currency;

  TransactionAmountOptional({this.amount, this.currency});

  Map<String, dynamic> toJson() {
    return {
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
    };
  }
}

class TransactionAmountRequired {
  final int amount;
  final String currency;

  TransactionAmountRequired({required this.amount, required this.currency});

  factory TransactionAmountRequired.fromJson(Map<String, dynamic> json) {
    return TransactionAmountRequired(
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'currency': currency};
  }
}
