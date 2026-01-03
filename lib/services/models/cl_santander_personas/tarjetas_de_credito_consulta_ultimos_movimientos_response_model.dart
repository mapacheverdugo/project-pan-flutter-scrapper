class ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosResponseModel {
  ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosResponseModel({
    required this.metadata,
    required this.data,
  });

  final ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMetadata?
  metadata;
  final ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosData?
  data;

  factory ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosResponseModel(
      metadata: json["METADATA"] == null
          ? null
          : ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMetadata.fromJson(
              json["METADATA"],
            ),
      data: json["DATA"] == null
          ? null
          : ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosData.fromJson(
              json["DATA"],
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "METADATA": metadata?.toJson(),
    "DATA": data?.toJson(),
  };
}

class ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosData {
  ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosData({
    required this.informacion,
    required this.matrizMovimientos,
  });

  final ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion?
  informacion;
  final List<
    ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMatrizMovimiento
  >
  matrizMovimientos;

  factory ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosData(
      informacion:
          json["ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion"] ==
              null
          ? null
          : ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion.fromJson(
              json["ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion"],
            ),
      matrizMovimientos: json["MatrizMovimientos"] == null
          ? []
          : List<
              ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMatrizMovimiento
            >.from(
              json["MatrizMovimientos"]!.map(
                (x) =>
                    ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMatrizMovimiento.fromJson(
                      x,
                    ),
              ),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion":
        informacion?.toJson(),
    "MatrizMovimientos": matrizMovimientos.map((x) => x?.toJson()).toList(),
  };
}

class ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion {
  ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion({
    required this.codigo,
    required this.resultado,
    required this.mensaje,
  });

  final String? codigo;
  final String? resultado;
  final String? mensaje;

  factory ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosInformacion(
      codigo: json["Codigo"],
      resultado: json["Resultado"],
      mensaje: json["Mensaje"],
    );
  }

  Map<String, dynamic> toJson() => {
    "Codigo": codigo,
    "Resultado": resultado,
    "Mensaje": mensaje,
  };
}

class ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMatrizMovimiento {
  ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMatrizMovimiento({
    required this.fecha,
    required this.descripcion,
    required this.comercio,
    required this.importe,
    required this.descripcionRubro,
    required this.ciudad,
    required this.tipoBen,
    required this.indicadorDebeHaber,
  });

  final String? fecha;
  final String? descripcion;
  final String? comercio;
  final String? importe;
  final dynamic descripcionRubro;
  final String? ciudad;
  final dynamic tipoBen;
  final String? indicadorDebeHaber;

  factory ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMatrizMovimiento.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMatrizMovimiento(
      fecha: json["Fecha"],
      descripcion: json["Descripcion"],
      comercio: json["Comercio"],
      importe: json["Importe"],
      descripcionRubro: json["DescripcionRubro"],
      ciudad: json["Ciudad"],
      tipoBen: json["TipoBen"],
      indicadorDebeHaber: json["IndicadorDebeHaber"],
    );
  }

  Map<String, dynamic> toJson() => {
    "Fecha": fecha,
    "Descripcion": descripcion,
    "Comercio": comercio,
    "Importe": importe,
    "DescripcionRubro": descripcionRubro,
    "Ciudad": ciudad,
    "TipoBen": tipoBen,
    "IndicadorDebeHaber": indicadorDebeHaber,
  };
}

class ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMetadata {
  ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMetadata({
    required this.status,
    required this.descripcion,
  });

  final String? status;
  final String? descripcion;

  factory ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMetadata.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMetadata(
      status: json["STATUS"],
      descripcion: json["DESCRIPCION"],
    );
  }

  Map<String, dynamic> toJson() => {
    "STATUS": status,
    "DESCRIPCION": descripcion,
  };
}
