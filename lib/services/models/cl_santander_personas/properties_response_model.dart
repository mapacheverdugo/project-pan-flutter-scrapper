class ClSantanderPersonasPropertiesResponseModel {
  final String _usuarioAlt;
  final String _canal;
  final String _canalFisico;
  final String _canalLogico;
  final String _infoDispositivo;
  final String _nroSer;
  final String _xSantanderClientId;

  ClSantanderPersonasPropertiesResponseModel._({
    required String usuarioAlt,
    required String canal,
    required String canalFisico,
    required String canalLogico,
    required String infoDispositivo,
    required String nroSer,
    required String xSantanderClientId,
  }) : _usuarioAlt = usuarioAlt,
       _canal = canal,
       _canalFisico = canalFisico,
       _canalLogico = canalLogico,
       _infoDispositivo = infoDispositivo,
       _nroSer = nroSer,
       _xSantanderClientId = xSantanderClientId;

  factory ClSantanderPersonasPropertiesResponseModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ClSantanderPersonasPropertiesResponseModel._(
      usuarioAlt: map['USUARIO_ALT'] as String? ?? '',
      canal: map['CANAL'] as String? ?? '',
      canalFisico: map['CANAL_FISICO'] as String? ?? '',
      canalLogico: map['CANAL_LOGICO'] as String? ?? '',
      infoDispositivo: map['INFO_DISPOSITIVO'] as String? ?? '',
      nroSer: map['NRO_SER'] as String? ?? '',
      xSantanderClientId: map['X_SANTANDER_CLIENT_ID'] as String? ?? '',
    );
  }

  String get usuarioAlt => _usuarioAlt;
  String get canal => _canal;
  String get canalFisico => _canalFisico;
  String get canalLogico => _canalLogico;
  String get infoDispositivo => _infoDispositivo;
  String get nroSer => _nroSer;
  String get xSantanderClientId => _xSantanderClientId;
}







