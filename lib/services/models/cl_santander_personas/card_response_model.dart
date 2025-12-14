class ClSantanderPersonasCardResponse {
  ClSantanderPersonasCardResponse({required this.metadata, required this.data});

  final ClSantanderPersonasCardMetadata? metadata;
  final ClSantanderPersonasCardData? data;

  factory ClSantanderPersonasCardResponse.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasCardResponse(
      metadata: json["METADATA"] == null
          ? null
          : ClSantanderPersonasCardMetadata.fromJson(json["METADATA"]),
      data: json["DATA"] == null
          ? null
          : ClSantanderPersonasCardData.fromJson(json["DATA"]),
    );
  }
}

class ClSantanderPersonasCardData {
  ClSantanderPersonasCardData({required this.conTarjetasRutResponse});

  final ClSantanderPersonasCardConTarjetasRutResponse? conTarjetasRutResponse;

  factory ClSantanderPersonasCardData.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasCardData(
      conTarjetasRutResponse: json["CONTarjetasRut_Response"] == null
          ? null
          : ClSantanderPersonasCardConTarjetasRutResponse.fromJson(
              json["CONTarjetasRut_Response"],
            ),
    );
  }
}

class ClSantanderPersonasCardConTarjetasRutResponse {
  ClSantanderPersonasCardConTarjetasRutResponse({
    required this.info,
    required this.output,
  });

  final ClSantanderPersonasCardInfo? info;
  final ClSantanderPersonasCardOutput? output;

  factory ClSantanderPersonasCardConTarjetasRutResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCardConTarjetasRutResponse(
      info: json["INFO"] == null
          ? null
          : ClSantanderPersonasCardInfo.fromJson(json["INFO"]),
      output: json["OUTPUT"] == null
          ? null
          : ClSantanderPersonasCardOutput.fromJson(json["OUTPUT"]),
    );
  }
}

class ClSantanderPersonasCardInfo {
  ClSantanderPersonasCardInfo({
    required this.codigo,
    required this.msje,
    required this.msjeUsuario,
  });

  final String? codigo;
  final String? msje;
  final dynamic msjeUsuario;

  factory ClSantanderPersonasCardInfo.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasCardInfo(
      codigo: json["Codigo"],
      msje: json["Msje"],
      msjeUsuario: json["MsjeUsuario"],
    );
  }
}

class ClSantanderPersonasCardOutput {
  ClSantanderPersonasCardOutput({required this.detalleConsultaTarjetas});

  final List<ClSantanderPersonasCardDetalleConsultaTarjeta>
  detalleConsultaTarjetas;

  factory ClSantanderPersonasCardOutput.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasCardOutput(
      detalleConsultaTarjetas: json["DetalleConsultaTarjetas"] == null
          ? []
          : List<ClSantanderPersonasCardDetalleConsultaTarjeta>.from(
              json["DetalleConsultaTarjetas"]!.map(
                (x) =>
                    ClSantanderPersonasCardDetalleConsultaTarjeta.fromJson(x),
              ),
            ),
    );
  }
}

class ClSantanderPersonasCardDetalleConsultaTarjeta {
  ClSantanderPersonasCardDetalleConsultaTarjeta({
    required this.calidadParticipa,
    required this.indicador,
    required this.producto,
    required this.subProducto,
    required this.codigoMarca,
    required this.tipoTarjeta,
    required this.entidad,
    required this.centroAlta,
    required this.contrato,
    required this.numeroTarjeta,
    required this.numeroCuenta,
    required this.numeroPlastico,
    required this.codigoBloqueo,
    required this.glosaBloqueo,
    required this.empresa,
    required this.limitePesos,
    required this.limiteDolares,
    required this.imagen,
    required this.flagOfertable,
    required this.glosaProducto,
    required this.titular,
    required this.beneficiario,
    required this.estadoTarjeta,
    required this.fechaCaducidadTarjeta,
    required this.glosaEstadoTarjeta,
    required this.numeroPersona,
    required this.tipoDispositivoPago,
    required this.glosaTipoDispositivoPago,
    required this.cuentaDomicilioTarjeta1,
    required this.cuentaDomicilioTarjeta2,
    required this.datosExterno1,
    required this.datosExterno2,
  });

  final String? calidadParticipa;
  final String? indicador;
  final String? producto;
  final String? subProducto;
  final String? codigoMarca;
  final String? tipoTarjeta;
  final String? entidad;
  final String? centroAlta;
  final String? contrato;
  final String? numeroTarjeta;
  final String? numeroCuenta;
  final String? numeroPlastico;
  final String? codigoBloqueo;
  final String? glosaBloqueo;
  final String? empresa;
  final String? limitePesos;
  final String? limiteDolares;
  final String? imagen;
  final String? flagOfertable;
  final String glosaProducto;
  final String? titular;
  final String? beneficiario;
  final String? estadoTarjeta;
  final String? fechaCaducidadTarjeta;
  final String? glosaEstadoTarjeta;
  final String? numeroPersona;
  final String? tipoDispositivoPago;
  final String? glosaTipoDispositivoPago;
  final String? cuentaDomicilioTarjeta1;
  final dynamic cuentaDomicilioTarjeta2;
  final String? datosExterno1;
  final String? datosExterno2;

  factory ClSantanderPersonasCardDetalleConsultaTarjeta.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCardDetalleConsultaTarjeta(
      calidadParticipa: json["CalidadParticipa"],
      indicador: json["Indicador"],
      producto: json["Producto"],
      subProducto: json["SubProducto"],
      codigoMarca: json["CodigoMarca"],
      tipoTarjeta: json["TipoTarjeta"],
      entidad: json["Entidad"],
      centroAlta: json["CentroAlta"],
      contrato: json["Contrato"],
      numeroTarjeta: json["NumeroTarjeta"],
      numeroCuenta: json["NumeroCuenta"],
      numeroPlastico: json["NumeroPlastico"],
      codigoBloqueo: json["CodigoBloqueo"],
      glosaBloqueo: json["GlosaBloqueo"],
      empresa: json["Empresa"],
      limitePesos: json["LimitePesos"],
      limiteDolares: json["LimiteDolares"],
      imagen: json["Imagen"],
      flagOfertable: json["FlagOfertable"],
      glosaProducto: json["GlosaProducto"],
      titular: json["Titular"],
      beneficiario: json["Beneficiario"],
      estadoTarjeta: json["EstadoTarjeta"],
      fechaCaducidadTarjeta: json["FechaCaducidadTarjeta"],
      glosaEstadoTarjeta: json["GlosaEstadoTarjeta"],
      numeroPersona: json["NumeroPersona"],
      tipoDispositivoPago: json["TipoDispositivoPago"],
      glosaTipoDispositivoPago: json["GlosaTipoDispositivoPago"],
      cuentaDomicilioTarjeta1: json["CuentaDomicilioTarjeta1"],
      cuentaDomicilioTarjeta2: json["CuentaDomicilioTarjeta2"],
      datosExterno1: json["DatosExterno1"],
      datosExterno2: json["DatosExterno2"],
    );
  }
}

class ClSantanderPersonasCardMetadata {
  ClSantanderPersonasCardMetadata({
    required this.status,
    required this.descripcion,
  });

  final String? status;
  final String? descripcion;

  factory ClSantanderPersonasCardMetadata.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasCardMetadata(
      status: json["STATUS"],
      descripcion: json["DESCRIPCION"],
    );
  }
}
