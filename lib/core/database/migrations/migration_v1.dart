// ignore_for_file: constant_identifier_names

import '../../../shared/constants/database_constants.dart';

/// Migration V1: Initial Database Schema
///
/// Creates all initial tables for the SleepBalance application:
/// - users: User profiles and preferences
/// - sleep_records: Nightly sleep data from wearables
/// - modules: Intervention module definitions
/// - user_module_configurations: User-specific module settings
/// - intervention_activities: Daily intervention tracking
/// - user_sleep_baselines: Computed personal averages
///
/// Also pre-populates modules table with 9 intervention modules.

const String MIGRATION_V1 = '''
-- ============================================================================
-- Users Table
-- ============================================================================
CREATE TABLE $TABLE_USERS (
  $USERS_ID TEXT PRIMARY KEY,
  $USERS_EMAIL TEXT UNIQUE NOT NULL,
  $USERS_PASSWORD_HASH TEXT,
  $USERS_FIRST_NAME TEXT NOT NULL,
  $USERS_LAST_NAME TEXT NOT NULL,
  $USERS_BIRTH_DATE TEXT NOT NULL,
  $USERS_TIMEZONE TEXT NOT NULL,
  $USERS_TARGET_SLEEP_DURATION INTEGER,
  $USERS_TARGET_BED_TIME TEXT,
  $USERS_TARGET_WAKE_TIME TEXT,
  $USERS_HAS_SLEEP_DISORDER INTEGER NOT NULL DEFAULT 0,
  $USERS_SLEEP_DISORDER_TYPE TEXT,
  $USERS_TAKES_SLEEP_MEDICATION INTEGER NOT NULL DEFAULT 0,
  $USERS_PREFERRED_UNIT_SYSTEM TEXT NOT NULL DEFAULT 'metric',
  $USERS_LANGUAGE TEXT NOT NULL DEFAULT 'en',
  $USERS_CREATED_AT TEXT NOT NULL,
  $USERS_UPDATED_AT TEXT NOT NULL,
  $USERS_SYNCED_AT TEXT,
  $USERS_IS_DELETED INTEGER NOT NULL DEFAULT 0
);

-- ============================================================================
-- Sleep Records Table
-- ============================================================================
CREATE TABLE $TABLE_SLEEP_RECORDS (
  $SLEEP_RECORDS_ID TEXT PRIMARY KEY,
  $SLEEP_RECORDS_USER_ID TEXT NOT NULL,
  $SLEEP_RECORDS_SLEEP_DATE TEXT NOT NULL,
  $SLEEP_RECORDS_BED_TIME TEXT,
  $SLEEP_RECORDS_SLEEP_START_TIME TEXT,
  $SLEEP_RECORDS_SLEEP_END_TIME TEXT,
  $SLEEP_RECORDS_WAKE_TIME TEXT,
  $SLEEP_RECORDS_TOTAL_SLEEP_TIME INTEGER,
  $SLEEP_RECORDS_DEEP_SLEEP_DURATION INTEGER,
  $SLEEP_RECORDS_REM_SLEEP_DURATION INTEGER,
  $SLEEP_RECORDS_LIGHT_SLEEP_DURATION INTEGER,
  $SLEEP_RECORDS_AWAKE_DURATION INTEGER,
  $SLEEP_RECORDS_AVG_HEART_RATE REAL,
  $SLEEP_RECORDS_MIN_HEART_RATE REAL,
  $SLEEP_RECORDS_MAX_HEART_RATE REAL,
  $SLEEP_RECORDS_AVG_HRV REAL,
  $SLEEP_RECORDS_AVG_BREATHING_RATE REAL,
  $SLEEP_RECORDS_QUALITY_RATING TEXT CHECK($SLEEP_RECORDS_QUALITY_RATING IN ('bad', 'average', 'good')),
  $SLEEP_RECORDS_QUALITY_NOTES TEXT,
  $SLEEP_RECORDS_DATA_SOURCE TEXT NOT NULL,
  $SLEEP_RECORDS_CREATED_AT TEXT NOT NULL,
  $SLEEP_RECORDS_UPDATED_AT TEXT NOT NULL,
  $SLEEP_RECORDS_SYNCED_AT TEXT,
  $SLEEP_RECORDS_IS_DELETED INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY ($SLEEP_RECORDS_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE,
  UNIQUE($SLEEP_RECORDS_USER_ID, $SLEEP_RECORDS_SLEEP_DATE)
);

-- ============================================================================
-- Modules Table
-- ============================================================================
CREATE TABLE $TABLE_MODULES (
  $MODULES_ID TEXT PRIMARY KEY,
  $MODULES_NAME TEXT UNIQUE NOT NULL,
  $MODULES_DISPLAY_NAME TEXT NOT NULL,
  $MODULES_DESCRIPTION TEXT,
  $MODULES_ICON TEXT,
  $MODULES_IS_ACTIVE INTEGER NOT NULL DEFAULT 1,
  $MODULES_CREATED_AT TEXT NOT NULL
);

-- ============================================================================
-- User Module Configurations Table
-- ============================================================================
CREATE TABLE $TABLE_USER_MODULE_CONFIGURATIONS (
  $USER_MODULE_CONFIGS_ID TEXT PRIMARY KEY,
  $USER_MODULE_CONFIGS_USER_ID TEXT NOT NULL,
  $USER_MODULE_CONFIGS_MODULE_ID TEXT NOT NULL,
  $USER_MODULE_CONFIGS_IS_ENABLED INTEGER NOT NULL DEFAULT 1,
  $USER_MODULE_CONFIGS_CONFIGURATION TEXT,
  $USER_MODULE_CONFIGS_ENROLLED_AT TEXT NOT NULL,
  $USER_MODULE_CONFIGS_UPDATED_AT TEXT NOT NULL,
  $USER_MODULE_CONFIGS_SYNCED_AT TEXT,
  FOREIGN KEY ($USER_MODULE_CONFIGS_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE,
  FOREIGN KEY ($USER_MODULE_CONFIGS_MODULE_ID) REFERENCES $TABLE_MODULES($MODULES_ID) ON DELETE CASCADE,
  UNIQUE($USER_MODULE_CONFIGS_USER_ID, $USER_MODULE_CONFIGS_MODULE_ID)
);

-- ============================================================================
-- Intervention Activities Table
-- ============================================================================
CREATE TABLE $TABLE_INTERVENTION_ACTIVITIES (
  $INTERVENTION_ACTIVITIES_ID TEXT PRIMARY KEY,
  $INTERVENTION_ACTIVITIES_USER_ID TEXT NOT NULL,
  $INTERVENTION_ACTIVITIES_MODULE_ID TEXT NOT NULL,
  $INTERVENTION_ACTIVITIES_ACTIVITY_DATE TEXT NOT NULL,
  $INTERVENTION_ACTIVITIES_WAS_COMPLETED INTEGER NOT NULL,
  $INTERVENTION_ACTIVITIES_COMPLETED_AT TEXT,
  $INTERVENTION_ACTIVITIES_DURATION_MINUTES INTEGER,
  $INTERVENTION_ACTIVITIES_TIME_OF_DAY TEXT CHECK($INTERVENTION_ACTIVITIES_TIME_OF_DAY IN ('morning', 'afternoon', 'evening', 'night')),
  $INTERVENTION_ACTIVITIES_INTENSITY TEXT CHECK($INTERVENTION_ACTIVITIES_INTENSITY IN ('low', 'medium', 'high')),
  $INTERVENTION_ACTIVITIES_MODULE_SPECIFIC_DATA TEXT,
  $INTERVENTION_ACTIVITIES_NOTES TEXT,
  $INTERVENTION_ACTIVITIES_CREATED_AT TEXT NOT NULL,
  $INTERVENTION_ACTIVITIES_UPDATED_AT TEXT NOT NULL,
  $INTERVENTION_ACTIVITIES_SYNCED_AT TEXT,
  $INTERVENTION_ACTIVITIES_IS_DELETED INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY ($INTERVENTION_ACTIVITIES_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE,
  FOREIGN KEY ($INTERVENTION_ACTIVITIES_MODULE_ID) REFERENCES $TABLE_MODULES($MODULES_ID) ON DELETE CASCADE
);

-- ============================================================================
-- User Sleep Baselines Table
-- ============================================================================
CREATE TABLE $TABLE_USER_SLEEP_BASELINES (
  $USER_SLEEP_BASELINES_ID TEXT PRIMARY KEY,
  $USER_SLEEP_BASELINES_USER_ID TEXT NOT NULL,
  $USER_SLEEP_BASELINES_BASELINE_TYPE TEXT NOT NULL CHECK($USER_SLEEP_BASELINES_BASELINE_TYPE IN ('7_day', '30_day', 'all_time')),
  $USER_SLEEP_BASELINES_METRIC_NAME TEXT NOT NULL,
  $USER_SLEEP_BASELINES_METRIC_VALUE REAL NOT NULL,
  $USER_SLEEP_BASELINES_DATA_RANGE_START TEXT NOT NULL,
  $USER_SLEEP_BASELINES_DATA_RANGE_END TEXT NOT NULL,
  $USER_SLEEP_BASELINES_COMPUTED_AT TEXT NOT NULL,
  FOREIGN KEY ($USER_SLEEP_BASELINES_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE,
  UNIQUE($USER_SLEEP_BASELINES_USER_ID, $USER_SLEEP_BASELINES_BASELINE_TYPE, $USER_SLEEP_BASELINES_METRIC_NAME, $USER_SLEEP_BASELINES_DATA_RANGE_END)
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

CREATE INDEX idx_sleep_records_user_date ON $TABLE_SLEEP_RECORDS($SLEEP_RECORDS_USER_ID, $SLEEP_RECORDS_SLEEP_DATE);
CREATE INDEX idx_sleep_records_quality ON $TABLE_SLEEP_RECORDS($SLEEP_RECORDS_USER_ID, $SLEEP_RECORDS_QUALITY_RATING);
CREATE INDEX idx_intervention_activities_user_date ON $TABLE_INTERVENTION_ACTIVITIES($INTERVENTION_ACTIVITIES_USER_ID, $INTERVENTION_ACTIVITIES_ACTIVITY_DATE);
CREATE INDEX idx_intervention_activities_module ON $TABLE_INTERVENTION_ACTIVITIES($INTERVENTION_ACTIVITIES_MODULE_ID, $INTERVENTION_ACTIVITIES_ACTIVITY_DATE);
CREATE INDEX idx_baselines_user ON $TABLE_USER_SLEEP_BASELINES($USER_SLEEP_BASELINES_USER_ID, $USER_SLEEP_BASELINES_BASELINE_TYPE, $USER_SLEEP_BASELINES_METRIC_NAME);
CREATE INDEX idx_user_modules_user ON $TABLE_USER_MODULE_CONFIGURATIONS($USER_MODULE_CONFIGS_USER_ID);

-- ============================================================================
-- Pre-populate Modules Table
-- ============================================================================

INSERT INTO $TABLE_MODULES ($MODULES_ID, $MODULES_NAME, $MODULES_DISPLAY_NAME, $MODULES_DESCRIPTION, $MODULES_IS_ACTIVE, $MODULES_CREATED_AT)
VALUES
  ('light', 'light', 'Light Therapy', 'Morning and evening light exposure optimization', 1, datetime('now')),
  ('sport', 'sport', 'Exercise & Movement', 'Physical activity and exercise routines', 1, datetime('now')),
  ('temperature', 'temperature', 'Temperature Exposure', 'Sauna, heat and cold exposure protocols', 1, datetime('now')),
  ('nutrition', 'nutrition', 'Sleep-Promoting Nutrition', 'Foods and supplements for better sleep', 1, datetime('now')),
  ('mealtime', 'mealtime', 'Meal Timing', 'Eating schedule optimization', 1, datetime('now')),
  ('sleep_hygiene', 'sleep_hygiene', 'Sleep Hygiene', 'Bedtime routine and environment optimization', 1, datetime('now')),
  ('meditation', 'meditation', 'Meditation & Relaxation', 'Mindfulness and relaxation techniques', 1, datetime('now')),
  ('journaling', 'journaling', 'Sleep Journaling', 'Progress tracking and reflection', 1, datetime('now')),
  ('medication', 'medication', 'Medication Tracking', 'Track medication and effects on sleep', 1, datetime('now'));
''';
