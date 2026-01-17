import '../../domain/models/sleep_baseline.dart';
import '../../domain/models/sleep_record.dart';
import '../../domain/models/sleep_record_sleep_phase.dart';
import '../../domain/repositories/sleep_record_repository.dart';
import '../datasources/sleep_record_local_datasource.dart';

/// Sleep Record Repository Implementation
///
/// Concrete implementation of SleepRecordRepository interface.
/// Delegates all operations to SleepRecordLocalDataSource.
///
/// This layer provides abstraction between business logic and data access,
/// making it easy to add caching, remote sync, or other data sources in the future.
class SleepRecordRepositoryImpl implements SleepRecordRepository {
  final SleepRecordLocalDataSource _dataSource;

  /// Creates a new instance of [SleepRecordRepositoryImpl].
  ///
  /// Requires a [SleepRecordLocalDataSource] to handle data operations.
  SleepRecordRepositoryImpl({required SleepRecordLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  /// Retrieves a single sleep record for a specific user and date.
  Future<SleepRecord?> getRecordForDate(String userId, DateTime date) async {
    return await _dataSource.getRecordByDate(userId, date);
  }

  @override
  /// Retrieves a list of sleep records for a user within a given date range.
  Future<List<SleepRecord>> getRecordsBetween(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    return await _dataSource.getRecordsByDateRange(userId, start, end);
  }

  @override
  /// Retrieves recent sleep records for a user for a specified number of days.
  Future<List<SleepRecord>> getRecentRecords(String userId, int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return await _dataSource.getRecordsByDateRange(userId, start, end);
  }

  @override
  /// Saves a sleep record to the local data source.
  ///
  /// This method handles both creating new records and updating existing ones.
  Future<void> saveRecord(SleepRecord record) async {
    // Use insertRecord which handles both insert and update via INSERT OR REPLACE
    await _dataSource.insertRecord(record);
  }

  @override
  /// Deletes a sleep record from the local data source.
  Future<void> deleteRecord(String recordId) async {
    await _dataSource.deleteRecord(recordId);
  }

  @override
  /// Updates the quality rating and notes for a specific sleep record.
  Future<void> updateQualityRating(
    String recordId,
    String rating,
    String? notes,
  ) async {
    await _dataSource.updateQualityFields(recordId, rating, notes);
  }

  @override
  /// Retrieves a list of sleep baselines for a user and baseline type.
  Future<List<SleepBaseline>> getBaselines(
    String userId,
    String baselineType,
  ) async {
    return await _dataSource.getBaselinesByType(userId, baselineType);
  }

  @override
  /// Retrieves a specific baseline value for a user, baseline type, and metric name.
  Future<double?> getBaselineValue(
    String userId,
    String baselineType,
    String metricName,
  ) async {
    return await _dataSource.getSpecificBaseline(
      userId,
      baselineType,
      metricName,
    );
  }

  @override
  /// Retrieves the quality ratings for the 7 days leading up to a specific date.
  Future<Map<DateTime, String?>> getPreviousQualityRatings(String userId, DateTime upUntil) async {
    return await _dataSource.getQualityForRange(userId, upUntil.subtract(Duration(days: 6)), upUntil);
  }

  @override
  /// Retrieves all sleep phases for a given sleep record.
  Future<List<SleepRecordSleepPhase>> getSleepPhasesForRecord(String sleepRecordId) async {
    return await _dataSource.getSleepPhasesForRecord(sleepRecordId);
  }
}
