import 'package:sleepbalance/core/utils/database_date_utils.dart';

import '../../../../shared/constants/database_constants.dart';

/// Represents a single, continuous phase of sleep within a larger sleep record.
///
/// Each sleep record is composed of multiple sequential phases (e.g., deep, light, REM, wake).
class SleepRecordSleepPhase {
  /// Unique identifier for this sleep phase segment.
  final String id;
  /// Foreign key linking to the parent sleep record.
  final String sleepRecordId;
  /// Foreign key linking to the sleep phase type (e.g., deep, light, REM, wake).
  final int sleepPhaseId;
  /// The exact time this sleep phase began.
  final DateTime startedAt;
  /// The duration of this phase in seconds.
  final int duration;

  /// Creates a new instance of [SleepRecordSleepPhase].
  const SleepRecordSleepPhase({
    required this.id,
    required this.sleepRecordId,
    required this.sleepPhaseId,
    required this.startedAt,
    required this.duration
  });

  /// Converts this [SleepRecordSleepPhase] object into a map for database storage.
  Map<String, dynamic> toDatabase() {
    return {
      SLEEP_RECORD_SLEEP_PHASES_ID: id,
      SLEEP_RECORD_SLEEP_PHASES_STARTED_AT: DatabaseDateUtils.toTimestamp(startedAt),
      SLEEP_RECORD_SLEEP_PHASES_DURATION: duration,
      SLEEP_RECORD_SLEEP_PHASES_SLEEP_PHASE_ID: sleepPhaseId,
      SLEEP_RECORD_SLEEP_PHASES_RECORD_ID: sleepRecordId,
    };
  }

  /// Creates a [SleepRecordSleepPhase] instance from a database row map.
  static SleepRecordSleepPhase fromDatabase(Map<String, dynamic> data) {
    final id = data[SLEEP_RECORD_SLEEP_PHASES_ID] as String;
    final sleepRecordId = data[SLEEP_RECORD_SLEEP_PHASES_RECORD_ID] as String;
    final sleepPhaseId = data[SLEEP_RECORD_SLEEP_PHASES_SLEEP_PHASE_ID] as int;
    final startedAtString = data[SLEEP_RECORD_SLEEP_PHASES_STARTED_AT] as String;
    final startedAt = DateTime.parse(startedAtString);
    final duration = data[SLEEP_RECORD_SLEEP_PHASES_DURATION] as int;

    return SleepRecordSleepPhase(
        id: id,
        sleepRecordId: sleepRecordId,
        sleepPhaseId: sleepPhaseId,
        startedAt: startedAt,
        duration: duration
    );
  }
}
