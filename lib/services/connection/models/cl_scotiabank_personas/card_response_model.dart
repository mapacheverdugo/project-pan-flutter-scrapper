class ClScotiabankPersonasCardResponseModel {
  ClScotiabankPersonasCardResponseModel({
    required this.key,
    required this.type,
    required this.code,
    required this.description,
    required this.id,
    required this.iconName,
    required this.isCardDisabledByFraudLaw,
  });

  final String key;
  final String? type;
  final String? code;
  final String description;
  final String? id;
  final dynamic iconName;
  final bool? isCardDisabledByFraudLaw;

  factory ClScotiabankPersonasCardResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClScotiabankPersonasCardResponseModel(
      key: json["key"],
      type: json["type"],
      code: json["code"],
      description: json["description"],
      id: json["id"],
      iconName: json["icon_name"],
      isCardDisabledByFraudLaw: json["is_card_disabled_by_fraud_law"],
    );
  }
}
