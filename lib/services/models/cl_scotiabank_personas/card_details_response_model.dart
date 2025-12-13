class ClScotiabankPersonasCardDetailsResponseModel {
  ClScotiabankPersonasCardDetailsResponseModel({
    required this.key,
    required this.nationalAmount,
    required this.nationalAmountAvailable,
    required this.internationalAmount,
    required this.internationalAmountAvailable,
  });

  final String? key;
  final String? nationalAmount;
  final String? nationalAmountAvailable;
  final String? internationalAmount;
  final String? internationalAmountAvailable;

  factory ClScotiabankPersonasCardDetailsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClScotiabankPersonasCardDetailsResponseModel(
      key: json["key"],
      nationalAmount: json["national_amount"],
      nationalAmountAvailable: json["national_amount_available"],
      internationalAmount: json["international_amount"],
      internationalAmountAvailable: json["international_amount_available"],
    );
  }
}
