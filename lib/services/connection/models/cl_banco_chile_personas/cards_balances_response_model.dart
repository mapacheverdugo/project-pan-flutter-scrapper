class ClBancoChilePersonasCardsBalancesResponseModel {
  ClBancoChilePersonasCardsBalancesResponseModel({
    required this.titular,
    required this.marca,
    required this.tipo,
    required this.idProducto,
    required this.numero,
    required this.cupos,
  });

  final bool? titular;
  final String? marca;
  final String? tipo;
  final String idProducto;
  final String? numero;
  final List<ClBancoChilePersonasCardsBalancesCupo> cupos;

  factory ClBancoChilePersonasCardsBalancesResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasCardsBalancesResponseModel(
      titular: json["titular"],
      marca: json["marca"],
      tipo: json["tipo"],
      idProducto: json["idProducto"],
      numero: json["numero"],
      cupos: json["cupos"] == null
          ? []
          : List<ClBancoChilePersonasCardsBalancesCupo>.from(
              json["cupos"]!.map(
                (x) => ClBancoChilePersonasCardsBalancesCupo.fromJson(x),
              ),
            ),
    );
  }
}

class ClBancoChilePersonasCardsBalancesCupo {
  ClBancoChilePersonasCardsBalancesCupo({
    required this.moneda,
    required this.disponible,
    required this.cupo,
  });

  final String moneda;
  final double disponible;
  final num cupo;

  factory ClBancoChilePersonasCardsBalancesCupo.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasCardsBalancesCupo(
      moneda: json["moneda"],
      disponible: json["disponible"],
      cupo: json["cupo"],
    );
  }
}
