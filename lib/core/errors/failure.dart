/// Generic failure object for handling errors cleanly across the app.
class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}
