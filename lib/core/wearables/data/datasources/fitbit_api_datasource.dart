import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../domain/exceptions/wearable_exception.dart';

/// Data source for Fitbit Web API calls
///
/// Uses raw Dio HTTP client to fetch sleep summary data from Fitbit.
/// We use direct API calls instead of fitbitter's data manager because:
/// - fitbitter returns granular 30-second interval data
/// - We need daily summary data (total sleep, deep/light/REM durations)
class FitbitApiDataSource {
  /// Creates a Fitbit API data source
  FitbitApiDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const String _baseUrl = 'https://api.fitbit.com/1.2';

  /// Fetch sleep data for a single date
  ///
  /// Calls: GET /1.2/user/{user-id}/sleep/date/{date}.json
  ///
  /// Returns raw JSON response containing sleep records for the specified date.
  /// Response structure:
  /// ```json
  /// {
  ///   "sleep": [{
  ///     "dateOfSleep": "2025-11-15",
  ///     "startTime": "2025-11-15T23:15:30.000",
  ///     "endTime": "2025-11-16T07:30:30.000",
  ///     "minutesAsleep": 420,
  ///     "levels": {
  ///       "summary": {
  ///         "deep": {"minutes": 88},
  ///         "light": {"minutes": 240},
  ///         "rem": {"minutes": 92},
  ///         "wake": {"minutes": 12}
  ///       }
  ///     }
  ///   }]
  /// }
  /// ```
  ///
  /// Throws [WearableException] on errors:
  /// - authentication: 401 Unauthorized (token expired/invalid)
  /// - rateLimited: 429 Too Many Requests
  /// - network: Connection timeout, DNS failure
  /// - unknown: 5xx server errors, unexpected responses
  Future<Map<String, dynamic>> fetchSleepData({
    required String userId,
    required String accessToken,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final url = '$_baseUrl/user/$userId/sleep/date/$dateStr.json';

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e, stackTrace) {
      throw _handleDioException(e, stackTrace);
    } catch (e, stackTrace) {
      throw WearableException(
        message: 'Unexpected error fetching Fitbit sleep data: $e',
        errorType: WearableErrorType.unknown,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch sleep data for a date range
  ///
  /// Makes multiple API calls (one per date) and aggregates results.
  /// Fitbit API does not support range queries for sleep data, so we
  /// must fetch each date individually.
  ///
  /// Returns list of daily sleep data responses.
  ///
  /// Throws [WearableException] on any API call failure.
  Future<List<Map<String, dynamic>>> fetchSleepDataRange({
    required String userId,
    required String accessToken,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = <Map<String, dynamic>>[];
    var currentDate = startDate;

    while (!currentDate.isAfter(endDate)) {
      try {
        final data = await fetchSleepData(
          userId: userId,
          accessToken: accessToken,
          date: currentDate,
        );
        results.add(data);
      } catch (e) {
        // Re-throw the exception - caller decides whether to fail fast
        // or continue with partial data
        rethrow;
      }

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return results;
  }

  /// Convert DioException to WearableException with appropriate error type
  WearableException _handleDioException(
    DioException e,
    StackTrace stackTrace,
  ) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;

      switch (statusCode) {
        case 401:
          return WearableException(
            message: 'Fitbit authentication failed. Token may be expired.',
            errorType: WearableErrorType.authentication,
            originalError: e,
            stackTrace: stackTrace,
          );

        case 429:
          return WearableException(
            message: 'Fitbit API rate limit exceeded. Try again later.',
            errorType: WearableErrorType.rateLimited,
            originalError: e,
            stackTrace: stackTrace,
          );

        case 500:
        case 502:
        case 503:
        case 504:
          return WearableException(
            message: 'Fitbit server error. Try again later.',
            errorType: WearableErrorType.network,
            originalError: e,
            stackTrace: stackTrace,
          );

        default:
          return WearableException(
            message:
                'Fitbit API error (HTTP $statusCode): ${e.response!.data}',
            errorType: WearableErrorType.unknown,
            originalError: e,
            stackTrace: stackTrace,
          );
      }
    }

    // Network errors (timeout, connection refused, DNS failure)
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return WearableException(
        message: 'Network error connecting to Fitbit: ${e.message}',
        errorType: WearableErrorType.network,
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    // Unknown error
    return WearableException(
      message: 'Unexpected Fitbit API error: ${e.message}',
      errorType: WearableErrorType.unknown,
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}
