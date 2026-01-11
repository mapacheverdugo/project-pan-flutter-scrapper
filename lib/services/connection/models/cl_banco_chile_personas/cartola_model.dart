class ClBancoChilePersonasCartolaModel {
  ClBancoChilePersonasCartolaModel({
    required this.horaConsulta,
    required this.moneda,
    required this.saldoFinal,
    required this.totalCargos,
    required this.totalAbonos,
    required this.retencion1Dia,
    required this.retencionNDia,
    required this.montoAutorizado,
    required this.montoUtilizado,
    required this.saldoDisponible,
    required this.lineaCredito,
    required this.movimientos,
    required this.pagina,
    required this.montoUtilizadoLinea,
    required this.montoAutorizadoLinea,
    required this.saldoDisponibleLinea,
    required this.numeroLineaCredito,
    required this.permisoLineaCredito,
  });

  final String? horaConsulta;
  final String? moneda;
  final int? saldoFinal;
  final int? totalCargos;
  final int? totalAbonos;
  final int? retencion1Dia;
  final int? retencionNDia;
  final int? montoAutorizado;
  final int? montoUtilizado;
  final int? saldoDisponible;
  final int? lineaCredito;
  final List<Movimiento> movimientos;
  final List<Pagina> pagina;
  final int? montoUtilizadoLinea;
  final int? montoAutorizadoLinea;
  final int? saldoDisponibleLinea;
  final String? numeroLineaCredito;
  final bool? permisoLineaCredito;

  factory ClBancoChilePersonasCartolaModel.fromJson(Map<String, dynamic> json) {
    return ClBancoChilePersonasCartolaModel(
      horaConsulta: json["horaConsulta"],
      moneda: json["moneda"],
      saldoFinal: json["saldoFinal"],
      totalCargos: json["totalCargos"],
      totalAbonos: json["totalAbonos"],
      retencion1Dia: json["retencion1Dia"],
      retencionNDia: json["retencionNDia"],
      montoAutorizado: json["montoAutorizado"],
      montoUtilizado: json["montoUtilizado"],
      saldoDisponible: json["saldoDisponible"],
      lineaCredito: json["lineaCredito"],
      movimientos: json["movimientos"] == null
          ? []
          : List<Movimiento>.from(
              json["movimientos"]!.map((x) => Movimiento.fromJson(x)),
            ),
      pagina: json["pagina"] == null
          ? []
          : List<Pagina>.from(json["pagina"]!.map((x) => Pagina.fromJson(x))),
      montoUtilizadoLinea: json["montoUtilizadoLinea"],
      montoAutorizadoLinea: json["montoAutorizadoLinea"],
      saldoDisponibleLinea: json["saldoDisponibleLinea"],
      numeroLineaCredito: json["numeroLineaCredito"],
      permisoLineaCredito: json["permisoLineaCredito"],
    );
  }

  Map<String, dynamic> toJson() => {
    "horaConsulta": horaConsulta,
    "moneda": moneda,
    "saldoFinal": saldoFinal,
    "totalCargos": totalCargos,
    "totalAbonos": totalAbonos,
    "retencion1Dia": retencion1Dia,
    "retencionNDia": retencionNDia,
    "montoAutorizado": montoAutorizado,
    "montoUtilizado": montoUtilizado,
    "saldoDisponible": saldoDisponible,
    "lineaCredito": lineaCredito,
    "movimientos": movimientos.map((x) => x?.toJson()).toList(),
    "pagina": pagina.map((x) => x?.toJson()).toList(),
    "montoUtilizadoLinea": montoUtilizadoLinea,
    "montoAutorizadoLinea": montoAutorizadoLinea,
    "saldoDisponibleLinea": saldoDisponibleLinea,
    "numeroLineaCredito": numeroLineaCredito,
    "permisoLineaCredito": permisoLineaCredito,
  };
}

class Movimiento {
  Movimiento({
    required this.estado,
    required this.descripcion,
    required this.monto,
    required this.saldo,
    required this.nombreCuenta,
    required this.numeroCuenta,
    required this.idCuenta,
    required this.canal,
    required this.tipo,
    required this.fecha,
    required this.fechaContable,
    required this.id,
    required this.numeroDocumento,
    required this.fechaContableMovimiento,
    required this.detalleGlosa,
  });

  final dynamic estado;
  final String? descripcion;
  final String? monto;
  final String? saldo;
  final String? nombreCuenta;
  final String? numeroCuenta;
  final String? idCuenta;
  final String? canal;
  final String? tipo;
  final String? fecha;
  final String? fechaContable;
  final String? id;
  final String? numeroDocumento;
  final int? fechaContableMovimiento;
  final List<String> detalleGlosa;

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      estado: json["estado"],
      descripcion: json["descripcion"],
      monto: json["monto"],
      saldo: json["saldo"],
      nombreCuenta: json["nombreCuenta"],
      numeroCuenta: json["numeroCuenta"],
      idCuenta: json["idCuenta"],
      canal: json["canal"],
      tipo: json["tipo"],
      fecha: json["fecha"],
      fechaContable: json["fechaContable"],
      id: json["id"],
      numeroDocumento: json["numeroDocumento"],
      fechaContableMovimiento: json["fechaContableMovimiento"],
      detalleGlosa: json["detalleGlosa"] == null
          ? []
          : List<String>.from(json["detalleGlosa"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "estado": estado,
    "descripcion": descripcion,
    "monto": monto,
    "saldo": saldo,
    "nombreCuenta": nombreCuenta,
    "numeroCuenta": numeroCuenta,
    "idCuenta": idCuenta,
    "canal": canal,
    "tipo": tipo,
    "fecha": fecha,
    "fechaContable": fechaContable,
    "id": id,
    "numeroDocumento": numeroDocumento,
    "fechaContableMovimiento": fechaContableMovimiento,
    "detalleGlosa": detalleGlosa.map((x) => x).toList(),
  };
}

class Pagina {
  Pagina({
    required this.idCuenta,
    required this.cantidadRegistros,
    required this.totalRegistros,
    required this.indiceInicio,
    required this.indiceTermino,
    required this.masPaginas,
  });

  final String? idCuenta;
  final String? cantidadRegistros;
  final String? totalRegistros;
  final String? indiceInicio;
  final String? indiceTermino;
  final String? masPaginas;

  factory Pagina.fromJson(Map<String, dynamic> json) {
    return Pagina(
      idCuenta: json["idCuenta"],
      cantidadRegistros: json["cantidadRegistros"],
      totalRegistros: json["totalRegistros"],
      indiceInicio: json["indiceInicio"],
      indiceTermino: json["indiceTermino"],
      masPaginas: json["masPaginas"],
    );
  }

  Map<String, dynamic> toJson() => {
    "idCuenta": idCuenta,
    "cantidadRegistros": cantidadRegistros,
    "totalRegistros": totalRegistros,
    "indiceInicio": indiceInicio,
    "indiceTermino": indiceTermino,
    "masPaginas": masPaginas,
  };
}
