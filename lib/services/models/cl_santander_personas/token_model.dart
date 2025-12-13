class ClSantanderPersonasTokenModel {
  final Map<String, dynamic> crucedeProducto;
  final String tokenJwt;
  final String accessToken;

  ClSantanderPersonasTokenModel({
    required this.crucedeProducto,
    required this.tokenJwt,
    required this.accessToken,
  });

  factory ClSantanderPersonasTokenModel.fromMap(Map<String, dynamic> json) {
    return ClSantanderPersonasTokenModel(
      crucedeProducto: json['CrucedeProducto'] as Map<String, dynamic>,
      tokenJwt: json['tokenJWT'] as String,
      accessToken: json['access_token'] as String? ?? '',
    );
  }
}
