abstract class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  final String message;
  final String? code;
  final Object? details;
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException({
    required super.message,
    super.code,
    super.details,
  });
}

class DataUnavailableException extends AppException {
  const DataUnavailableException({
    required super.message,
    super.code,
    super.details,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.details,
  });
}