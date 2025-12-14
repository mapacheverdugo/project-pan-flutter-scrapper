import 'package:pan_scrapper/models/institution.dart';

extension InstitutionExtension on Institution {
  String get label {
    switch (this) {
      case Institution.bci:
        return 'BCI';
      case Institution.santander:
        return 'Santander';
      case Institution.scotiabank:
        return 'Scotiabank';
      case Institution.bancoChile:
        return 'Banco de Chile';
      case Institution.itau:
        return 'Itau';
      case Institution.bancoFalabella:
        return 'Banco Falabella';
    }
  }
}
