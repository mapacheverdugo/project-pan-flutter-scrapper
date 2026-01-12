import 'package:pan_scrapper/entities/institution_code.dart';

class LocalConnection {
  final String id;
  final InstitutionCode institutionCode;
  final String rawUsername;
  final String password;

  LocalConnection({
    required this.id,
    required this.institutionCode,
    required this.rawUsername,
    required this.password,
  });
}
