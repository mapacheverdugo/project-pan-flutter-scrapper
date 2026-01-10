import 'package:pan_scrapper/entities/institution_code.dart';

extension InstitutionCodeExtension on InstitutionCode {
  String get label {
    switch (this) {
      case InstitutionCode.clBciPersonas:
        return 'BCI';
      case InstitutionCode.clSantanderPersonas:
        return 'Santander';
      case InstitutionCode.clScotiabankPersonas:
        return 'Scotiabank';
      case InstitutionCode.clBancoChilePersonas:
        return 'Banco de Chile';
      case InstitutionCode.clItauPersonas:
        return 'Itau';
      case InstitutionCode.clBancoFalabellaPersonas:
        return 'Banco Falabella';
      case InstitutionCode.clBancoEstadoPersonas:
        return 'Banco Estado';
      default:
        return 'Unknown';
    }
  }
}
