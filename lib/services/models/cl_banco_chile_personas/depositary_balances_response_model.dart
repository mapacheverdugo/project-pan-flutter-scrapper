class ClBancoChilePersonasDepositaryBalancesResponseModel {
  ClBancoChilePersonasDepositaryBalancesResponseModel({
    required this.codProducto,
    required this.tipo,
    required this.numero,
    required this.disponible,
    required this.cupo,
    required this.ctaCte,
    required this.moneda,
    required this.descripcion,
    required this.url,
    required this.lineas,
  });

  final String? codProducto;
  final String? tipo;
  final String numero;
  final int? disponible;
  final int? cupo;
  final bool? ctaCte;
  final String moneda;
  final String? descripcion;
  final dynamic url;
  final dynamic lineas;

  factory ClBancoChilePersonasDepositaryBalancesResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasDepositaryBalancesResponseModel(
      codProducto: json["codProducto"],
      tipo: json["tipo"],
      numero: json["numero"],
      disponible: json["disponible"],
      cupo: json["cupo"],
      ctaCte: json["ctaCte"],
      moneda: json["moneda"],
      descripcion: json["descripcion"],
      url: json["url"],
      lineas: json["lineas"],
    );
  }
}
