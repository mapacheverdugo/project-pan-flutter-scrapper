class PanConnectException implements Exception {
  final PanConnectExceptionType type;
  final Object? originalException;

  PanConnectException(this.type, {this.originalException});

  @override
  String toString() {
    return 'PanConnectException: $type ${originalException?.toString()}';
  }
}

enum PanConnectExceptionType {
  connectionNotFound,
  syncIntervalNotReached,
  syncNotSupported,
  unknown,
}
