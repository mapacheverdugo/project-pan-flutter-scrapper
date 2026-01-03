class ClSantanderPersonasCreditCardUnbilledTransactionResponseModel {
  ClSantanderPersonasCreditCardUnbilledTransactionResponseModel({
    required this.data,
    required this.metadata,
  });

  final ClSantanderPersonasCreditCardUnbilledTransactionData data;
  final ClSantanderPersonasCreditCardUnbilledTransactionMetadata metadata;

  factory ClSantanderPersonasCreditCardUnbilledTransactionResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCreditCardUnbilledTransactionResponseModel(
      data: ClSantanderPersonasCreditCardUnbilledTransactionData.fromJson(
        json['DATA'] as Map<String, dynamic>,
      ),
      metadata:
          ClSantanderPersonasCreditCardUnbilledTransactionMetadata.fromJson(
        json['METADATA'] as Map<String, dynamic>,
      ),
    );
  }
}

class ClSantanderPersonasCreditCardUnbilledTransactionData {
  ClSantanderPersonasCreditCardUnbilledTransactionData({
    required this.conMovimientosPorFacturarResponse,
  });

  final ClSantanderPersonasCONMovimientosPorFacturarResponse
      conMovimientosPorFacturarResponse;

  factory ClSantanderPersonasCreditCardUnbilledTransactionData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCreditCardUnbilledTransactionData(
      conMovimientosPorFacturarResponse:
          ClSantanderPersonasCONMovimientosPorFacturarResponse.fromJson(
        json['CONMovimientosPorFacturar_Response'] as Map<String, dynamic>,
      ),
    );
  }
}

class ClSantanderPersonasCONMovimientosPorFacturarResponse {
  ClSantanderPersonasCONMovimientosPorFacturarResponse({
    required this.info,
    required this.output,
  });

  final ClSantanderPersonasCreditCardUnbilledTransactionInfo info;
  final ClSantanderPersonasCreditCardUnbilledTransactionOutput output;

  factory ClSantanderPersonasCONMovimientosPorFacturarResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCONMovimientosPorFacturarResponse(
      info: ClSantanderPersonasCreditCardUnbilledTransactionInfo.fromJson(
        json['INFO'] as Map<String, dynamic>,
      ),
      output: ClSantanderPersonasCreditCardUnbilledTransactionOutput.fromJson(
        json['OUTPUT'] as Map<String, dynamic>,
      ),
    );
  }
}

class ClSantanderPersonasCreditCardUnbilledTransactionInfo {
  ClSantanderPersonasCreditCardUnbilledTransactionInfo({
    required this.codigo,
    required this.descripcion,
  });

  final String? codigo;
  final String? descripcion;

  factory ClSantanderPersonasCreditCardUnbilledTransactionInfo.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCreditCardUnbilledTransactionInfo(
      codigo: json['Codigo'] as String?,
      descripcion: json['Descripcion'] as String?,
    );
  }
}

class ClSantanderPersonasCreditCardUnbilledTransactionOutput {
  ClSantanderPersonasCreditCardUnbilledTransactionOutput({
    required this.matrizMovimientosPorFacturar,
  });

  final List<ClSantanderPersonasMatrizMovimientosPorFacturar>
      matrizMovimientosPorFacturar;

  factory ClSantanderPersonasCreditCardUnbilledTransactionOutput.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCreditCardUnbilledTransactionOutput(
      matrizMovimientosPorFacturar: json['MatrizMovimientosPorFacturar'] == null
          ? []
          : List<ClSantanderPersonasMatrizMovimientosPorFacturar>.from(
              (json['MatrizMovimientosPorFacturar'] as List).map(
                (x) => ClSantanderPersonasMatrizMovimientosPorFacturar.fromJson(
                  x as Map<String, dynamic>,
                ),
              ),
            ),
    );
  }
}

class ClSantanderPersonasMatrizMovimientosPorFacturar {
  ClSantanderPersonasMatrizMovimientosPorFacturar({
    required this.ciudad,
    required this.codigoMoneda,
    required this.codigoMonedaExtracto,
    required this.comercio,
    required this.concepto,
    required this.descripcion,
    required this.estadoFinaciamiento,
    required this.fecha,
    required this.glosaRubroActivida,
    required this.importe,
    required this.indicadorDebeHaber,
    required this.indicadorPriSec,
    required this.numeroExtractoPendiente,
    required this.numeroMovimientoExtracto,
    required this.pais,
    required this.referencia,
    required this.tipoBeneficiario,
  });

  final String? ciudad;
  final String? codigoMoneda;
  final String? codigoMonedaExtracto;
  final String? comercio;
  final String? concepto;
  final String? descripcion;
  final String? estadoFinaciamiento;
  final String? fecha;
  final String? glosaRubroActivida;
  final String? importe;
  final String? indicadorDebeHaber;
  final String? indicadorPriSec;
  final String? numeroExtractoPendiente;
  final String? numeroMovimientoExtracto;
  final String? pais;
  final String? referencia;
  final String? tipoBeneficiario;

  factory ClSantanderPersonasMatrizMovimientosPorFacturar.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasMatrizMovimientosPorFacturar(
      ciudad: json['Ciudad'] as String?,
      codigoMoneda: json['CodigoMoneda'] as String?,
      codigoMonedaExtracto: json['CodigoMonedaExtracto'] as String?,
      comercio: json['Comercio'] as String?,
      concepto: json['Concepto'] as String?,
      descripcion: json['Descripcion'] as String?,
      estadoFinaciamiento: json['EstadoFinaciamiento'] as String?,
      fecha: json['Fecha'] as String?,
      glosaRubroActivida: json['GlosaRubroActivida'] as String?,
      importe: json['Importe'] as String?,
      indicadorDebeHaber: json['IndicadorDebeHaber'] as String?,
      indicadorPriSec: json['IndicadorPriSec'] as String?,
      numeroExtractoPendiente: json['NumeroExtractoPendiente'] as String?,
      numeroMovimientoExtracto: json['NumeroMovimientoExtracto'] as String?,
      pais: json['Pais'] as String?,
      referencia: json['Referencia'] as String?,
      tipoBeneficiario: json['TipoBeneficiario'] as String?,
    );
  }
}

class ClSantanderPersonasCreditCardUnbilledTransactionMetadata {
  ClSantanderPersonasCreditCardUnbilledTransactionMetadata({
    required this.descripcion,
    required this.status,
  });

  final String? descripcion;
  final String? status;

  factory ClSantanderPersonasCreditCardUnbilledTransactionMetadata.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClSantanderPersonasCreditCardUnbilledTransactionMetadata(
      descripcion: json['DESCRIPCION'] as String?,
      status: json['STATUS'] as String?,
    );
  }
}

