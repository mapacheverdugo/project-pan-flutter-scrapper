enum InstitutionCode {
  clBciPersonas,
  clSantanderPersonas,
  clScotiabankPersonas,
  clBancoChilePersonas,
  clItauPersonas,
  clBancoFalabellaPersonas,
  clBancoEstadoPersonas,
  unknown,
}

extension InstitutionCodeExtension on InstitutionCode {
  /// Returns the minimum sync interval in minutes for this institution.
  /// Returns null for unknown institutions.
  int? get minimumSyncIntervalMinutes {
    switch (this) {
      case InstitutionCode.clSantanderPersonas:
        return 60; // 1 hour
      case InstitutionCode.unknown:
        return null;
      default:
        return 10; // 10 minutes for all other institutions
    }
  }
}
