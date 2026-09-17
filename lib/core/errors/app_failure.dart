/// Base failure class representing a domain or infrastructure failure.
sealed class AppFailure {
  final String message;
  final String? technicalDetails;

  const AppFailure(this.message, {this.technicalDetails});

  @override
  String toString() => technicalDetails != null
      ? '$message ($technicalDetails)'
      : message;
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, {super.technicalDetails});
}

class ValidationFailure extends AppFailure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(super.message, {this.fieldErrors, super.technicalDetails});
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message, {super.technicalDetails});
}

class SecurityFailure extends AppFailure {
  const SecurityFailure(super.message, {super.technicalDetails});
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.technicalDetails});
}

class ConflictFailure extends AppFailure {
  const ConflictFailure(super.message, {super.technicalDetails});
}
