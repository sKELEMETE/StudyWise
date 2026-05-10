abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class AuthException extends AppException {
  AuthException(super.message);
}

class AiException extends AppException {
  AiException(super.message);
}

class StorageException extends AppException {
  StorageException(super.message);
}

class ContentExtractionException extends AppException {
  ContentExtractionException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}