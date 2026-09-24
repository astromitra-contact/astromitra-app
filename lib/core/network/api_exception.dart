/// Thrown by [ApiClient] for any non-2xx response or network-level
/// failure. Carries the backend's own error `code` (e.g.
/// `QUESTION_LIMIT_REACHED`, `KUNDLI_NOT_FOUND`, `PLACE_NOT_FOUND`) through
/// to the UI layer, so screens can react to *specific* backend conditions
/// (e.g. show the rewarded-ad option on `QUESTION_LIMIT_REACHED`) rather
/// than just a generic failure.
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final bool isNetworkError;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.isNetworkError = false,
  });

  factory ApiException.network(String message) =>
      ApiException(message: message, isNetworkError: true);

  factory ApiException.timeout() => const ApiException(
        message: 'The request took too long to respond. Please check your connection and try again.',
        isNetworkError: true,
      );

  @override
  String toString() => message;
}
