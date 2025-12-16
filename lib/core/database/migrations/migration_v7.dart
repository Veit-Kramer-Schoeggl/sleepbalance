// ignore_for_file: constant_identifier_names

import '../../../shared/constants/database_constants.dart';

/// Migration V7: Wearables Integration Tables
///
/// Creates tables for storing wearable device connections and sync history:
/// - wearable_connections: OAuth credentials and connection metadata
/// - wearable_sync_history: Sync attempt logging for debugging and transparency
///
/// Added in Phase 7 (Wearables Integration - Phase 1: Foundation)

const String MIGRATION_V7 = '''
-- ============================================================================
-- Wearable Connections Table
-- ============================================================================
-- Stores OAuth credentials and connection status for wearable devices
-- Each user can have one connection per provider (enforced by UNIQUE constraint)

CREATE TABLE IF NOT EXISTS $TABLE_WEARABLE_CONNECTIONS (
  $WEARABLE_CONNECTIONS_ID TEXT PRIMARY KEY,
  $WEARABLE_CONNECTIONS_USER_ID TEXT NOT NULL,
  $WEARABLE_CONNECTIONS_PROVIDER TEXT NOT NULL CHECK($WEARABLE_CONNECTIONS_PROVIDER IN ('fitbit', 'apple_health', 'google_fit', 'garmin')),

  -- OAuth tokens
  $WEARABLE_CONNECTIONS_ACCESS_TOKEN TEXT NOT NULL,
  $WEARABLE_CONNECTIONS_REFRESH_TOKEN TEXT,
  $WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT TEXT,

  -- Provider-specific metadata
  $WEARABLE_CONNECTIONS_USER_EXTERNAL_ID TEXT,
  $WEARABLE_CONNECTIONS_GRANTED_SCOPES TEXT,

  -- Connection status
  $WEARABLE_CONNECTIONS_IS_ACTIVE INTEGER NOT NULL DEFAULT 1,
  $WEARABLE_CONNECTIONS_CONNECTED_AT TEXT NOT NULL,
  $WEARABLE_CONNECTIONS_LAST_SYNC_AT TEXT,

  -- Standard fields
  $WEARABLE_CONNECTIONS_CREATED_AT TEXT NOT NULL,
  $WEARABLE_CONNECTIONS_UPDATED_AT TEXT NOT NULL,

  FOREIGN KEY ($WEARABLE_CONNECTIONS_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE,
  UNIQUE($WEARABLE_CONNECTIONS_USER_ID, $WEARABLE_CONNECTIONS_PROVIDER)
);

-- Index for quick lookups by user
CREATE INDEX IF NOT EXISTS idx_wearable_connections_user
  ON $TABLE_WEARABLE_CONNECTIONS($WEARABLE_CONNECTIONS_USER_ID);

-- Index for quick lookups by provider and active status
CREATE INDEX IF NOT EXISTS idx_wearable_connections_provider_active
  ON $TABLE_WEARABLE_CONNECTIONS($WEARABLE_CONNECTIONS_PROVIDER, $WEARABLE_CONNECTIONS_IS_ACTIVE);

-- ============================================================================
-- Wearable Sync History Table
-- ============================================================================
-- Logs all sync attempts for debugging, transparency, and analytics
-- Helps track when data was last synced and identify sync failures

CREATE TABLE IF NOT EXISTS $TABLE_WEARABLE_SYNC_HISTORY (
  $WEARABLE_SYNC_HISTORY_ID TEXT PRIMARY KEY,
  $WEARABLE_SYNC_HISTORY_USER_ID TEXT NOT NULL,
  $WEARABLE_SYNC_HISTORY_PROVIDER TEXT NOT NULL,

  -- Sync window
  $WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM TEXT NOT NULL,
  $WEARABLE_SYNC_HISTORY_SYNC_DATE_TO TEXT NOT NULL,

  -- Timing
  $WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT TEXT NOT NULL,
  $WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT TEXT,

  -- Results
  $WEARABLE_SYNC_HISTORY_STATUS TEXT NOT NULL CHECK($WEARABLE_SYNC_HISTORY_STATUS IN ('success', 'failed', 'partial')),
  $WEARABLE_SYNC_HISTORY_RECORDS_FETCHED INTEGER NOT NULL DEFAULT 0,
  $WEARABLE_SYNC_HISTORY_RECORDS_INSERTED INTEGER NOT NULL DEFAULT 0,
  $WEARABLE_SYNC_HISTORY_RECORDS_UPDATED INTEGER NOT NULL DEFAULT 0,
  $WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED INTEGER NOT NULL DEFAULT 0,

  -- Error information
  $WEARABLE_SYNC_HISTORY_ERROR_CODE TEXT,
  $WEARABLE_SYNC_HISTORY_ERROR_MESSAGE TEXT,

  FOREIGN KEY ($WEARABLE_SYNC_HISTORY_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE
);

-- Index for quick lookups by user and sync time
CREATE INDEX IF NOT EXISTS idx_sync_history_user_time
  ON $TABLE_WEARABLE_SYNC_HISTORY($WEARABLE_SYNC_HISTORY_USER_ID, $WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT);

-- Index for filtering by sync status
CREATE INDEX IF NOT EXISTS idx_sync_history_status
  ON $TABLE_WEARABLE_SYNC_HISTORY($WEARABLE_SYNC_HISTORY_STATUS);
''';
