// ignore_for_file: constant_identifier_names

/// Migration V3: Sleep records and baselines tables
///
/// Creates tables for storing nightly sleep data from wearables
/// and computed personal baseline averages.
///
/// Schema additions:
/// - sleep_records table for nightly sleep metrics from wearables
/// - user_sleep_baselines table for personal average calculations
/// - Indexes for efficient date-based queries
library;

import '../../../shared/constants/database_constants.dart';

const String MIGRATION_V3 = '''
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
  $SLEEP_RECORDS_AVG_HEART_RATE_VARIABILITY REAL,
  $SLEEP_RECORDS_AVG_BREATHING_RATE REAL,
  $SLEEP_RECORDS_QUALITY_RATING TEXT,
  $SLEEP_RECORDS_QUALITY_NOTES TEXT,
  $SLEEP_RECORDS_DATA_SOURCE TEXT NOT NULL,
  $SLEEP_RECORDS_CREATED_AT TEXT NOT NULL,
  $SLEEP_RECORDS_UPDATED_AT TEXT NOT NULL,
  $SLEEP_RECORDS_SYNCED_AT TEXT,
  $SLEEP_RECORDS_IS_DELETED INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY ($SLEEP_RECORDS_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE
);

-- Index for user+date queries (most common query pattern)
CREATE INDEX idx_sleep_records_user_date ON $TABLE_SLEEP_RECORDS($SLEEP_RECORDS_USER_ID, $SLEEP_RECORDS_SLEEP_DATE);

-- ============================================================================
-- User Sleep Baselines Table
-- ============================================================================
CREATE TABLE $TABLE_USER_SLEEP_BASELINES (
  $USER_SLEEP_BASELINES_ID TEXT PRIMARY KEY,
  $USER_SLEEP_BASELINES_USER_ID TEXT NOT NULL,
  $USER_SLEEP_BASELINES_BASELINE_TYPE TEXT NOT NULL,
  $USER_SLEEP_BASELINES_METRIC_NAME TEXT NOT NULL,
  $USER_SLEEP_BASELINES_METRIC_VALUE REAL NOT NULL,
  $USER_SLEEP_BASELINES_DATA_RANGE_START TEXT NOT NULL,
  $USER_SLEEP_BASELINES_DATA_RANGE_END TEXT NOT NULL,
  $USER_SLEEP_BASELINES_COMPUTED_AT TEXT NOT NULL,
  FOREIGN KEY ($USER_SLEEP_BASELINES_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE
);

-- Index for baseline lookups by user and type
CREATE INDEX idx_user_sleep_baselines_user_type ON $TABLE_USER_SLEEP_BASELINES($USER_SLEEP_BASELINES_USER_ID, $USER_SLEEP_BASELINES_BASELINE_TYPE);
''';