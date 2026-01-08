import 'dart:ui';

enum Institution {
  bci,
  santander,
  scotiabank,
  bancoChile,
  itau,
  bancoFalabella,
  bancoEstado,
  bancoBice,
  bancoEdwards,
  bancoSecurity,
  fintual,
  tenpo,
}

extension InstitutionExtension on Institution {
  String get id => switch (this) {
    Institution.bci => 'cl_bci_personas',
    Institution.santander => 'cl_banco_santander_personas',
    Institution.scotiabank => 'cl_scotiabank_personas',
    Institution.bancoChile => 'cl_banco_chile_personas',
    Institution.itau => 'cl_banco_itau_personas',
    Institution.bancoFalabella => 'cl_banco_falabella_personas',
    Institution.bancoEstado => 'cl_banco_estado_personas',
    Institution.bancoBice => 'cl_banco_bice_personas',
    Institution.bancoEdwards => 'cl_banco_edwards_personas',
    Institution.bancoSecurity => 'cl_banco_security_personas',
    Institution.fintual => 'cl_fintual',
    Institution.tenpo => 'cl_tenpo_personas',
  };

  String get country => switch (this) {
    Institution.bci => 'CL',
    Institution.santander => 'CL',
    Institution.scotiabank => 'CL',
    Institution.bancoChile => 'CL',
    Institution.itau => 'CL',
    Institution.bancoFalabella => 'CL',
    Institution.bancoEstado => 'CL',
    Institution.bancoBice => 'CL',
    Institution.bancoEdwards => 'CL',
    Institution.bancoSecurity => 'CL',
    Institution.fintual => 'CL',
    Institution.tenpo => 'CL',
  };

  String get name => switch (this) {
    Institution.bci => 'Bci',
    Institution.santander => 'Banco Santander',
    Institution.scotiabank => 'Scotiabank',
    Institution.bancoChile => 'Banco de Chile',
    Institution.itau => 'Banco Itaú',
    Institution.bancoFalabella => 'Banco Falabella',
    Institution.bancoEstado => 'Banco Estado',
    Institution.bancoBice => 'Banco BICE',
    Institution.bancoEdwards => 'Banco Edwards',
    Institution.bancoSecurity => 'Banco Security',
    Institution.fintual => 'Fintual',
    Institution.tenpo => 'Tenpo',
  };

  String get logoPositiveUrl => switch (this) {
    Institution.bci =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbci%2Flogo.svg?alt=media',
    Institution.santander =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fsantander%2Flogo.svg?alt=media',
    Institution.scotiabank =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fscotiabank%2Flogo.svg?alt=media',
    Institution.bancoChile =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-chile%2Flogo.svg?alt=media',
    Institution.itau =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-itau%2Flogo.svg?alt=media',
    Institution.bancoFalabella =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-falabella%2Flogo.svg?alt=media',
    Institution.bancoEstado =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-estado%2Flogo.svg?alt=media',
    Institution.bancoBice =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-bice%2Flogo.svg?alt=media',
    Institution.bancoEdwards =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-edwards%2Flogo.svg?alt=media',
    Institution.bancoSecurity =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-security%2Flogo.svg?alt=media',
    Institution.fintual =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ffintual%2Flogo.svg?alt=media',
    Institution.tenpo =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ftenpo%2Flogo.svg?alt=media',
  };

  String get logoNegativeUrl => switch (this) {
    Institution.bci =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbci%2Flogo_negative.svg?alt=media',
    Institution.santander =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fsantander%2Flogo_negative.svg?alt=media',
    Institution.scotiabank =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fscotiabank%2Flogo_negative.svg?alt=media',
    Institution.bancoChile =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-chile%2Flogo_negative.svg?alt=media',
    Institution.itau =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-itau%2Flogo_negative.svg?alt=media',
    Institution.bancoFalabella =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-falabella%2Flogo_negative.svg?alt=media',
    Institution.bancoEstado =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-estado%2Flogo_negative.svg?alt=media',
    Institution.bancoBice =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-bice%2Flogo_negative.svg?alt=media',
    Institution.bancoEdwards =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-edwards%2Flogo_negative.svg?alt=media',
    Institution.bancoSecurity =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-security%2Flogo_negative.svg?alt=media',
    Institution.fintual =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ffintual%2Flogo_negative.svg?alt=media',
    Institution.tenpo =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ftenpo%2Flogo_negative.svg?alt=media',
  };

  String get iconPositiveUrl => switch (this) {
    Institution.bci =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbci%2Ficon.svg?alt=media',
    Institution.santander =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fsantander%2Ficon.svg?alt=media',
    Institution.scotiabank =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fscotiabank%2Ficon.svg?alt=media',
    Institution.bancoChile =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-chile%2Ficon.svg?alt=media',
    Institution.itau =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-itau%2Ficon.svg?alt=media',
    Institution.bancoFalabella =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-falabella%2Ficon.svg?alt=media',
    Institution.bancoEstado =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-estado%2Ficon.svg?alt=media',
    Institution.bancoBice =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-bice%2Ficon.svg?alt=media',
    Institution.bancoEdwards =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-edwards%2Ficon.svg?alt=media',
    Institution.bancoSecurity =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-security%2Ficon.svg?alt=media',
    Institution.fintual =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ffintual%2Ficon.svg?alt=media',
    Institution.tenpo =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ftenpo%2Ficon.svg?alt=media',
  };

  String get iconNegativeUrl => switch (this) {
    Institution.bci =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbci%2Ficon_negative.svg?alt=media',
    Institution.santander =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fsantander%2Ficon_negative.svg?alt=media',
    Institution.scotiabank =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fscotiabank%2Ficon_negative.svg?alt=media',
    Institution.bancoChile =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-chile%2Ficon_negative.svg?alt=media',
    Institution.itau =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-itau%2Ficon_negative.svg?alt=media',
    Institution.bancoFalabella =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-falabella%2Ficon_negative.svg?alt=media',
    Institution.bancoEstado =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-estado%2Ficon_negative.svg?alt=media',
    Institution.bancoBice =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-bice%2Ficon_negative.svg?alt=media',
    Institution.bancoEdwards =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-edwards%2Ficon_negative.svg?alt=media',
    Institution.bancoSecurity =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-security%2Ficon_negative.svg?alt=media',
    Institution.fintual =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ffintual%2Ficon_negative.svg?alt=media',
    Institution.tenpo =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ftenpo%2Ficon_negative.svg?alt=media',
  };

  String? get iconAltUrl => switch (this) {
    Institution.bci => null,
    Institution.santander => null,
    Institution.scotiabank => null,
    Institution.bancoChile => null,
    Institution.itau => null,
    Institution.bancoFalabella =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Fbanco-falabella%2Ficon_alt.svg?alt=media',
    Institution.bancoEstado => '',
    Institution.bancoBice => null,
    Institution.bancoEdwards => null,
    Institution.bancoSecurity => null,
    Institution.fintual =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ffintual%2Ficon_alt.svg?alt=media',
    Institution.tenpo =>
      'https://firebasestorage.googleapis.com/v0/b/project-pan-5074b.firebasestorage.app/o/institution-assets%2Ftenpo%2Ficon_alt.svg?alt=media',
  };

  String get suggestedIconOnMainColor => switch (this) {
    Institution.bci => 'iconPositive',
    Institution.santander => 'iconNegative',
    Institution.scotiabank => 'iconNegative',
    Institution.bancoChile => 'iconNegative',
    Institution.itau => 'iconNegative',
    Institution.bancoFalabella => 'iconAlt',
    Institution.bancoEstado => 'iconPositive',
    Institution.bancoBice => 'iconNegative',
    Institution.bancoEdwards => 'iconNegative',
    Institution.bancoSecurity => 'iconNegative',
    Institution.fintual => 'iconPositive',
    Institution.tenpo => 'iconAlt',
  };

  String get _primaryColorString => switch (this) {
    Institution.bci => '#2C70B8',
    Institution.santander => '#ec0000',
    Institution.scotiabank => '#ec111a',
    Institution.bancoChile => '#173a79',
    Institution.itau => '#ff6200',
    Institution.bancoFalabella => '#007937',
    Institution.bancoEstado => '#ff6b00',
    Institution.bancoBice => '#326295',
    Institution.bancoEdwards => '#078F80',
    Institution.bancoSecurity => '#6a2e92',
    Institution.fintual => '#005ad6',
    Institution.tenpo => '#03ff94',
  };

  Color get primaryColor => Color(
    int.parse(_primaryColorString.substring(1), radix: 16) + 0xFF000000,
  );

  String get website => switch (this) {
    Institution.bci => 'https://www.bci.cl',
    Institution.santander => 'https://www.santander.cl',
    Institution.scotiabank => 'https://www.scotiabank.cl',
    Institution.bancoChile => 'https://www.bancochile.cl',
    Institution.itau => 'https://www.itau.cl',
    Institution.bancoFalabella => 'https://www.bancofalabella.cl',
    Institution.bancoEstado => 'https://www.bancoestado.cl',
    Institution.bancoBice => 'https://www.bice.cl',
    Institution.bancoEdwards => 'https://www.bancoedwards.cl',
    Institution.bancoSecurity => 'https://www.security.cl',
    Institution.fintual => 'https://www.fintual.cl',
    Institution.tenpo => 'https://www.tenpo.cl',
  };

  String get _mainColorString => switch (this) {
    Institution.bci => '#ffffff',
    Institution.santander => '#ec0000',
    Institution.scotiabank => '#ec111a',
    Institution.bancoChile => '#173a79',
    Institution.itau => '#ff6200',
    Institution.bancoFalabella => '#154734',
    Institution.bancoEstado => '#ff6b00',
    Institution.bancoBice => '#326295',
    Institution.bancoEdwards => '#078F80',
    Institution.bancoSecurity => '#6a2e92',
    Institution.fintual => '#ffffff',
    Institution.tenpo => '#000000',
  };

  Color get mainColor =>
      Color(int.parse(_mainColorString.substring(1), radix: 16) + 0xFF000000);

  bool get hasServiceInstitution => switch (this) {
    Institution.bci => true,
    Institution.santander => false,
    Institution.scotiabank => true,
    Institution.bancoChile => true,
    Institution.itau => false,
    Institution.bancoFalabella => false,
    Institution.bancoEstado => false,
    Institution.bancoBice => false,
    Institution.bancoEdwards => false,
    Institution.bancoSecurity => false,
    Institution.fintual => false,
    Institution.tenpo => false,
  };

  // Convenience getter for iconUrl (used in widgets)
  String? get iconUrl => iconPositiveUrl;
}
