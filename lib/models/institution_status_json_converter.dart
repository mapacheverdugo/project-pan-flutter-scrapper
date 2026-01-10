import 'package:json_annotation/json_annotation.dart';
import 'package:pan_scrapper/entities/institution_status.dart';

class InstitutionStatusJsonConverter
    extends JsonConverter<InstitutionStatus, String> {
  const InstitutionStatusJsonConverter();

  @override
  InstitutionStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case "active":
        return InstitutionStatus.active;
      case "inactive":
        return InstitutionStatus.inactive;
      case "soon":
        return InstitutionStatus.soon;
      case "experimental_only":
        return InstitutionStatus.experimentalOnly;
      case "maintanance":
        return InstitutionStatus.maintanance;
      default:
        return InstitutionStatus.unknown;
    }
  }

  @override
  String toJson(InstitutionStatus object) {
    switch (object) {
      case InstitutionStatus.active:
        return "active".toUpperCase();
      case InstitutionStatus.inactive:
        return "disconnected".toUpperCase();
      case InstitutionStatus.soon:
        return "soon".toUpperCase();
      case InstitutionStatus.experimentalOnly:
        return "experimental_only".toUpperCase();
      case InstitutionStatus.maintanance:
        return "maintanance".toUpperCase();
      case InstitutionStatus.unknown:
        return "unknown".toUpperCase();
    }
  }
}
