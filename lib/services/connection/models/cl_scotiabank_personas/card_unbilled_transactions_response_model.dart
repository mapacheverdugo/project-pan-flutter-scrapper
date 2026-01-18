class ClScotiabankPersonasCardUnbilledTransactionsResponseModel {
  ClScotiabankPersonasCardUnbilledTransactionsResponseModel({
    required this.lstUltimosMovVisaEnc,
  });

  final ClScotiabankPersonasLstUltimosMovVisaEnc lstUltimosMovVisaEnc;

  factory ClScotiabankPersonasCardUnbilledTransactionsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClScotiabankPersonasCardUnbilledTransactionsResponseModel(
      lstUltimosMovVisaEnc:
          ClScotiabankPersonasLstUltimosMovVisaEnc.fromJson(
        json['lstUltimosMovVisaEnc'] as Map<String, dynamic>,
      ),
    );
  }
}

class ClScotiabankPersonasLstUltimosMovVisaEnc {
  ClScotiabankPersonasLstUltimosMovVisaEnc({
    required this.gdesc,
    required this.ntar,
    required this.vtrs,
    required this.visnac,
    required this.svmonori,
    required this.rellamado,
    required this.fant,
    required this.nreg,
    required this.visint,
    required this.haymas,
    required this.gciu,
    required this.svtrs,
    required this.cpais,
    required this.gtipo,
    required this.fsig,
    required this.vmonori,
    required this.ftrs,
  });

  final List<String> gdesc;
  final String ntar;
  final List<String> vtrs;
  final String visnac;
  final List<String> svmonori;
  final String rellamado;
  final String fant;
  final String nreg;
  final String visint;
  final String haymas;
  final List<String> gciu;
  final List<String> svtrs;
  final List<String> cpais;
  final List<String> gtipo;
  final String fsig;
  final List<String> vmonori;
  final List<String> ftrs;

  factory ClScotiabankPersonasLstUltimosMovVisaEnc.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClScotiabankPersonasLstUltimosMovVisaEnc(
      gdesc: (json['gdesc'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ntar: json['ntar'] as String? ?? '',
      vtrs: (json['vtrs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      visnac: json['visnac'] as String? ?? '',
      svmonori: (json['svmonori'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rellamado: json['rellamado'] as String? ?? '',
      fant: json['fant'] as String? ?? '',
      nreg: json['nreg'] as String? ?? '',
      visint: json['visint'] as String? ?? '',
      haymas: json['haymas'] as String? ?? '',
      gciu: (json['gciu'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      svtrs: (json['svtrs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cpais: (json['cpais'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      gtipo: (json['gtipo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fsig: json['fsig'] as String? ?? '',
      vmonori: (json['vmonori'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ftrs: (json['ftrs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
