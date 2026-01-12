class ClBancoChilePersonasMovimientosNoFacturadosModel {
  ClBancoChilePersonasMovimientosNoFacturadosModel({
    required this.tarjetaHabiente,
    required this.fechaFacturacionAnterior,
    required this.fechaAhora,
    required this.fechaFacturacionAnteriorString,
    required this.fechaAhoraString,
    required this.fechaProximaFacturacionCalendario,
    required this.listaMovNoFactur,
  });

  final String? tarjetaHabiente;
  final int? fechaFacturacionAnterior;
  final int? fechaAhora;
  final String? fechaFacturacionAnteriorString;
  final String? fechaAhoraString;
  final String? fechaProximaFacturacionCalendario;
  final List<ClBancoChilePersonasListaMovNoFactur> listaMovNoFactur;

  factory ClBancoChilePersonasMovimientosNoFacturadosModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasMovimientosNoFacturadosModel(
      tarjetaHabiente: json["tarjetaHabiente"],
      fechaFacturacionAnterior: json["fechaFacturacionAnterior"],
      fechaAhora: json["fechaAhora"],
      fechaFacturacionAnteriorString: json["fechaFacturacionAnteriorString"],
      fechaAhoraString: json["fechaAhoraString"],
      fechaProximaFacturacionCalendario:
          json["fechaProximaFacturacionCalendario"],
      listaMovNoFactur: json["listaMovNoFactur"] == null
          ? []
          : List<ClBancoChilePersonasListaMovNoFactur>.from(
              json["listaMovNoFactur"]!.map(
                (x) => ClBancoChilePersonasListaMovNoFactur.fromJson(x),
              ),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "tarjetaHabiente": tarjetaHabiente,
    "fechaFacturacionAnterior": fechaFacturacionAnterior,
    "fechaAhora": fechaAhora,
    "fechaFacturacionAnteriorString": fechaFacturacionAnteriorString,
    "fechaAhoraString": fechaAhoraString,
    "fechaProximaFacturacionCalendario": fechaProximaFacturacionCalendario,
    "listaMovNoFactur": listaMovNoFactur.map((x) => x?.toJson()).toList(),
  };
}

class ClBancoChilePersonasListaMovNoFactur {
  ClBancoChilePersonasListaMovNoFactur({
    required this.origenTransaccion,
    required this.fechaTransaccion,
    required this.fechaTransaccionString,
    required this.montoCompra,
    required this.glosaTransaccion,
    required this.codigoComercioTbk,
    required this.codigoComercioInt,
    required this.nombreComercio,
    required this.rubroComercio,
    required this.codigoPaisComercio,
    required this.ciudad,
    required this.fechaAutorizacion,
    required this.horaAutorizacion,
    required this.numeroTarjeta,
    required this.descripcionTransaccion,
    required this.montoMonedaOrigen,
    required this.codigoMonedaOrigen,
    required this.despliegueCuotas,
    required this.numeroCuotas,
    required this.numeroTotalCuotas,
    required this.tipoTarjeta,
    required this.fechaAutorizacionString,
    required this.montoCompraString,
    required this.nombreTarjetaHabiente,
    required this.numeroTarjetaCompleto,
  });

  final String? origenTransaccion;
  final int? fechaTransaccion;
  final String? fechaTransaccionString;
  final double? montoCompra;
  final String? glosaTransaccion;
  final int? codigoComercioTbk;
  final String? codigoComercioInt;
  final String? nombreComercio;
  final String? rubroComercio;
  final String? codigoPaisComercio;
  final String? ciudad;
  final String? fechaAutorizacion;
  final String? horaAutorizacion;
  final String? numeroTarjeta;
  final String? descripcionTransaccion;
  final String? montoMonedaOrigen;
  final int? codigoMonedaOrigen;
  final String? despliegueCuotas;
  final String? numeroCuotas;
  final String? numeroTotalCuotas;
  final String? tipoTarjeta;
  final String? fechaAutorizacionString;
  final String? montoCompraString;
  final String? nombreTarjetaHabiente;
  final dynamic numeroTarjetaCompleto;

  factory ClBancoChilePersonasListaMovNoFactur.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClBancoChilePersonasListaMovNoFactur(
      origenTransaccion: json["origenTransaccion"],
      fechaTransaccion: json["fechaTransaccion"],
      fechaTransaccionString: json["fechaTransaccionString"],
      montoCompra: json["montoCompra"],
      glosaTransaccion: json["glosaTransaccion"],
      codigoComercioTbk: json["codigoComercioTBK"],
      codigoComercioInt: json["codigoComercioINT"],
      nombreComercio: json["nombreComercio"],
      rubroComercio: json["rubroComercio"],
      codigoPaisComercio: json["codigoPaisComercio"],
      ciudad: json["ciudad"],
      fechaAutorizacion: json["fechaAutorizacion"],
      horaAutorizacion: json["horaAutorizacion"],
      numeroTarjeta: json["numeroTarjeta"],
      descripcionTransaccion: json["descripcionTransaccion"],
      montoMonedaOrigen: json["montoMonedaOrigen"],
      codigoMonedaOrigen: json["codigoMonedaOrigen"],
      despliegueCuotas: json["despliegueCuotas"],
      numeroCuotas: json["numeroCuotas"],
      numeroTotalCuotas: json["numeroTotalCuotas"],
      tipoTarjeta: json["tipoTarjeta"],
      fechaAutorizacionString: json["fechaAutorizacionString"],
      montoCompraString: json["montoCompraString"],
      nombreTarjetaHabiente: json["nombreTarjetaHabiente"],
      numeroTarjetaCompleto: json["numeroTarjetaCompleto"],
    );
  }

  Map<String, dynamic> toJson() => {
    "origenTransaccion": origenTransaccion,
    "fechaTransaccion": fechaTransaccion,
    "fechaTransaccionString": fechaTransaccionString,
    "montoCompra": montoCompra,
    "glosaTransaccion": glosaTransaccion,
    "codigoComercioTBK": codigoComercioTbk,
    "codigoComercioINT": codigoComercioInt,
    "nombreComercio": nombreComercio,
    "rubroComercio": rubroComercio,
    "codigoPaisComercio": codigoPaisComercio,
    "ciudad": ciudad,
    "fechaAutorizacion": fechaAutorizacion,
    "horaAutorizacion": horaAutorizacion,
    "numeroTarjeta": numeroTarjeta,
    "descripcionTransaccion": descripcionTransaccion,
    "montoMonedaOrigen": montoMonedaOrigen,
    "codigoMonedaOrigen": codigoMonedaOrigen,
    "despliegueCuotas": despliegueCuotas,
    "numeroCuotas": numeroCuotas,
    "numeroTotalCuotas": numeroTotalCuotas,
    "tipoTarjeta": tipoTarjeta,
    "fechaAutorizacionString": fechaAutorizacionString,
    "montoCompraString": montoCompraString,
    "nombreTarjetaHabiente": nombreTarjetaHabiente,
    "numeroTarjetaCompleto": numeroTarjetaCompleto,
  };
}
