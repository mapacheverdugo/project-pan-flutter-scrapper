class ClSantanderPersonasDepositaryAccountTransactionResponseModel {
  ClSantanderPersonasDepositaryAccountTransactionResponseModel({
    required this.additionalInfo,
    required this.repositioningExit,
    required this.movements,
  });

  final List<ClSantanderPersonasAdditionalInfo> additionalInfo;
  final ClSantanderPersonasRepositioningExit? repositioningExit;
  final List<ClSantanderPersonasMovement> movements;

  factory ClSantanderPersonasDepositaryAccountTransactionResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasDepositaryAccountTransactionResponseModel(
      additionalInfo: json["additionalInfo"] == null
          ? []
          : List<ClSantanderPersonasAdditionalInfo>.from(
              json["additionalInfo"]!.map(
                (x) => ClSantanderPersonasAdditionalInfo.fromJson(x),
              ),
            ),
      repositioningExit: json["repositioningExit"] == null
          ? null
          : ClSantanderPersonasRepositioningExit.fromJson(
              json["repositioningExit"],
            ),
      movements: json["movements"] == null
          ? []
          : List<ClSantanderPersonasMovement>.from(
              json["movements"]!.map(
                (x) => ClSantanderPersonasMovement.fromJson(x),
              ),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "additionalInfo": additionalInfo.map((x) => x.toJson()).toList(),
    "repositioningExit": repositioningExit?.toJson(),
    "movements": movements.map((x) => x.toJson()).toList(),
  };
}

class ClSantanderPersonasAdditionalInfo {
  ClSantanderPersonasAdditionalInfo({required this.key, required this.value});

  final String? key;
  final String? value;

  factory ClSantanderPersonasAdditionalInfo.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasAdditionalInfo(
      key: json["key"],
      value: json["value"],
    );
  }

  Map<String, dynamic> toJson() => {"key": key, "value": value};
}

class ClSantanderPersonasMovement {
  ClSantanderPersonasMovement({
    required this.accountingDate,
    required this.transactionDate,
    required this.operationTime,
    required this.newBalance,
    required this.codeOperationMovement,
    required this.movementAmount,
    required this.observation,
    required this.expandedCode,
    required this.movementNumber,
    required this.chargePaymentFlag,
  });

  final String? accountingDate;
  final String? transactionDate;
  final String? operationTime;
  final String? newBalance;
  final String? codeOperationMovement;
  final String? movementAmount;
  final String? observation;
  final String? expandedCode;
  final String? movementNumber;
  final String? chargePaymentFlag;

  factory ClSantanderPersonasMovement.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasMovement(
      accountingDate: json["accountingDate"],
      transactionDate: json["transactionDate"],
      operationTime: json["operationTime"],
      newBalance: json["newBalance"],
      codeOperationMovement: json["codeOperationMovement"],
      movementAmount: json["movementAmount"],
      observation: json["observation"],
      expandedCode: json["expandedCode"],
      movementNumber: json["movementNumber"],
      chargePaymentFlag: json["chargePaymentFlag"],
    );
  }

  Map<String, dynamic> toJson() => {
    "accountingDate": accountingDate,
    "transactionDate": transactionDate,
    "operationTime": operationTime,
    "newBalance": newBalance,
    "codeOperationMovement": codeOperationMovement,
    "movementAmount": movementAmount,
    "observation": observation,
    "expandedCode": expandedCode,
    "movementNumber": movementNumber,
    "chargePaymentFlag": chargePaymentFlag,
  };
}

class ClSantanderPersonasRepositioningExit {
  ClSantanderPersonasRepositioningExit({
    required this.codeCtaCli,
    required this.divisa,
    required this.dateFrom,
    required this.dateTo,
    required this.initialMove,
    required this.finalMove,
    required this.recordType,
    required this.timeStamp,
    required this.recordRecover,
    required this.indChargeCommision,
  });

  final String? codeCtaCli;
  final String? divisa;
  final String? dateFrom;
  final String? dateTo;
  final String? initialMove;
  final String? finalMove;
  final String? recordType;
  final String? timeStamp;
  final String? recordRecover;
  final String? indChargeCommision;

  factory ClSantanderPersonasRepositioningExit.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasRepositioningExit(
      codeCtaCli: json["codeCtaCli"],
      divisa: json["divisa"],
      dateFrom: json["dateFrom"],
      dateTo: json["dateTo"],
      initialMove: json["initialMove"],
      finalMove: json["finalMove"],
      recordType: json["recordType"],
      timeStamp: json["timeStamp"],
      recordRecover: json["recordRecover"],
      indChargeCommision: json["indChargeCommision"],
    );
  }

  Map<String, dynamic> toJson() => {
    "codeCtaCli": codeCtaCli,
    "divisa": divisa,
    "dateFrom": dateFrom,
    "dateTo": dateTo,
    "initialMove": initialMove,
    "finalMove": finalMove,
    "recordType": recordType,
    "timeStamp": timeStamp,
    "recordRecover": recordRecover,
    "indChargeCommision": indChargeCommision,
  };
}
