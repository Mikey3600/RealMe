
/// Represents a standardized application error.
///
/// Use this class to propagate error details across layers without
/// exposing internal exceptions or stack traces to the UI directly.
class AppError {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError(message: $message, code: $code)';
}
