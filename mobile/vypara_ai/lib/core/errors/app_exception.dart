sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class StorageException extends AppException {
  const StorageException(super.message);
}

class UnknownException extends AppException {
  const UnknownException(super.message);
}
