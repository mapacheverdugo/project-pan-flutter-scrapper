import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/institution_code.dart';

class InstitutionCodeJsonConverter
    extends JsonConverter<InstitutionCode, String> {
  const InstitutionCodeJsonConverter();

  @override
  InstitutionCode fromJson(String json) {
    switch (json.toLowerCase()) {
      case "cl_banco_chile_personas":
        return InstitutionCode.clBancoChilePersonas;
      case "cl_bci_personas":
        return InstitutionCode.clBciPersonas;
      case "cl_santander_personas":
        return InstitutionCode.clSantanderPersonas;
      case "cl_scotiabank_personas":
        return InstitutionCode.clScotiabankPersonas;
      case "cl_banco_estado_personas":
        return InstitutionCode.clBancoEstadoPersonas;
      case "cl_banco_falabella_personas":
        return InstitutionCode.clBancoFalabellaPersonas;
      default:
        return InstitutionCode.unknown;
    }
  }

  @override
  String toJson(InstitutionCode object) {
    switch (object) {
      case InstitutionCode.clBciPersonas:
        return "cl_bci_personas".toUpperCase();
      case InstitutionCode.clSantanderPersonas:
        return "cl_santander_personas".toUpperCase();
      case InstitutionCode.clScotiabankPersonas:
        return "cl_scotiabank_personas".toUpperCase();
      case InstitutionCode.clBancoChilePersonas:
        return "cl_banco_chile_personas".toUpperCase();
      case InstitutionCode.clItauPersonas:
        return "cl_itau_personas".toUpperCase();
      case InstitutionCode.clBancoFalabellaPersonas:
        return "cl_banco_falabella_personas".toUpperCase();
      case InstitutionCode.clBancoEstadoPersonas:
        return "cl_banco_estado_personas".toUpperCase();
      case InstitutionCode.unknown:
        return "unknown".toUpperCase();
    }
  }
}
