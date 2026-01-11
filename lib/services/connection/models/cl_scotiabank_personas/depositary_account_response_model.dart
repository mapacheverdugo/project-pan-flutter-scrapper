class ClScotiabankPersonasDepositaryAccountResponseModel {
  ClScotiabankPersonasDepositaryAccountResponseModel({
    required this.key,
    required this.displayId,
    required this.type,
    required this.description,
    required this.currencyCode,
    required this.totalBalance,
    required this.amountAvailable,
    required this.iconName,
  });

  final String key;
  final String displayId;
  final String type;
  final String description;
  final String currencyCode;
  final String totalBalance;
  final String amountAvailable;
  final String? iconName;

  factory ClScotiabankPersonasDepositaryAccountResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClScotiabankPersonasDepositaryAccountResponseModel(
      key: json["key"],
      displayId: json["display_id"],
      type: json["type"],
      description: json["description"],
      currencyCode: json["currency_code"],
      totalBalance: json["total_balance"],
      amountAvailable: json["amount_available"],
      iconName: json["icon_name"],
    );
  }
}
