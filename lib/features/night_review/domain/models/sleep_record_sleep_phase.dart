import 'package:sleepbalance/core/utils/database_date_utils.dart';

import '../../../../shared/constants/database_constants.dart';

class SleepRecordSleepPhase {
  final String id;
  final String sleepRecordId;
  final int sleepPhaseId;
  final DateTime startedAt;
  final int duration;

  const SleepRecordSleepPhase({
    required this.id,
    required this.sleepRecordId,
    required this.sleepPhaseId,
    required this.startedAt,
    required this.duration
  });

  Map<String, dynamic> toDatabase() {
    return {
      SLEEP_RECORD_SLEEP_PHASES_ID: id,
      SLEEP_RECORD_SLEEP_PHASES_STARTED_AT: DatabaseDateUtils.toTimestamp(startedAt),
      SLEEP_RECORD_SLEEP_PHASES_DURATION: duration,
      SLEEP_RECORD_SLEEP_PHASES_SLEEP_PHASE_ID: sleepPhaseId,
      SLEEP_RECORD_SLEEP_PHASES_RECORD_ID: sleepRecordId,
    };
  }

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