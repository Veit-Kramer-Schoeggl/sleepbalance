import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../shared/constants/database_constants.dart';
import '../../../auth/data/services/password_hash_service.dart';

/// Database Seeding Service
///
/// Provides comprehensive test data generation for development and testing.
/// Creates a predefined test user with sample data across all database entities.
///
/// Usage:
/// - DatabaseSeedService.seedDatabase() - Creates test user with all test data
/// - DatabaseSeedService.clearDatabase() - Wipes all database tables
///
/// Test User Credentials:
/// - Email: testuser1@gmail.com
/// - Password: 1234
class DatabaseSeedService {
  static const Uuid _uuid = Uuid();

  /// Seeds the entire database with test data
  ///
  /// This method is idempotent - it clears existing data before seeding,
  /// so it can be run multiple times safely.
  ///
  /// **Requires database version 8 or higher.**
  /// Throws an exception if database version is outdated or if seeding fails.
  static Future<void> seedDatabase() async {
    try {
      debugPrint('DatabaseSeedService: Starting database seeding...');

      // Check database version FIRST - fail fast if outdated
      final db = await DatabaseHelper.instance.database;
      final versionResult = await db.rawQuery('PRAGMA user_version');
      final version = Sqflite.firstIntValue(versionResult) ?? 0;

      if (version < 8) {
        throw Exception(
          'Database version $version is outdated! Required: version 8 or higher.\n'
          'Please uninstall the app and reinstall to upgrade the database:\n'
          '  adb uninstall com.sleepbalance.sleepbalance\n'
          '  flutter run'
        );
      }

      debugPrint('DatabaseSeedService: Database version $version ✓');

      // First, clear all data
      await clearDatabase();

      // Then seed fresh data
      final userId = await _createTestUser();
      await _seedModules();
      await _seedUserModuleConfigs(userId);
      await _seedSleepRecords(userId);
      await _seedUserSleepBaselines(userId);
      await _seedInterventionActivities(userId);
      await _seedDailyActions(userId);
      await _seedWearableConnections(userId);
      await _seedWearableSyncHistory(userId);

      debugPrint('DatabaseSeedService: Database seeded successfully');
    } catch (e) {
      debugPrint('DatabaseSeedService: Seeding failed: $e');
      rethrow;
    }
  }

  /// Clears all data from all database tables
  ///
  /// Also clears the SharedPreferences session.
  /// Tables are deleted in reverse dependency order to avoid foreign key violations.
  /// Silently skips tables that don't exist (for older database versions).
  static Future<void> clearDatabase() async {
    try {
      debugPrint('DatabaseSeedService: Clearing database...');

      final db = await DatabaseHelper.instance.database;

      // Delete in reverse dependency order
      // Use try-catch for each table in case it doesn't exist yet
      await _safeDelete(db, TABLE_WEARABLE_SYNC_HISTORY);
      await _safeDelete(db, TABLE_WEARABLE_CONNECTIONS);
      await _safeDelete(db, TABLE_DAILY_ACTIONS);
      await _safeDelete(db, TABLE_INTERVENTION_ACTIVITIES);
      await _safeDelete(db, TABLE_USER_SLEEP_BASELINES);
      await _safeDelete(db, TABLE_SLEEP_RECORDS);
      await _safeDelete(db, TABLE_USER_MODULE_CONFIGURATIONS);
      await _safeDelete(db, TABLE_EMAIL_VERIFICATION_TOKENS);
      await _safeDelete(db, TABLE_MODULES);
      await _safeDelete(db, TABLE_USERS);

      // Clear SharedPreferences session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');

      debugPrint('DatabaseSeedService: Database cleared successfully');
    } catch (e) {
      debugPrint('DatabaseSeedService: Clear failed: $e');
      rethrow;
    }
  }

  /// Safely deletes from a table, ignoring errors if table doesn't exist
  static Future<void> _safeDelete(dynamic db, String tableName) async {
    try {
      await db.delete(tableName);
    } catch (e) {
      // Table might not exist in older database versions - that's okay
      debugPrint('DatabaseSeedService: Skipped $tableName (table may not exist): $e');
    }
  }

  // ============================================================================
  // Private Seeding Methods
  // ============================================================================

  /// Creates test user with predefined credentials
  ///
  /// Returns the generated user ID
  static Future<String> _createTestUser() async {
    final db = await DatabaseHelper.instance.database;
    final userId = _uuid.v4();

    // Hash the test password "1234" using PBKDF2
    final passwordHash = await PasswordHashService.hashPassword('1234');

    await db.insert(TABLE_USERS, {
      USERS_ID: userId,
      USERS_EMAIL: 'testuser1@gmail.com',
      USERS_PASSWORD_HASH: passwordHash,
      USERS_FIRST_NAME: 'Test',
      USERS_LAST_NAME: 'User',
      USERS_BIRTH_DATE: '1990-01-01',
      USERS_TIMEZONE: 'UTC',
      USERS_TARGET_SLEEP_DURATION: 480,
      USERS_TARGET_BED_TIME: '22:00',
      USERS_TARGET_WAKE_TIME: '06:00',
      USERS_HAS_SLEEP_DISORDER: 0,
      USERS_TAKES_SLEEP_MEDICATION: 0,
      USERS_PREFERRED_UNIT_SYSTEM: 'metric',
      USERS_LANGUAGE: 'en',
      USERS_EMAIL_VERIFIED: 1,
      USERS_CREATED_AT: DateTime.now().toIso8601String(),
      USERS_UPDATED_AT: DateTime.now().toIso8601String(),
      USERS_IS_DELETED: 0,
    });

    debugPrint('DatabaseSeedService: Created test user with ID: $userId');
    return userId;
  }

  /// Seeds all 9 intervention modules
  static Future<void> _seedModules() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    final modules = [
      {
        MODULES_ID: 'light',
        MODULES_NAME: 'light',
        MODULES_DISPLAY_NAME: 'Light Therapy',
        MODULES_DESCRIPTION: 'Morning and evening light exposure optimization',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'sport',
        MODULES_NAME: 'sport',
        MODULES_DISPLAY_NAME: 'Exercise & Movement',
        MODULES_DESCRIPTION: 'Physical activity and exercise routines',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'temperature',
        MODULES_NAME: 'temperature',
        MODULES_DISPLAY_NAME: 'Temperature Exposure',
        MODULES_DESCRIPTION: 'Sauna, heat and cold exposure protocols',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'nutrition',
        MODULES_NAME: 'nutrition',
        MODULES_DISPLAY_NAME: 'Sleep-Promoting Nutrition',
        MODULES_DESCRIPTION: 'Foods and supplements for better sleep',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'mealtime',
        MODULES_NAME: 'mealtime',
        MODULES_DISPLAY_NAME: 'Meal Timing',
        MODULES_DESCRIPTION: 'Eating schedule optimization',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'sleep_hygiene',
        MODULES_NAME: 'sleep_hygiene',
        MODULES_DISPLAY_NAME: 'Sleep Hygiene',
        MODULES_DESCRIPTION: 'Bedtime routine and environment optimization',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'meditation',
        MODULES_NAME: 'meditation',
        MODULES_DISPLAY_NAME: 'Meditation & Relaxation',
        MODULES_DESCRIPTION: 'Mindfulness and relaxation techniques',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'journaling',
        MODULES_NAME: 'journaling',
        MODULES_DISPLAY_NAME: 'Sleep Journaling',
        MODULES_DESCRIPTION: 'Progress tracking and reflection',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
      {
        MODULES_ID: 'medication',
        MODULES_NAME: 'medication',
        MODULES_DISPLAY_NAME: 'Medication Tracking',
        MODULES_DESCRIPTION: 'Track medication and effects on sleep',
        MODULES_IS_ACTIVE: 1,
        MODULES_CREATED_AT: now,
      },
    ];

    for (final module in modules) {
      await db.insert(TABLE_MODULES, module);
    }

    debugPrint('DatabaseSeedService: Seeded ${modules.length} modules');
  }

  /// Seeds all 9 user module configurations (3 enabled, 6 disabled)
  static Future<void> _seedUserModuleConfigs(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    final configs = [
      // Enabled modules
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'light',
        USER_MODULE_CONFIGS_IS_ENABLED: 1,
        USER_MODULE_CONFIGS_CONFIGURATION: '{"intensity": "medium", "duration_minutes": 30}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'sport',
        USER_MODULE_CONFIGS_IS_ENABLED: 1,
        USER_MODULE_CONFIGS_CONFIGURATION: '{"type": "cardio", "duration_minutes": 45}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'meditation',
        USER_MODULE_CONFIGS_IS_ENABLED: 1,
        USER_MODULE_CONFIGS_CONFIGURATION: '{"type": "mindfulness", "duration_minutes": 15}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      // Disabled modules
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'temperature',
        USER_MODULE_CONFIGS_IS_ENABLED: 0,
        USER_MODULE_CONFIGS_CONFIGURATION: '{}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'nutrition',
        USER_MODULE_CONFIGS_IS_ENABLED: 0,
        USER_MODULE_CONFIGS_CONFIGURATION: '{}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'mealtime',
        USER_MODULE_CONFIGS_IS_ENABLED: 0,
        USER_MODULE_CONFIGS_CONFIGURATION: '{}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'sleep_hygiene',
        USER_MODULE_CONFIGS_IS_ENABLED: 0,
        USER_MODULE_CONFIGS_CONFIGURATION: '{}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'journaling',
        USER_MODULE_CONFIGS_IS_ENABLED: 0,
        USER_MODULE_CONFIGS_CONFIGURATION: '{}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
      {
        USER_MODULE_CONFIGS_ID: _uuid.v4(),
        USER_MODULE_CONFIGS_USER_ID: userId,
        USER_MODULE_CONFIGS_MODULE_ID: 'medication',
        USER_MODULE_CONFIGS_IS_ENABLED: 0,
        USER_MODULE_CONFIGS_CONFIGURATION: '{}',
        USER_MODULE_CONFIGS_ENROLLED_AT: now,
        USER_MODULE_CONFIGS_UPDATED_AT: now,
      },
    ];

    for (final config in configs) {
      await db.insert(TABLE_USER_MODULE_CONFIGURATIONS, config);
    }

    debugPrint('DatabaseSeedService: Seeded ${configs.length} module configurations');
  }

  /// Seeds 7 days of sleep records
  static Future<void> _seedSleepRecords(String userId) async {
    final db = await DatabaseHelper.instance.database;

    // Normalize to date-only so "sleep_date" matches your date queries
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final qualityRatings = [
      'good', 'good', 'average', 'good', 'bad', 'average', 'good'
    ];

    DateTime _timeOnDay(DateTime day, String hhmm) {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return DateTime(day.year, day.month, day.day, h, m);
    }

    for (int i = 0; i < 7; i++) {
      // sleep_date is the WAKE date (e.g. 2026-01-10)
      final wakeDay = today.subtract(Duration(days: i));
      final sleepDate = _formatDate(wakeDay);

      // Bed/start happen the evening BEFORE the wake day (e.g. 2026-01-09)
      final bedDay = wakeDay.subtract(const Duration(days: 1));

      final bedTime = _timeOnDay(bedDay, '22:30');
      final sleepStart = _timeOnDay(bedDay, '23:00');

      // End/wake are on the wake day morning
      final sleepEnd = _timeOnDay(wakeDay, '06:00');
      final wakeTime = _timeOnDay(wakeDay, '06:30');

      // Timestamps (whatever you prefer; here: created/updated on wakeDay noon)
      final createdAt = wakeDay.add(const Duration(hours: 12));
      final updatedAt = createdAt;

      await db.insert(TABLE_SLEEP_RECORDS, {
        SLEEP_RECORDS_ID: _uuid.v4(),
        SLEEP_RECORDS_USER_ID: userId,

        // IMPORTANT: this is now the WAKE day date-only string
        SLEEP_RECORDS_SLEEP_DATE: sleepDate,

        // IMPORTANT: full ISO strings so your fromDatabase parsing works
        SLEEP_RECORDS_BED_TIME: bedTime.toIso8601String(),
        SLEEP_RECORDS_SLEEP_START_TIME: sleepStart.toIso8601String(),
        SLEEP_RECORDS_SLEEP_END_TIME: sleepEnd.toIso8601String(),
        SLEEP_RECORDS_WAKE_TIME: wakeTime.toIso8601String(),

        SLEEP_RECORDS_TOTAL_SLEEP_TIME: 420,
        SLEEP_RECORDS_DEEP_SLEEP_DURATION: 100,
        SLEEP_RECORDS_REM_SLEEP_DURATION: 90,
        SLEEP_RECORDS_LIGHT_SLEEP_DURATION: 200,
        SLEEP_RECORDS_AWAKE_DURATION: 30,

        SLEEP_RECORDS_AVG_HEART_RATE: 60.0,
        SLEEP_RECORDS_MIN_HEART_RATE: 50.0,
        SLEEP_RECORDS_MAX_HEART_RATE: 75.0,
        SLEEP_RECORDS_AVG_HRV: 50.0,
        SLEEP_RECORDS_AVG_BREATHING_RATE: 14.0,

        SLEEP_RECORDS_QUALITY_RATING: qualityRatings[i],
        SLEEP_RECORDS_DATA_SOURCE: 'manual',
        SLEEP_RECORDS_CREATED_AT: createdAt.toIso8601String(),
        SLEEP_RECORDS_UPDATED_AT: updatedAt.toIso8601String(),
        SLEEP_RECORDS_IS_DELETED: 0,
      });
    }

    debugPrint('DatabaseSeedService: Seeded 7 sleep records (sleep_date = wake date)');
  }


  /// Seeds user sleep baselines (7-day, 30-day, all-time)
  static Future<void> _seedUserSleepBaselines(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final computedAt = now.toIso8601String();

    final baselines = [
      // 7-day baselines
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: '7_day',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_total_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 420.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 7))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: '7_day',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_deep_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 100.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 7))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: '7_day',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_rem_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 90.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 7))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      // 30-day baselines
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: '30_day',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_total_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 425.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 30))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: '30_day',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_deep_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 105.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 30))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: '30_day',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_rem_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 95.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 30))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      // all-time baselines
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: 'all_time',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_total_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 430.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 90))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: 'all_time',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_deep_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 110.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 90))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
      {
        USER_SLEEP_BASELINES_ID: _uuid.v4(),
        USER_SLEEP_BASELINES_USER_ID: userId,
        USER_SLEEP_BASELINES_BASELINE_TYPE: 'all_time',
        USER_SLEEP_BASELINES_METRIC_NAME: 'avg_rem_sleep',
        USER_SLEEP_BASELINES_METRIC_VALUE: 100.0,
        USER_SLEEP_BASELINES_DATA_RANGE_START: _formatDate(now.subtract(const Duration(days: 90))),
        USER_SLEEP_BASELINES_DATA_RANGE_END: _formatDate(now),
        USER_SLEEP_BASELINES_COMPUTED_AT: computedAt,
      },
    ];

    for (final baseline in baselines) {
      await db.insert(TABLE_USER_SLEEP_BASELINES, baseline);
    }

    debugPrint('DatabaseSeedService: Seeded ${baselines.length} baselines');
  }

  /// Seeds 5 intervention activities (3 light, 2 sport)
  static Future<void> _seedInterventionActivities(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    // Light module activities (last 3 days)
    for (int i = 0; i < 3; i++) {
      final date = now.subtract(Duration(days: i));
      final activityDate = _formatDate(date);

      await db.insert(TABLE_INTERVENTION_ACTIVITIES, {
        INTERVENTION_ACTIVITIES_ID: _uuid.v4(),
        INTERVENTION_ACTIVITIES_USER_ID: userId,
        INTERVENTION_ACTIVITIES_MODULE_ID: 'light',
        INTERVENTION_ACTIVITIES_ACTIVITY_DATE: activityDate,
        INTERVENTION_ACTIVITIES_WAS_COMPLETED: i % 2 == 0 ? 1 : 0,
        INTERVENTION_ACTIVITIES_COMPLETED_AT: i % 2 == 0 ? date.toIso8601String() : null,
        INTERVENTION_ACTIVITIES_DURATION_MINUTES: 30,
        INTERVENTION_ACTIVITIES_TIME_OF_DAY: 'morning',
        INTERVENTION_ACTIVITIES_INTENSITY: 'medium',
        INTERVENTION_ACTIVITIES_MODULE_SPECIFIC_DATA: '{"light_type": "natural", "location": "outdoor"}',
        INTERVENTION_ACTIVITIES_CREATED_AT: date.toIso8601String(),
        INTERVENTION_ACTIVITIES_UPDATED_AT: date.toIso8601String(),
        INTERVENTION_ACTIVITIES_IS_DELETED: 0,
      });
    }

    // Sport module activities (last 2 days)
    for (int i = 0; i < 2; i++) {
      final date = now.subtract(Duration(days: i));
      final activityDate = _formatDate(date);

      await db.insert(TABLE_INTERVENTION_ACTIVITIES, {
        INTERVENTION_ACTIVITIES_ID: _uuid.v4(),
        INTERVENTION_ACTIVITIES_USER_ID: userId,
        INTERVENTION_ACTIVITIES_MODULE_ID: 'sport',
        INTERVENTION_ACTIVITIES_ACTIVITY_DATE: activityDate,
        INTERVENTION_ACTIVITIES_WAS_COMPLETED: 1,
        INTERVENTION_ACTIVITIES_COMPLETED_AT: date.toIso8601String(),
        INTERVENTION_ACTIVITIES_DURATION_MINUTES: 45,
        INTERVENTION_ACTIVITIES_TIME_OF_DAY: 'afternoon',
        INTERVENTION_ACTIVITIES_INTENSITY: 'high',
        INTERVENTION_ACTIVITIES_MODULE_SPECIFIC_DATA: '{"exercise_type": "running", "distance_km": 5}',
        INTERVENTION_ACTIVITIES_CREATED_AT: date.toIso8601String(),
        INTERVENTION_ACTIVITIES_UPDATED_AT: date.toIso8601String(),
        INTERVENTION_ACTIVITIES_IS_DELETED: 0,
      });
    }

    debugPrint('DatabaseSeedService: Seeded 5 intervention activities');
  }

  /// Seeds 3 daily actions for today
  static Future<void> _seedDailyActions(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final today = _formatDate(now);
    final createdAt = now.toIso8601String();

    final actions = [
      {
        DAILY_ACTIONS_ID: _uuid.v4(),
        DAILY_ACTIONS_USER_ID: userId,
        DAILY_ACTIONS_TITLE: 'Morning light exposure',
        DAILY_ACTIONS_ICON_NAME: 'wb_sunny',
        DAILY_ACTIONS_IS_COMPLETED: 0,
        DAILY_ACTIONS_ACTION_DATE: today,
        DAILY_ACTIONS_CREATED_AT: createdAt,
      },
      {
        DAILY_ACTIONS_ID: _uuid.v4(),
        DAILY_ACTIONS_USER_ID: userId,
        DAILY_ACTIONS_TITLE: 'Evening exercise session',
        DAILY_ACTIONS_ICON_NAME: 'fitness_center',
        DAILY_ACTIONS_IS_COMPLETED: 0,
        DAILY_ACTIONS_ACTION_DATE: today,
        DAILY_ACTIONS_CREATED_AT: createdAt,
      },
      {
        DAILY_ACTIONS_ID: _uuid.v4(),
        DAILY_ACTIONS_USER_ID: userId,
        DAILY_ACTIONS_TITLE: 'Meditation before bed',
        DAILY_ACTIONS_ICON_NAME: 'self_improvement',
        DAILY_ACTIONS_IS_COMPLETED: 0,
        DAILY_ACTIONS_ACTION_DATE: today,
        DAILY_ACTIONS_CREATED_AT: createdAt,
      },
    ];

    for (final action in actions) {
      await db.insert(TABLE_DAILY_ACTIONS, action);
    }

    debugPrint('DatabaseSeedService: Seeded ${actions.length} daily actions');
  }

  /// Seeds 1 fake wearable connection
  static Future<void> _seedWearableConnections(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30));

    await db.insert(TABLE_WEARABLE_CONNECTIONS, {
      WEARABLE_CONNECTIONS_ID: _uuid.v4(),
      WEARABLE_CONNECTIONS_USER_ID: userId,
      WEARABLE_CONNECTIONS_PROVIDER: 'fitbit',
      WEARABLE_CONNECTIONS_ACCESS_TOKEN: 'fake_token_for_testing',
      WEARABLE_CONNECTIONS_REFRESH_TOKEN: 'fake_refresh_token',
      WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT: expiresAt.toIso8601String(),
      WEARABLE_CONNECTIONS_USER_EXTERNAL_ID: 'test_fitbit_user_123',
      WEARABLE_CONNECTIONS_GRANTED_SCOPES: '["sleep", "heartrate", "activity"]',
      WEARABLE_CONNECTIONS_IS_ACTIVE: 1,
      WEARABLE_CONNECTIONS_CONNECTED_AT: now.toIso8601String(),
      WEARABLE_CONNECTIONS_LAST_SYNC_AT: now.toIso8601String(),
      WEARABLE_CONNECTIONS_CREATED_AT: now.toIso8601String(),
      WEARABLE_CONNECTIONS_UPDATED_AT: now.toIso8601String(),
    });

    debugPrint('DatabaseSeedService: Seeded 1 wearable connection');
  }

  /// Seeds 2 wearable sync history entries (1 success, 1 failure)
  static Future<void> _seedWearableSyncHistory(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    // Successful sync (3 days ago)
    final successDate = now.subtract(const Duration(days: 3));
    await db.insert(TABLE_WEARABLE_SYNC_HISTORY, {
      WEARABLE_SYNC_HISTORY_ID: _uuid.v4(),
      WEARABLE_SYNC_HISTORY_USER_ID: userId,
      WEARABLE_SYNC_HISTORY_PROVIDER: 'fitbit',
      WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM: _formatDate(successDate.subtract(const Duration(days: 7))),
      WEARABLE_SYNC_HISTORY_SYNC_DATE_TO: _formatDate(successDate),
      WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT: successDate.toIso8601String(),
      WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT: successDate.add(const Duration(minutes: 2)).toIso8601String(),
      WEARABLE_SYNC_HISTORY_STATUS: 'success',
      WEARABLE_SYNC_HISTORY_RECORDS_FETCHED: 7,
      WEARABLE_SYNC_HISTORY_RECORDS_INSERTED: 5,
      WEARABLE_SYNC_HISTORY_RECORDS_UPDATED: 2,
      WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED: 0,
    });

    // Failed sync (1 day ago)
    final failureDate = now.subtract(const Duration(days: 1));
    await db.insert(TABLE_WEARABLE_SYNC_HISTORY, {
      WEARABLE_SYNC_HISTORY_ID: _uuid.v4(),
      WEARABLE_SYNC_HISTORY_USER_ID: userId,
      WEARABLE_SYNC_HISTORY_PROVIDER: 'fitbit',
      WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM: _formatDate(failureDate.subtract(const Duration(days: 7))),
      WEARABLE_SYNC_HISTORY_SYNC_DATE_TO: _formatDate(failureDate),
      WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT: failureDate.toIso8601String(),
      WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT: failureDate.add(const Duration(seconds: 30)).toIso8601String(),
      WEARABLE_SYNC_HISTORY_STATUS: 'failed',
      WEARABLE_SYNC_HISTORY_RECORDS_FETCHED: 0,
      WEARABLE_SYNC_HISTORY_RECORDS_INSERTED: 0,
      WEARABLE_SYNC_HISTORY_RECORDS_UPDATED: 0,
      WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED: 0,
      WEARABLE_SYNC_HISTORY_ERROR_CODE: 'TOKEN_EXPIRED',
      WEARABLE_SYNC_HISTORY_ERROR_MESSAGE: 'Token expired',
    });

    debugPrint('DatabaseSeedService: Seeded 2 sync history entries');
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Formats date as YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
