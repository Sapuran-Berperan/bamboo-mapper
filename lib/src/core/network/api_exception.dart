sealed class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ValidationException extends ApiException {
  const ValidationException(super.message, this.fieldErrors, [super.statusCode]);

  final Map<String, String> fieldErrors;

  @override
  String toString() =>
      'ValidationException: $message, fields: $fieldErrors (status: $statusCode)';
}

class ConflictException extends ApiException {
  const ConflictException(super.message, [super.statusCode = 409]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, [super.statusCode = 401]);
}

class ServerException extends ApiException {
  const ServerException(super.message, [super.statusCode = 500]);
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'Tidak dapat terhubung ke server']);
}
