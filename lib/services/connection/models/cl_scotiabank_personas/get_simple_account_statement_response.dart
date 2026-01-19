class ClScotiabankPersonasGetSimpleAccountStatementResponse {
  ClScotiabankPersonasGetSimpleAccountStatementResponse({
    required this.informacionPeriodoResumen,
    required this.informacionPeriodoDetalle,
    required this.proximoPeriodoResumen,
    required this.proximoPeriodoDetalle,
  });

  final InformacionPeriodoResumen? informacionPeriodoResumen;
  final InformacionPeriodoDetalle? informacionPeriodoDetalle;
  final ProximoPeriodoResumen? proximoPeriodoResumen;
  final ProximoPeriodoDetalle? proximoPeriodoDetalle;

  factory ClScotiabankPersonasGetSimpleAccountStatementResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClScotiabankPersonasGetSimpleAccountStatementResponse(
      informacionPeriodoResumen: json["informacionPeriodoResumen"] == null
          ? null
          : InformacionPeriodoResumen.fromJson(
              json["informacionPeriodoResumen"],
            ),
      informacionPeriodoDetalle: json["informacionPeriodoDetalle"] == null
          ? null
          : InformacionPeriodoDetalle.fromJson(
              json["informacionPeriodoDetalle"],
            ),
      proximoPeriodoResumen: json["proximoPeriodoResumen"] == null
          ? null
          : ProximoPeriodoResumen.fromJson(json["proximoPeriodoResumen"]),
      proximoPeriodoDetalle: json["proximoPeriodoDetalle"] == null
          ? null
          : ProximoPeriodoDetalle.fromJson(json["proximoPeriodoDetalle"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "informacionPeriodoResumen": informacionPeriodoResumen?.toJson(),
    "informacionPeriodoDetalle": informacionPeriodoDetalle?.toJson(),
    "proximoPeriodoResumen": proximoPeriodoResumen?.toJson(),
    "proximoPeriodoDetalle": proximoPeriodoDetalle?.toJson(),
  };
}

class InformacionPeriodoDetalle {
  InformacionPeriodoDetalle({
    required this.totalPeriodoAnterior,
    required this.pagosRealizados,
    required this.saldoPeriodoAnterior,
    required this.totalComprasAvancesSinCuotasTitular,
    required this.totalComprasAvancesSinCuotasAdicional,
    required this.pagosAutomaticos,
    required this.totalComprasAvanceSinCuotas,
    required this.totalComprasAvancesEnCuotasTitular,
    required this.totalComprasAvancesEnCuotasAdicional,
    required this.totalComprasAvancesEnCuotas,
    required this.comisionMensual,
    required this.otrasComisiones,
    required this.intereses,
    required this.interesesMora,
    required this.traspasoDeudaInternacional,
    required this.impuestos,
    required this.totalCostos,
    required this.totalAbonosDevoluciones,
    required this.totalFacturadoIntereses,
  });

  final String? totalPeriodoAnterior;
  final String? pagosRealizados;
  final String? saldoPeriodoAnterior;
  final String? totalComprasAvancesSinCuotasTitular;
  final String? totalComprasAvancesSinCuotasAdicional;
  final String? pagosAutomaticos;
  final String? totalComprasAvanceSinCuotas;
  final String? totalComprasAvancesEnCuotasTitular;
  final String? totalComprasAvancesEnCuotasAdicional;
  final String? totalComprasAvancesEnCuotas;
  final String? comisionMensual;
  final String? otrasComisiones;
  final String? intereses;
  final String? interesesMora;
  final String? traspasoDeudaInternacional;
  final String? impuestos;
  final String? totalCostos;
  final String? totalAbonosDevoluciones;
  final String? totalFacturadoIntereses;

  factory InformacionPeriodoDetalle.fromJson(Map<String, dynamic> json) {
    return InformacionPeriodoDetalle(
      totalPeriodoAnterior: json["totalPeriodoAnterior"],
      pagosRealizados: json["pagosRealizados"],
      saldoPeriodoAnterior: json["saldoPeriodoAnterior"],
      totalComprasAvancesSinCuotasTitular:
          json["totalComprasAvancesSinCuotasTitular"],
      totalComprasAvancesSinCuotasAdicional:
          json["totalComprasAvancesSinCuotasAdicional"],
      pagosAutomaticos: json["pagosAutomaticos"],
      totalComprasAvanceSinCuotas: json["totalComprasAvanceSinCuotas"],
      totalComprasAvancesEnCuotasTitular:
          json["totalComprasAvancesEnCuotasTitular"],
      totalComprasAvancesEnCuotasAdicional:
          json["totalComprasAvancesEnCuotasAdicional"],
      totalComprasAvancesEnCuotas: json["totalComprasAvancesEnCuotas"],
      comisionMensual: json["comisionMensual"],
      otrasComisiones: json["otrasComisiones"],
      intereses: json["intereses"],
      interesesMora: json["interesesMora"],
      traspasoDeudaInternacional: json["traspasoDeudaInternacional"],
      impuestos: json["impuestos"],
      totalCostos: json["totalCostos"],
      totalAbonosDevoluciones: json["totalAbonosDevoluciones"],
      totalFacturadoIntereses: json["totalFacturadoIntereses"],
    );
  }

  Map<String, dynamic> toJson() => {
    "totalPeriodoAnterior": totalPeriodoAnterior,
    "pagosRealizados": pagosRealizados,
    "saldoPeriodoAnterior": saldoPeriodoAnterior,
    "totalComprasAvancesSinCuotasTitular": totalComprasAvancesSinCuotasTitular,
    "totalComprasAvancesSinCuotasAdicional":
        totalComprasAvancesSinCuotasAdicional,
    "pagosAutomaticos": pagosAutomaticos,
    "totalComprasAvanceSinCuotas": totalComprasAvanceSinCuotas,
    "totalComprasAvancesEnCuotasTitular": totalComprasAvancesEnCuotasTitular,
    "totalComprasAvancesEnCuotasAdicional":
        totalComprasAvancesEnCuotasAdicional,
    "totalComprasAvancesEnCuotas": totalComprasAvancesEnCuotas,
    "comisionMensual": comisionMensual,
    "otrasComisiones": otrasComisiones,
    "intereses": intereses,
    "interesesMora": interesesMora,
    "traspasoDeudaInternacional": traspasoDeudaInternacional,
    "impuestos": impuestos,
    "totalCostos": totalCostos,
    "totalAbonosDevoluciones": totalAbonosDevoluciones,
    "totalFacturadoIntereses": totalFacturadoIntereses,
  };
}

class InformacionPeriodoResumen {
  InformacionPeriodoResumen({
    required this.totalFacturado,
    required this.pagoMinimo,
    required this.pagarHasta,
    required this.periodoFacturacionDesde,
    required this.periodoFacturacionHasta,
  });

  final String? totalFacturado;
  final String? pagoMinimo;
  final String? pagarHasta;
  final String? periodoFacturacionDesde;
  final String? periodoFacturacionHasta;

  factory InformacionPeriodoResumen.fromJson(Map<String, dynamic> json) {
    return InformacionPeriodoResumen(
      totalFacturado: json["totalFacturado"],
      pagoMinimo: json["pagoMinimo"],
      pagarHasta: json["pagarHasta"],
      periodoFacturacionDesde: json["periodoFacturacionDesde"],
      periodoFacturacionHasta: json["periodoFacturacionHasta"],
    );
  }

  Map<String, dynamic> toJson() => {
    "totalFacturado": totalFacturado,
    "pagoMinimo": pagoMinimo,
    "pagarHasta": pagarHasta,
    "periodoFacturacionDesde": periodoFacturacionDesde,
    "periodoFacturacionHasta": periodoFacturacionHasta,
  };
}

class ProximoPeriodoDetalle {
  ProximoPeriodoDetalle({
    required this.proximasCuotas,
    required this.tasaInteres,
    required this.cae,
  });

  final List<String> proximasCuotas;
  final List<String> tasaInteres;
  final List<String> cae;

  factory ProximoPeriodoDetalle.fromJson(Map<String, dynamic> json) {
    return ProximoPeriodoDetalle(
      proximasCuotas: json["proximasCuotas"] == null
          ? []
          : List<String>.from(json["proximasCuotas"]!.map((x) => x)),
      tasaInteres: json["tasaInteres"] == null
          ? []
          : List<String>.from(json["tasaInteres"]!.map((x) => x)),
      cae: json["cae"] == null
          ? []
          : List<String>.from(json["cae"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "proximasCuotas": proximasCuotas.map((x) => x).toList(),
    "tasaInteres": tasaInteres.map((x) => x).toList(),
    "cae": cae.map((x) => x).toList(),
  };
}

class ProximoPeriodoResumen {
  ProximoPeriodoResumen({
    required this.periodoDesde,
    required this.periodoHasta,
    required this.pagarHasta,
  });

  final String? periodoDesde;
  final String? periodoHasta;
  final String? pagarHasta;

  factory ProximoPeriodoResumen.fromJson(Map<String, dynamic> json) {
    return ProximoPeriodoResumen(
      periodoDesde: json["periodoDesde"],
      periodoHasta: json["periodoHasta"],
      pagarHasta: json["pagarHasta"],
    );
  }

  Map<String, dynamic> toJson() => {
    "periodoDesde": periodoDesde,
    "periodoHasta": periodoHasta,
    "pagarHasta": pagarHasta,
  };
}
