class ConnectionException implements Exception {
  final ConnectionExceptionType type;
  final Object? originalException;

  /// Creates a new ConnectionException
  ConnectionException(this.type, {this.originalException});

  @override
  String toString() {
    return 'ConnectionException: $type ${originalException?.toString()}';
  }
}

enum ConnectionExceptionType {
  invalidLoginCredentials,
  invalidAuthCredentials,
  authBlocked,
  authCredentialsExpired,
  unknown,
}
