class ClSantanderPersonasProductsResponse {
  ClSantanderPersonasProductsResponse({
    required this.metadata,
    required this.data,
  });

  final ClSantanderPersonasProductsMetadata? metadata;
  final ClSantanderPersonasProductsData? data;

  factory ClSantanderPersonasProductsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasProductsResponse(
      metadata: json["METADATA"] == null
          ? null
          : ClSantanderPersonasProductsMetadata.fromJson(json["METADATA"]),
      data: json["DATA"] == null
          ? null
          : ClSantanderPersonasProductsData.fromJson(json["DATA"]),
    );
  }
}

class ClSantanderPersonasProductsData {
  ClSantanderPersonasProductsData({required this.output});

  final ClSantanderPersonasProductsOutput? output;

  factory ClSantanderPersonasProductsData.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasProductsData(
      output: json["OUTPUT"] == null
          ? null
          : ClSantanderPersonasProductsOutput.fromJson(json["OUTPUT"]),
    );
  }
}

class ClSantanderPersonasProductsOutput {
  ClSantanderPersonasProductsOutput({
    required this.info,
    required this.escalares,
    required this.matrices,
  });

  final ClSantanderPersonasProductsInfo? info;
  final ClSantanderPersonasProductsEscalares? escalares;
  final ClSantanderPersonasProductsMatrices? matrices;

  factory ClSantanderPersonasProductsOutput.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasProductsOutput(
      info: json["INFO"] == null
          ? null
          : ClSantanderPersonasProductsInfo.fromJson(json["INFO"]),
      escalares: json["ESCALARES"] == null
          ? null
          : ClSantanderPersonasProductsEscalares.fromJson(json["ESCALARES"]),
      matrices: json["MATRICES"] == null
          ? null
          : ClSantanderPersonasProductsMatrices.fromJson(json["MATRICES"]),
    );
  }
}

class ClSantanderPersonasProductsEscalares {
  ClSantanderPersonasProductsEscalares({
    required this.numeropersona,
    required this.tipodocumento,
    required this.numerodocumento,
    required this.tipopersona,
    required this.apellidopaterno,
    required this.apellidomaterno,
    required this.nombrepersona,
    required this.nombrefantasia,
    required this.segmento,
    required this.perfil,
    required this.glsegmento,
    required this.subsegmento,
    required this.glsubsegmento,
    required this.msgid,
    required this.layout,
    required this.meritolife,
    required this.penumpue,
  });

  final String? numeropersona;
  final String? tipodocumento;
  final String? numerodocumento;
  final String? tipopersona;
  final String? apellidopaterno;
  final String? apellidomaterno;
  final String? nombrepersona;
  final dynamic nombrefantasia;
  final String? segmento;
  final String? perfil;
  final String? glsegmento;
  final String? subsegmento;
  final String? glsubsegmento;
  final dynamic msgid;
  final String? layout;
  final String? meritolife;
  final String? penumpue;

  factory ClSantanderPersonasProductsEscalares.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasProductsEscalares(
      numeropersona: json["NUMEROPERSONA"],
      tipodocumento: json["TIPODOCUMENTO"],
      numerodocumento: json["NUMERODOCUMENTO"],
      tipopersona: json["TIPOPERSONA"],
      apellidopaterno: json["APELLIDOPATERNO"],
      apellidomaterno: json["APELLIDOMATERNO"],
      nombrepersona: json["NOMBREPERSONA"],
      nombrefantasia: json["NOMBREFANTASIA"],
      segmento: json["SEGMENTO"],
      perfil: json["PERFIL"],
      glsegmento: json["GLSEGMENTO"],
      subsegmento: json["SUBSEGMENTO"],
      glsubsegmento: json["GLSUBSEGMENTO"],
      msgid: json["MSGID"],
      layout: json["LAYOUT"],
      meritolife: json["MERITOLIFE"],
      penumpue: json["PENUMPUE"],
    );
  }
}

class ClSantanderPersonasProductsInfo {
  ClSantanderPersonasProductsInfo({
    required this.coderr,
    required this.deserr,
    required this.msgusuario,
  });

  final String? coderr;
  final String? deserr;
  final String? msgusuario;

  factory ClSantanderPersonasProductsInfo.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasProductsInfo(
      coderr: json["CODERR"],
      deserr: json["DESERR"],
      msgusuario: json["MSGUSUARIO"],
    );
  }
}

class ClSantanderPersonasProductsMatrices {
  ClSantanderPersonasProductsMatrices({required this.matrizcaptaciones});

  final ClSantanderPersonasProductsMatrizcaptaciones? matrizcaptaciones;

  factory ClSantanderPersonasProductsMatrices.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasProductsMatrices(
      matrizcaptaciones: json["MATRIZCAPTACIONES"] == null
          ? null
          : ClSantanderPersonasProductsMatrizcaptaciones.fromJson(
              json["MATRIZCAPTACIONES"],
            ),
    );
  }
}

class ClSantanderPersonasProductsMatrizcaptaciones {
  ClSantanderPersonasProductsMatrizcaptaciones({required this.e1});

  final List<ClSantanderPersonasProductsE1> e1;

  factory ClSantanderPersonasProductsMatrizcaptaciones.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasProductsMatrizcaptaciones(
      e1: json["e1"] == null
          ? []
          : List<ClSantanderPersonasProductsE1>.from(
              json["e1"]!.map((x) => ClSantanderPersonasProductsE1.fromJson(x)),
            ),
    );
  }
}

class ClSantanderPersonasProductsE1 {
  ClSantanderPersonasProductsE1({
    required this.numerocontrato,
    required this.producto,
    required this.subproducto,
    required this.montodisponible,
    required this.montoutilizado,
    required this.glosacorta,
    required this.oficinacontrato,
    required this.cupo,
    required this.glosaestado,
    required this.numeropan,
    required this.estadooperacion,
    required this.estadorelacion,
    required this.codigomoneda,
    required this.agrupacioncomercial,
    required this.calidadparticipacion,
  });

  final String? numerocontrato;
  final String? producto;
  final String? subproducto;
  final String? montodisponible;
  final String? montoutilizado;
  final String? glosacorta;
  final String? oficinacontrato;
  final String? cupo;
  final String? glosaestado;
  final String? numeropan;
  final String? estadooperacion;
  final String? estadorelacion;
  final String? codigomoneda;
  final String? agrupacioncomercial;
  final String? calidadparticipacion;

  factory ClSantanderPersonasProductsE1.fromJson(Map<String, dynamic> json) {
    return ClSantanderPersonasProductsE1(
      numerocontrato: json["NUMEROCONTRATO"],
      producto: json["PRODUCTO"],
      subproducto: json["SUBPRODUCTO"],
      montodisponible: json["MONTODISPONIBLE"],
      montoutilizado: json["MONTOUTILIZADO"],
      glosacorta: json["GLOSACORTA"],
      oficinacontrato: json["OFICINACONTRATO"],
      cupo: json["CUPO"],
      glosaestado: json["GLOSAESTADO"],
      numeropan: json["NUMEROPAN"],
      estadooperacion: json["ESTADOOPERACION"],
      estadorelacion: json["ESTADORELACION"],
      codigomoneda: json["CODIGOMONEDA"],
      agrupacioncomercial: json["AGRUPACIONCOMERCIAL"],
      calidadparticipacion: json["CALIDADPARTICIPACION"],
    );
  }
}

class ClSantanderPersonasProductsMetadata {
  ClSantanderPersonasProductsMetadata({
    required this.status,
    required this.descripcion,
  });

  final String? status;
  final String? descripcion;

  factory ClSantanderPersonasProductsMetadata.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasProductsMetadata(
      status: json["STATUS"],
      descripcion: json["DESCRIPCION"],
    );
  }
}
