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

  SleepRecordRepositoryImpl({required SleepRecordLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<SleepRecord?> getRecordForDate(String userId, DateTime date) async {
    return await _dataSource.getRecordByDate(userId, date);
  }

  @override
  Future<List<SleepRecord>> getRecordsBetween(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    return await _dataSource.getRecordsByDateRange(userId, start, end);
  }

  @override
  Future<List<SleepRecord>> getRecentRecords(String userId, int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return await _dataSource.getRecordsByDateRange(userId, start, end);
  }

  @override
  Future<void> saveRecord(SleepRecord record) async {
    // Use insertRecord which handles both insert and update via INSERT OR REPLACE
    await _dataSource.insertRecord(record);
  }

  @override
  Future<void> deleteRecord(String recordId) async {
    await _dataSource.deleteRecord(recordId);
  }

  @override
  Future<void> updateQualityRating(
    String recordId,
    String rating,
    String? notes,
  ) async {
    await _dataSource.updateQualityFields(recordId, rating, notes);
  }

  @override
  Future<List<SleepBaseline>> getBaselines(
    String userId,
    String baselineType,
  ) async {
    return await _dataSource.getBaselinesByType(userId, baselineType);
  }

  @override
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
  Future<Map<DateTime, String?>> getPreviousQualityRatings(String userId, DateTime upUntil) async {
    return await _dataSource.getQualityForRange(userId, upUntil.subtract(Duration(days: 6)), upUntil);
  }

  @override
  Future<List<SleepRecordSleepPhase>> getSleepPhasesForRecord(String sleepRecordId) async {
    return await _dataSource.getSleepPhasesForRecord(sleepRecordId);
  }
}