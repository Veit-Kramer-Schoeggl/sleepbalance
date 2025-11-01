// ignore_for_file: constant_identifier_names

/// Migration V4: Users table for profile and preferences
///
/// Creates table for user profiles, authentication, preferences,
/// and sleep-related settings. Supports future multi-user capability.
library;

import '../../../shared/constants/database_constants.dart';

/// Migration V4: Add Users Table
///
/// Adds users table to support user profiles and settings.
/// This table stores user authentication, preferences, and sleep-related settings.
///
/// Schema additions:
/// - users table with profile and preferences
/// - Index for efficient email queries
const String MIGRATION_V4 = '''
-- ============================================================================
-- Users Table
-- ============================================================================
CREATE TABLE $TABLE_USERS (
  $USERS_ID TEXT PRIMARY KEY,
  $USERS_EMAIL TEXT NOT NULL UNIQUE,
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

CREATE INDEX idx_users_email ON $TABLE_USERS($USERS_EMAIL);
''';