import 'app_error.dart';

/// A sealed class representing the result of an operation.
///
/// It strictly enforces handling of both [Success] and [Failure] cases,
/// promoting safer error handling patterns.
sealed class Result<T> {
  const Result();

  /// Executes [onSuccess] if this is a [Success], or [onFailure] if this is a [Failure].
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(AppError error) onFailure,
  );
}

/// Represents a successful operation containing a value of type [T].
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(AppError error) onFailure,
  ) {
    return onSuccess(value);
  }
}

/// Represents a failed operation containing an [AppError].
class Failure<T> extends Result<T> {
  final AppError error;

  const Failure(this.error);

  @override
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(AppError error) onFailure,
  ) {
    return onFailure(error);
  }
}
