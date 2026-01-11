class ClBancoChilePersonasConfigConsultaMovimientosModel {
  ClBancoChilePersonasConfigConsultaMovimientosModel({
    required this.fechaTope,
    required this.maximoRangoDias,
    required this.fechaTopeEmitida,
    required this.vistaExtendida,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.rango45Dias,
    required this.nombreApoderado,
    required this.apellidoPaternoApoderado,
    required this.apellidoMaternoApoderado,
  });

  final int? fechaTope;
  final int? maximoRangoDias;
  final int? fechaTopeEmitida;
  final bool? vistaExtendida;
  final int? fechaDesde;
  final int? fechaHasta;
  final int? rango45Dias;
  final String? nombreApoderado;
  final String? apellidoPaternoApoderado;
  final String? apellidoMaternoApoderado;

  factory ClBancoChilePersonasConfigConsultaMovimientosModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasConfigConsultaMovimientosModel(
      fechaTope: json["fechaTope"],
      maximoRangoDias: json["maximoRangoDias"],
      fechaTopeEmitida: json["fechaTopeEmitida"],
      vistaExtendida: json["vistaExtendida"],
      fechaDesde: json["fechaDesde"],
      fechaHasta: json["fechaHasta"],
      rango45Dias: json["rango45Dias"],
      nombreApoderado: json["nombreApoderado"],
      apellidoPaternoApoderado: json["apellidoPaternoApoderado"],
      apellidoMaternoApoderado: json["apellidoMaternoApoderado"],
    );
  }

  Map<String, dynamic> toJson() => {
    "fechaTope": fechaTope,
    "maximoRangoDias": maximoRangoDias,
    "fechaTopeEmitida": fechaTopeEmitida,
    "vistaExtendida": vistaExtendida,
    "fechaDesde": fechaDesde,
    "fechaHasta": fechaHasta,
    "rango45Dias": rango45Dias,
    "nombreApoderado": nombreApoderado,
    "apellidoPaternoApoderado": apellidoPaternoApoderado,
    "apellidoMaternoApoderado": apellidoMaternoApoderado,
  };
}
