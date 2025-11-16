import 'package:uuid/uuid.dart';
import '../../../../features/night_review/domain/models/sleep_record.dart';
import '../../domain/exceptions/wearable_exception.dart';

/// Transforms Fitbit API sleep data to SleepRecord domain model
///
/// Handles mapping from Fitbit JSON structure to our internal SleepRecord format.
/// Extracts daily summary metrics from Fitbit's sleep endpoint response.
class FitbitSleepTransformer {
  static const _uuid = Uuid();

  /// Transform Fitbit API response to SleepRecord
  ///
  /// Input: Fitbit API response from /1.2/user/{user-id}/sleep/date/{date}.json
  /// ```json
  /// {
  ///   "sleep": [{
  ///     "dateOfSleep": "2025-11-15",
  ///     "startTime": "2025-11-15T23:15:30.000",
  ///     "endTime": "2025-11-16T07:30:30.000",
  ///     "isMainSleep": true,
  ///     "minutesAsleep": 420,
  ///     "minutesAwake": 12,
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
  /// Returns null if no main sleep record found for the date.
  ///
  /// Throws [WearableException] if data is malformed or missing required fields.
  static SleepRecord? transformSleepData({
    required Map<String, dynamic> fitbitData,
    required String userId,
  }) {
    try {
      // Extract sleep array
      final sleepList = fitbitData['sleep'] as List<dynamic>?;
      if (sleepList == null || sleepList.isEmpty) {
        return null; // No sleep data for this date
      }

      // Find main sleep record (ignore naps)
      final mainSleep = sleepList.firstWhere(
        (sleep) => sleep['isMainSleep'] == true,
        orElse: () => null,
      ) as Map<String, dynamic>?;

      if (mainSleep == null) {
        return null; // No main sleep, only naps
      }

      // Parse required fields
      final dateOfSleep = mainSleep['dateOfSleep'] as String?;
      if (dateOfSleep == null) {
        throw WearableException(
          message: 'Missing required field: dateOfSleep',
          errorType: WearableErrorType.dataTransformation,
        );
      }

      final sleepDate = DateTime.parse(dateOfSleep);
      final startTime = _parseDateTime(mainSleep['startTime'] as String?);
      final endTime = _parseDateTime(mainSleep['endTime'] as String?);
      final minutesAsleep = mainSleep['minutesAsleep'] as int?;
      final minutesAwake = mainSleep['minutesAwake'] as int?;

      // Extract sleep stage durations from levels.summary
      final levels = mainSleep['levels'] as Map<String, dynamic>?;
      final summary = levels?['summary'] as Map<String, dynamic>?;

      final deepMinutes = _extractSleepStageMinutes(summary, 'deep');
      final lightMinutes = _extractSleepStageMinutes(summary, 'light');
      final remMinutes = _extractSleepStageMinutes(summary, 'rem');
      final wakeMinutes = _extractSleepStageMinutes(summary, 'wake');

      // Create SleepRecord
      final now = DateTime.now();
      return SleepRecord(
        id: _uuid.v4(),
        userId: userId,
        sleepDate: sleepDate,
        bedTime: startTime,
        sleepStartTime: startTime,
        sleepEndTime: endTime,
        wakeTime: endTime,
        totalSleepTime: minutesAsleep,
        deepSleepDuration: deepMinutes,
        lightSleepDuration: lightMinutes,
        remSleepDuration: remMinutes,
        awakeDuration: wakeMinutes ?? minutesAwake,
        // Heart rate, HRV, breathing rate not available from sleep endpoint
        // (would require separate API calls - deferred to future phase)
        avgHeartRate: null,
        minHeartRate: null,
        maxHeartRate: null,
        avgHrv: null,
        avgHeartRateVariability: null,
        avgBreathingRate: null,
        // Quality rating/notes are user-entered, not from Fitbit
        qualityRating: null,
        qualityNotes: null,
        dataSource: 'fitbit',
        createdAt: now,
        updatedAt: now,
      );
    } catch (e, stackTrace) {
      if (e is WearableException) {
        rethrow;
      }

      throw WearableException(
        message: 'Failed to transform Fitbit sleep data: $e',
        errorType: WearableErrorType.dataTransformation,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Parse ISO 8601 datetime string to DateTime
  ///
  /// Returns null if string is null or invalid.
  static DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return null;

    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      // Invalid datetime format - return null rather than throw
      // (allows partial data import)
      return null;
    }
  }

  /// Extract sleep stage minutes from Fitbit levels.summary
  ///
  /// Example:
  /// ```json
  /// {
  ///   "deep": {"count": 3, "minutes": 88, "thirtyDayAvgMinutes": 62}
  /// }
  /// ```
  ///
  /// Returns null if stage data not found.
  static int? _extractSleepStageMinutes(
    Map<String, dynamic>? summary,
    String stage,
  ) {
    if (summary == null) return null;

    final stageData = summary[stage] as Map<String, dynamic>?;
    if (stageData == null) return null;

    return stageData['minutes'] as int?;
  }
}
