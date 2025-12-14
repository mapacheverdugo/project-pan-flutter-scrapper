class ClBancoChilePersonasCardsBalancesResponseModel {
  final String? id;
  final String? numero;
  final String? mascara;
  final String? descripcionLogo;
  final String? tarjetaHabiente;
  final String? codigoMoneda;
  final String? cupoTotal;
  final String? cupoDisponible;
  final String? cupoUtilizado;

  ClBancoChilePersonasCardsBalancesResponseModel({
    this.id,
    this.numero,
    this.mascara,
    this.descripcionLogo,
    this.tarjetaHabiente,
    this.codigoMoneda,
    this.cupoTotal,
    this.cupoDisponible,
    this.cupoUtilizado,
  });

  factory ClBancoChilePersonasCardsBalancesResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasCardsBalancesResponseModel(
      id: json['id'] as String?,
      numero: json['numero'] as String?,
      mascara: json['mascara'] as String?,
      descripcionLogo: json['descripcionLogo'] as String?,
      tarjetaHabiente: json['tarjetaHabiente'] as String?,
      codigoMoneda: json['codigoMoneda'] as String?,
      cupoTotal: json['cupoTotal'] as String?,
      cupoDisponible: json['cupoDisponible'] as String?,
      cupoUtilizado: json['cupoUtilizado'] as String?,
    );
  }
}

