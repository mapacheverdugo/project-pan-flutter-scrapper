class ClSantanderPersonasCardDevicesManagementResponse {
  ClSantanderPersonasCardDevicesManagementResponse({
    required this.responseCode,
    required this.responseDescription,
    required this.output,
  });

  final String? responseCode;
  final String? responseDescription;
  final List<ClSantanderPersonasCardDevicesManagementOutput> output;

  factory ClSantanderPersonasCardDevicesManagementResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCardDevicesManagementResponse(
      responseCode: json["responseCode"],
      responseDescription: json["responseDescription"],
      output: json["output"] == null
          ? []
          : List<ClSantanderPersonasCardDevicesManagementOutput>.from(
              json["output"]!.map(
                (x) =>
                    ClSantanderPersonasCardDevicesManagementOutput.fromJson(x),
              ),
            ),
    );
  }
}

class ClSantanderPersonasCardDevicesManagementOutput {
  ClSantanderPersonasCardDevicesManagementOutput({
    required this.qualityParticipate,
    required this.debitOrCreditCard,
    required this.product,
    required this.subProductCode,
    required this.brandCode,
    required this.cardType,
    required this.entityCode,
    required this.emissionCenter,
    required this.accountNumber,
    required this.cardNumber,
    required this.beneficiaryNumber,
    required this.plasticNumber,
    required this.lockCode,
    required this.lockComment,
    required this.isCompany,
    required this.limitCenterPesos,
    required this.limitContractUsd,
    required this.imagenCode,
    required this.isOfferable,
    required this.productComment,
    required this.ownerName,
    required this.beneficiaryName,
    required this.cardStatus,
    required this.cardExpirationDate,
    required this.cardStatusComment,
    required this.personNumber,
    required this.typePaymentAvailable,
    required this.typePaymentAvailableComment,
    required this.cardDomainAccount1,
    required this.cardDomainAccount2,
    required this.externalData1,
    required this.externalData2,
  });

  final String? qualityParticipate;
  final String? debitOrCreditCard;
  final String? product;
  final String? subProductCode;
  final String? brandCode;
  final String? cardType;
  final String? entityCode;
  final String? emissionCenter;
  final String? accountNumber;
  final String? cardNumber;
  final String? beneficiaryNumber;
  final String? plasticNumber;
  final String? lockCode;
  final String? lockComment;
  final String? isCompany;
  final String? limitCenterPesos;
  final String? limitContractUsd;
  final String? imagenCode;
  final String? isOfferable;
  final String? productComment;
  final String? ownerName;
  final String? beneficiaryName;
  final String? cardStatus;
  final String? cardExpirationDate;
  final String? cardStatusComment;
  final String? personNumber;
  final String? typePaymentAvailable;
  final String? typePaymentAvailableComment;
  final String? cardDomainAccount1;
  final String? cardDomainAccount2;
  final String? externalData1;
  final String? externalData2;

  factory ClSantanderPersonasCardDevicesManagementOutput.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCardDevicesManagementOutput(
      qualityParticipate: json["qualityParticipate"],
      debitOrCreditCard: json["debitOrCreditCard"],
      product: json["product"],
      subProductCode: json["subProductCode"],
      brandCode: json["brandCode"],
      cardType: json["cardType"],
      entityCode: json["entityCode"],
      emissionCenter: json["emissionCenter"],
      accountNumber: json["accountNumber"],
      cardNumber: json["cardNumber"],
      beneficiaryNumber: json["beneficiaryNumber"],
      plasticNumber: json["plasticNumber"],
      lockCode: json["lockCode"],
      lockComment: json["lockComment"],
      isCompany: json["isCompany"],
      limitCenterPesos: json["limitCenterPesos"],
      limitContractUsd: json["limitContractUSD"],
      imagenCode: json["imagenCode"],
      isOfferable: json["isOfferable"],
      productComment: json["productComment"],
      ownerName: json["ownerName"],
      beneficiaryName: json["beneficiaryName"],
      cardStatus: json["cardStatus"],
      cardExpirationDate: json["cardExpirationDate"],
      cardStatusComment: json["cardStatusComment"],
      personNumber: json["personNumber"],
      typePaymentAvailable: json["typePaymentAvailable"],
      typePaymentAvailableComment: json["typePaymentAvailableComment"],
      cardDomainAccount1: json["cardDomainAccount1"],
      cardDomainAccount2: json["cardDomainAccount2"],
      externalData1: json["externalData1"],
      externalData2: json["externalData2"],
    );
  }
}
