import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:sleepbalance/core/utils/database_date_utils.dart';
import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

/// Light Module Local Data Source
///
/// Handles all database operations for the Light module:
/// - Configuration management (CRUD for user_module_configurations)
/// - Activity tracking (CRUD for intervention_activities where module_id='light')
/// - Analytics queries (completion counts, rates, distributions)
class LightModuleLocalDataSource {
  final Database _database;

  LightModuleLocalDataSource({required Database database})
      : _database = database;

  // =========================================================================
  // Configuration Operations
  // =========================================================================

  /// Get user's Light module configuration
  ///
  /// Returns null if user hasn't configured Light module yet.
  Future<UserModuleConfig?> getConfigForUser(String userId) async {
    final results = await _database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
      whereArgs: [userId, 'light'],
    );

    if (results.isEmpty) {
      return null;
    }

    return UserModuleConfig.fromDatabase(results.first);
  }

  /// Save or update Light module configuration
  ///
  /// Uses INSERT OR REPLACE to handle both create and update cases.
  Future<void> upsertConfig(UserModuleConfig config) async {
    await _database.insert(
      TABLE_USER_MODULE_CONFIGURATIONS,
      config.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =========================================================================
  // Activity Operations
  // =========================================================================

  /// Get all Light activities for a specific date
  ///
  /// Returns empty list if no activities found.
  Future<List<InterventionActivity>> getActivitiesByDate(
    String userId,
    DateTime date,
  ) async {
    final dateString = DatabaseDateUtils.toDateString(date);

    final results = await _database.query(
      TABLE_INTERVENTION_ACTIVITIES,
      where: '$INTERVENTION_ACTIVITIES_USER_ID = ? AND '
          '$INTERVENTION_ACTIVITIES_MODULE_ID = ? AND '
          '$INTERVENTION_ACTIVITIES_ACTIVITY_DATE = ?',
      whereArgs: [userId, 'light', dateString],
      orderBy: '$INTERVENTION_ACTIVITIES_COMPLETED_AT DESC',
    );

    return results
        .map((row) => InterventionActivity.fromDatabase(row))
        .toList();
  }

  /// Get Light activities within a date range
  ///
  /// Used for analytics and trend visualization.
  /// Returns activities ordered by date descending (newest first).
  Future<List<InterventionActivity>> getActivitiesBetween(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString = DatabaseDateUtils.toDateString(startDate);
    final endString = DatabaseDateUtils.toDateString(endDate);

    final results = await _database.query(
      TABLE_INTERVENTION_ACTIVITIES,
      where: '$INTERVENTION_ACTIVITIES_USER_ID = ? AND '
          '$INTERVENTION_ACTIVITIES_MODULE_ID = ? AND '
          '$INTERVENTION_ACTIVITIES_ACTIVITY_DATE BETWEEN ? AND ?',
      whereArgs: [userId, 'light', startString, endString],
      orderBy: '$INTERVENTION_ACTIVITIES_ACTIVITY_DATE DESC',
    );

    return results
        .map((row) => InterventionActivity.fromDatabase(row))
        .toList();
  }

  /// Insert new Light activity
  ///
  /// Throws exception if activity already exists with same ID.
  Future<void> insertActivity(InterventionActivity activity) async {
    await _database.insert(
      TABLE_INTERVENTION_ACTIVITIES,
      activity.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Update existing Light activity
  ///
  /// Throws exception if activity doesn't exist.
  Future<void> updateActivity(InterventionActivity activity) async {
    final count = await _database.update(
      TABLE_INTERVENTION_ACTIVITIES,
      activity.toDatabase(),
      where: '$INTERVENTION_ACTIVITIES_ID = ?',
      whereArgs: [activity.id],
    );

    if (count == 0) {
      throw Exception('Activity not found: ${activity.id}');
    }
  }

  /// Delete Light activity by ID
  ///
  /// Does nothing if activity doesn't exist (idempotent).
  Future<void> deleteActivity(String activityId) async {
    await _database.delete(
      TABLE_INTERVENTION_ACTIVITIES,
      where: '$INTERVENTION_ACTIVITIES_ID = ?',
      whereArgs: [activityId],
    );
  }

  // =========================================================================
  // Analytics Operations
  // =========================================================================

  /// Get count of completed Light activities in date range
  ///
  /// Only counts activities where was_completed = 1.
  /// Used for streak tracking and completion statistics.
  Future<int> getCompletionCountBetween(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString = DatabaseDateUtils.toDateString(startDate);
    final endString = DatabaseDateUtils.toDateString(endDate);

    final results = await _database.rawQuery('''
      SELECT COUNT(*) as count
      FROM $TABLE_INTERVENTION_ACTIVITIES
      WHERE $INTERVENTION_ACTIVITIES_USER_ID = ?
        AND $INTERVENTION_ACTIVITIES_MODULE_ID = ?
        AND $INTERVENTION_ACTIVITIES_ACTIVITY_DATE BETWEEN ? AND ?
        AND $INTERVENTION_ACTIVITIES_WAS_COMPLETED = 1
    ''', [userId, 'light', startString, endString]);

    return results.first['count'] as int;
  }

  /// Get completion rate as percentage
  ///
  /// Calculates: (completed activities / total days in range) * 100
  ///
  /// Returns:
  /// - 0.0 to 100.0 (percentage)
  /// - 0.0 if no activities in range
  Future<double> getCompletionRateBetween(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final completedCount = await getCompletionCountBetween(
      userId,
      startDate,
      endDate,
    );

    // Calculate total days in range (inclusive)
    final totalDays = endDate.difference(startDate).inDays + 1;

    if (totalDays == 0) return 0.0;

    return (completedCount / totalDays) * 100.0;
  }

  /// Get distribution of light types used in date range
  ///
  /// Parses moduleSpecificData JSON to extract light_type field
  /// and counts occurrences of each type.
  ///
  /// Returns:
  /// ```dart
  /// {
  ///   'natural_sunlight': 15,
  ///   'light_box': 8,
  ///   'blue_light': 2,
  ///   'red_light': 1
  /// }
  /// ```
  Future<Map<String, int>> getLightTypeDistribution(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString = DatabaseDateUtils.toDateString(startDate);
    final endString = DatabaseDateUtils.toDateString(endDate);

    final results = await _database.query(
      TABLE_INTERVENTION_ACTIVITIES,
      columns: [INTERVENTION_ACTIVITIES_MODULE_SPECIFIC_DATA],
      where: '$INTERVENTION_ACTIVITIES_USER_ID = ? AND '
          '$INTERVENTION_ACTIVITIES_MODULE_ID = ? AND '
          '$INTERVENTION_ACTIVITIES_ACTIVITY_DATE BETWEEN ? AND ? AND '
          '$INTERVENTION_ACTIVITIES_WAS_COMPLETED = 1',
      whereArgs: [userId, 'light', startString, endString],
    );

    final distribution = <String, int>{};

    for (final row in results) {
      final dataString = row[INTERVENTION_ACTIVITIES_MODULE_SPECIFIC_DATA] as String?;

      if (dataString == null || dataString.isEmpty) continue;

      try {
        final data = json.decode(dataString) as Map<String, dynamic>;
        final lightType = data['light_type'] as String?;

        if (lightType != null) {
          distribution[lightType] = (distribution[lightType] ?? 0) + 1;
        }
      } catch (e) {
        // Skip malformed JSON
        continue;
      }
    }

    return distribution;
  }
}
