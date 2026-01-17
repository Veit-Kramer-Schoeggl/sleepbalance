import 'package:sleepbalance/features/night_review/domain/models/sleep_record_sleep_phase.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';
import 'package:uuid/data.dart';
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
      Map<String, dynamic>? mainSleep;
      for (final sleep in sleepList) {
        if (sleep is Map<String, dynamic> && sleep['isMainSleep'] == true) {
          mainSleep = sleep;
          break;
        }
      }

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

  /// Transforms the detailed sleep phase data from the Fitbit API response.
  ///
  /// Extracts the `levels.data` array from the main sleep entry, which contains
  /// a granular timeline of sleep stages (deep, light, rem, wake). Each segment
  /// in the timeline is then transformed into a [SleepRecordSleepPhase] object.
  ///
  /// Returns an empty list if no main sleep or no level data is found.
  static List<SleepRecordSleepPhase> transformSleepPhases(
      Map<String, dynamic> fitbitData,
      String sleepRecordId
    ) {
    final sleep = fitbitData['sleep'] as List<dynamic>?;
    final mainSleep = sleep?.firstWhere(
      (s) => s['isMainSleep'] == true,
      orElse: () => null
    );

    if (mainSleep == null) {
      return [];
    }

    final data = mainSleep['levels']?['data'] as List<dynamic>?;

    if (data == null || data.isEmpty) {
      return [];
    }

    final sleepPhases = data
        .map((d) => _extractSleepPhase(d, sleepRecordId))
        .whereType<SleepRecordSleepPhase>()
        .toList();

    return sleepPhases;
  }

  /// Extracts a single sleep phase from a Fitbit data segment.
  ///
  /// Maps the Fitbit `level` string (e.g., 'deep') to a local `sleepPhaseId`
  /// and creates a time-sortable UUID v7 for the record ID.
  ///
  /// Returns null if any of the required fields (`seconds`, `dateTime`, `level`) are missing.
  static SleepRecordSleepPhase? _extractSleepPhase(
    Map<String, dynamic> data,
    String sleepRecordId
  ) {
    final duration = data['seconds'] as int?;
    final start = data['dateTime'] as String?;
    final level = data['level'] as String?;

    if (duration == null || start == null || level == null) {
      return null;
    }

    final startedAt = DateTime.parse(start);

    final sleepPhaseId = switch (level) {
      'deep' => SLEEP_PHASE_DEEP,
      'light' => SLEEP_PHASE_LIGHT,
      'rem' => SLEEP_PHASE_REM,
      'wake' => SLEEP_PHASE_WAKE,
      _ => throw Exception("Sleep phase $level not implemented!")
    };

    final v7Options = V7Options(startedAt.millisecondsSinceEpoch, null);

    return SleepRecordSleepPhase(
      id: _uuid.v7(config: v7Options),
      sleepRecordId: sleepRecordId,
      sleepPhaseId: sleepPhaseId,
      startedAt: startedAt,
      duration: duration
    );
  }

}
