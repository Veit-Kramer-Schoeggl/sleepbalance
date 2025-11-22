/// Error types for wearable-related operations
enum WearableErrorType {
  /// Authentication errors (expired token, invalid credentials)
  authentication,

  /// Network connectivity issues
  network,

  /// API rate limiting
  rateLimited,

  /// Data transformation/parsing errors
  dataTransformation,

  /// Unknown or unclassified errors
  unknown,
}

/// Exception thrown during wearable operations (OAuth, sync, API calls)
class WearableException implements Exception {
  /// Creates a wearable exception
  WearableException({
    required this.message,
    required this.errorType,
    this.originalError,
    this.stackTrace,
  });

  /// Human-readable error message
  final String message;

  /// Classification of the error
  final WearableErrorType errorType;

  /// Original exception that caused this error (if any)
  final dynamic originalError;

  /// Stack trace at the point of error
  final StackTrace? stackTrace;

  /// Whether this error can be retried
  ///
  /// Authentication and network errors are typically retryable,
  /// while data transformation errors are not.
  bool get isRetryable {
    switch (errorType) {
      case WearableErrorType.authentication:
      case WearableErrorType.network:
      case WearableErrorType.rateLimited:
        return true;
      case WearableErrorType.dataTransformation:
      case WearableErrorType.unknown:
        return false;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('WearableException: $message');
    if (originalError != null) {
      buffer.write(' (Original: $originalError)');
    }
    return buffer.toString();
  }
}
