/// Custom exception hierarchy for CareSync.
///
/// Centralised exceptions allow consistent error handling across the app
/// without leaking raw server messages to the UI.

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Generic API Exception used by service layer.
class ApiException extends AppException {
  final int? code;
  const ApiException({required String message, this.code, int? statusCode})
      : super(message, statusCode: statusCode ?? code);
}

/// Thrown when the device has no network connectivity.
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection. Please check your network.'])
      : super(message);
}

/// Thrown when the server returns 401 or credentials are invalid.
class AuthenticationException extends AppException {
  const AuthenticationException([String message = 'Invalid email or password.'])
      : super(message, statusCode: 401);
}

/// Thrown when the server returns 400 or input validation fails.
class ValidationException extends AppException {
  const ValidationException(super.message) : super(statusCode: 400);
}

/// Thrown when the server returns 404.
class NotFoundException extends AppException {
  const NotFoundException([String message = 'The requested resource was not found.'])
      : super(message, statusCode: 404);
}

/// Thrown when the server returns 500 or an unexpected error occurs.
class ServerException extends AppException {
  const ServerException([String message = 'Something went wrong. Please try again later.'])
      : super(message, statusCode: 500);
}

/// Thrown when an HTTP request times out.
class TimeoutException extends AppException {
  const TimeoutException([String message = 'Request timed out. Please try again.'])
      : super(message);
}
