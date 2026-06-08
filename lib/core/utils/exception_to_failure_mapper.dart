import '../errors/failure.dart';
import '../exceptions/app_exception.dart';

Failure mapExceptionToFailure(Object exception) {
  if (exception is PermissionDeniedException) {
    return PermissionFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  if (exception is DataUnavailableException) {
    return DataUnavailableFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  if (exception is ValidationException) {
    return ValidationFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  return UnexpectedFailure(
    message: 'Unexpected error occurred',
    details: exception,
  );
}