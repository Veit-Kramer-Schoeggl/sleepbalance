import 'package:sleepbalance/features/night_review/domain/models/sleep_record_sleep_phase.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/database_date_utils.dart';
import '../../../../shared/constants/database_constants.dart';
import '../../domain/models/sleep_baseline.dart';
import '../../domain/models/sleep_record.dart';

/// Sleep Record Local Data Source
///
/// Handles SQLite operations for sleep records and baselines.
/// Provides low-level database access methods.
///
/// Responsibilities:
/// - Execute SQL queries for sleep records
/// - Convert database rows to domain models
/// - Handle date conversions for SQLite storage
class SleepRecordLocalDataSource {
  final Database database;

  SleepRecordLocalDataSource({required this.database});

  /// Gets sleep record by date
  ///
  /// Queries sleep_records table for a specific user and date.
  /// Returns null if no record found.
  Future<SleepRecord?> getRecordByDate(String userId, DateTime date) async {
    final dateString = DatabaseDateUtils.toDateString(date);

    final results = await database.query(
      TABLE_SLEEP_RECORDS,
      where: '$SLEEP_RECORDS_USER_ID = ? AND $SLEEP_RECORDS_SLEEP_DATE = ?',
      whereArgs: [userId, dateString],
    );

    if (results.isEmpty) {
      return null;
    }

    return SleepRecord.fromDatabase(results.first);
  }

  /// Gets sleep records by date range
  ///
  /// Queries sleep_records table for records between start and end dates (inclusive).
  /// Results are ordered by sleep_date descending (newest first).
  Future<List<SleepRecord>> getRecordsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final startString = DatabaseDateUtils.toDateString(start);
    final endString = DatabaseDateUtils.toDateString(end);

    final results = await database.query(
      TABLE_SLEEP_RECORDS,
      where: '$SLEEP_RECORDS_USER_ID = ? AND $SLEEP_RECORDS_SLEEP_DATE BETWEEN ? AND ?',
      whereArgs: [userId, startString, endString],
      orderBy: '$SLEEP_RECORDS_SLEEP_DATE DESC',
    );

    return results.map((row) => SleepRecord.fromDatabase(row)).toList();
  }

  /// Inserts a new sleep record
  ///
  /// Uses INSERT OR REPLACE to handle cases where record already exists.
  /// This allows upsert (insert or update) behavior.
  Future<void> insertRecord(SleepRecord record) async {
    await database.insert(
      TABLE_SLEEP_RECORDS,
      record.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertSleepPhase(SleepRecordSleepPhase sleepPhase) async {
    await database.insert(
      TABLE_SLEEP_RECORD_SLEEP_PHASES,
      sleepPhase.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<void> clearPhasesForRecord(String sleepRecordId) async {
    await database.delete(
      TABLE_SLEEP_RECORD_SLEEP_PHASES,
      where: '$SLEEP_RECORD_SLEEP_PHASES_RECORD_ID = ?',
      whereArgs: [sleepRecordId]
    );
  }

  Future<List<SleepRecordSleepPhase>> getSleepPhasesForRecord(String sleepRecordId) async {
    final data = await database.query(
      TABLE_SLEEP_RECORD_SLEEP_PHASES,
      where: '$SLEEP_RECORD_SLEEP_PHASES_RECORD_ID = ?',
      whereArgs: [sleepRecordId]
    );

    return data.map(SleepRecordSleepPhase.fromDatabase).toList();
  }

  /// Updates an existing sleep record
  ///
  /// Updates the record with the matching ID.
  Future<void> updateRecord(SleepRecord record) async {
    await database.update(
      TABLE_SLEEP_RECORDS,
      record.toDatabase(),
      where: '$SLEEP_RECORDS_ID = ?',
      whereArgs: [record.id],
    );
  }

  /// Deletes a sleep record
  ///
  /// Permanently removes the record from the database.
  Future<void> deleteRecord(String recordId) async {
    await database.delete(
      TABLE_SLEEP_RECORDS,
      where: '$SLEEP_RECORDS_ID = ?',
      whereArgs: [recordId],
    );
  }

  /// Updates quality rating fields only
  ///
  /// Efficiently updates just the quality rating and notes
  /// without fetching and updating the entire record.
  Future<void> updateQualityFields(
    String recordId,
    String rating,
    String? notes,
  ) async {
    await database.update(
      TABLE_SLEEP_RECORDS,
      {
        SLEEP_RECORDS_QUALITY_RATING: rating,
        SLEEP_RECORDS_QUALITY_NOTES: notes,
        SLEEP_RECORDS_UPDATED_AT: DatabaseDateUtils.toTimestamp(DateTime.now()),
      },
      where: '$SLEEP_RECORDS_ID = ?',
      whereArgs: [recordId],
    );
  }

  Future<Map<DateTime, String?>> getQualityForRange(
      String userId,
      DateTime from,
      DateTime to,
      ) async {
    final startString = DatabaseDateUtils.toDateString(from);
    final endString = DatabaseDateUtils.toDateString(to);

    final results = await database.query(
      TABLE_SLEEP_RECORDS,
      columns: [SLEEP_RECORDS_SLEEP_DATE, SLEEP_RECORDS_QUALITY_RATING],
      where: '$SLEEP_RECORDS_USER_ID = ? AND $SLEEP_RECORDS_SLEEP_DATE BETWEEN ? AND ?',
      whereArgs: [userId, startString, endString],
      orderBy: '$SLEEP_RECORDS_SLEEP_DATE DESC',
    );

    return {
      for (final row in results)
        DatabaseDateUtils.fromString(
            row[SLEEP_RECORDS_SLEEP_DATE] as String
        ): row[SLEEP_RECORDS_QUALITY_RATING] as String?,
    };
  }

  /// Gets baselines by type
  ///
  /// Queries user_sleep_baselines table for all metrics of a specific baseline type.
  Future<List<SleepBaseline>> getBaselinesByType(
    String userId,
    String baselineType,
  ) async {
    final results = await database.query(
      TABLE_USER_SLEEP_BASELINES,
      where: '$USER_SLEEP_BASELINES_USER_ID = ? AND $USER_SLEEP_BASELINES_BASELINE_TYPE = ?',
      whereArgs: [userId, baselineType],
    );

    return results.map((row) => SleepBaseline.fromDatabase(row)).toList();
  }

  /// Gets a specific baseline value
  ///
  /// Queries for a single metric value from user_sleep_baselines table.
  /// Returns null if baseline doesn't exist.
  Future<double?> getSpecificBaseline(
    String userId,
    String baselineType,
    String metricName,
  ) async {
    final results = await database.query(
      TABLE_USER_SLEEP_BASELINES,
      columns: [USER_SLEEP_BASELINES_METRIC_VALUE],
      where: '$USER_SLEEP_BASELINES_USER_ID = ? AND $USER_SLEEP_BASELINES_BASELINE_TYPE = ? AND $USER_SLEEP_BASELINES_METRIC_NAME = ?',
      whereArgs: [userId, baselineType, metricName],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first[USER_SLEEP_BASELINES_METRIC_VALUE] as double?;
  }
}