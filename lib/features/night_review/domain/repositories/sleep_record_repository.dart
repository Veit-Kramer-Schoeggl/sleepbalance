import '../models/sleep_baseline.dart';
import '../models/sleep_record.dart';
import '../models/sleep_record_sleep_phase.dart';

/// Sleep Record Repository Interface
///
/// Abstract interface for sleep record and baseline operations.
/// Follows repository pattern to decouple business logic from data access.
///
/// Responsibilities:
/// - CRUD operations for sleep records
/// - Query sleep records by date range
/// - Update subjective quality ratings
/// - Access sleep baseline metrics
///
/// Implementation: SleepRecordRepositoryImpl (data layer)
abstract class SleepRecordRepository {
  /// Gets sleep record for a specific date
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [date]: The sleep date (e.g., 2025-10-29)
  ///
  /// Returns the sleep record for that night, or null if not found
  Future<SleepRecord?> getRecordForDate(String userId, DateTime date);

  /// Gets sleep records within a date range
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [start]: Start date (inclusive)
  /// - [end]: End date (inclusive)
  ///
  /// Returns list of sleep records sorted by date descending (newest first)
  Future<List<SleepRecord>> getRecordsBetween(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Gets recent sleep records
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [days]: Number of days to look back
  ///
  /// Returns list of sleep records for the last N days
  ///
  /// Example: getRecentRecords('user123', 7) returns last week's sleep data
  Future<List<SleepRecord>> getRecentRecords(String userId, int days);

  /// Saves a sleep record (insert or update)
  ///
  /// If record ID exists, updates the existing record.
  /// Otherwise, inserts a new record.
  ///
  /// Parameters:
  /// - [record]: The sleep record to save
  Future<void> saveRecord(SleepRecord record);

  /// Deletes a sleep record
  ///
  /// Parameters:
  /// - [recordId]: The ID of the record to delete
  Future<void> deleteRecord(String recordId);

  /// Updates subjective quality rating for a sleep record
  ///
  /// Parameters:
  /// - [recordId]: The ID of the record to update
  /// - [rating]: Quality rating ('bad', 'average', 'good')
  /// - [notes]: Optional user notes about sleep quality
  ///
  /// This is a convenience method for updating just the quality fields
  /// without fetching and updating the entire record.
  Future<void> updateQualityRating(
    String recordId,
    String rating,
    String? notes,
  );

  /// Loads the previous 6 quality ratings
  ///
  /// Parameters:
  /// - [upUntil]: The end Date (excluded)
  ///
  /// This is a convenience method for fetching just the quality fields
  /// of the previous week
  Future<Map<DateTime, String?>> getPreviousQualityRatings(
    String userId,
    DateTime upUntil
  );

  /// Gets all baselines for a user by baseline type
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [baselineType]: Type of baseline ('7_day', '30_day', 'all_time')
  ///
  /// Returns list of baseline metrics for that type
  ///
  /// Example: getBaselines('user123', '7_day') returns all 7-day averages
  Future<List<SleepBaseline>> getBaselines(String userId, String baselineType);

  /// Gets a specific baseline value
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [baselineType]: Type of baseline ('7_day', '30_day', 'all_time')
  /// - [metricName]: Name of the metric ('avg_deep_sleep', 'avg_total_sleep', etc.)
  ///
  /// Returns the baseline value, or null if not found
  ///
  /// Example: getBaselineValue('user123', '7_day', 'avg_deep_sleep') → 85.0
  Future<double?> getBaselineValue(
    String userId,
    String baselineType,
    String metricName,
  );

  Future<List<SleepRecordSleepPhase>> getSleepPhasesForRecord(String sleepRecordId);
}