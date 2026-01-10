import 'package:pan_scrapper/entities/institution_code.dart';

class LinkIntent {
  final String linkWidgetToken;
  final String mode;
  final String? webhookUrl;
  final String? country;
  final DateTime? expiresAt;
  final InstitutionCode? preselectedInstitutionCode;
  final bool? enableExperimentalInstitutions;
  final PrefilledUsername? prefilledUsername;
  final String? taskId;
  final String? clientName;

  const LinkIntent({
    required this.linkWidgetToken,
    required this.mode,
    this.webhookUrl,
    this.country,
    this.expiresAt,
    this.preselectedInstitutionCode,
    this.enableExperimentalInstitutions,
    this.prefilledUsername,
    this.taskId,
    this.clientName,
  });
}

class PrefilledUsername {
  final String username;
  final bool mandatory;

  PrefilledUsername({required this.username, required this.mandatory});
}
