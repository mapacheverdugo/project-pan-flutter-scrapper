class ClBancoChilePersonasDepositaryBalancesResponseModel {
  final String? id;
  final String? numero;
  final String? mascara;
  final String? codigoMoneda;
  final String? saldo;
  final String? saldoDisponible;

  ClBancoChilePersonasDepositaryBalancesResponseModel({
    this.id,
    this.numero,
    this.mascara,
    this.codigoMoneda,
    this.saldo,
    this.saldoDisponible,
  });

  factory ClBancoChilePersonasDepositaryBalancesResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasDepositaryBalancesResponseModel(
      id: json['id'] as String?,
      numero: json['numero'] as String?,
      mascara: json['mascara'] as String?,
      codigoMoneda: json['codigoMoneda'] as String?,
      saldo: json['saldo'] as String?,
      saldoDisponible: json['saldoDisponible'] as String?,
    );
  }
}

