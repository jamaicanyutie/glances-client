/// Thrown whenever a request against the Glances REST API fails.
///
/// Carries the HTTP [statusCode] when the failure came from a non-2xx
/// response, and a human-readable [message] describing what went wrong.
/// The message is also intended to be surfaced directly in the UI, so it
/// should read as a complete sentence.
class ApiException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  /// HTTP status code of the failing response, when available.
  final int? statusCode;

  /// Creates an [ApiException].
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode == null) {
      return 'ApiException: $message';
    }
    return 'ApiException ($statusCode): $message';
  }
}
