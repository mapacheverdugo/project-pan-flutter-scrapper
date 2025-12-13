class ClSantanderPersonasProductIdMetadata {
  final String rawContractId;
  final String rawProductId;
  final String rawSubProductId;
  final String rawCenterId;
  final String? rawEntityId;

  ClSantanderPersonasProductIdMetadata({
    required this.rawContractId,
    required this.rawProductId,
    required this.rawSubProductId,
    required this.rawCenterId,
    this.rawEntityId,
  });
}



