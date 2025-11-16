// ignore_for_file: constant_identifier_names

import '../../../shared/constants/database_constants.dart';

/// Migration V2: Add Daily Actions Table
///
/// Adds daily_actions table to support Action Center feature.
/// This table stores user's daily action items (tasks/habits) with completion tracking.
///
/// Schema additions:
/// - daily_actions table with date-based tracking
/// - Index for efficient user+date queries
const String MIGRATION_V2 = '''
-- ============================================================================
-- Daily Actions Table
-- ============================================================================
CREATE TABLE $TABLE_DAILY_ACTIONS (
  $DAILY_ACTIONS_ID TEXT PRIMARY KEY,
  $DAILY_ACTIONS_USER_ID TEXT NOT NULL,
  $DAILY_ACTIONS_TITLE TEXT NOT NULL,
  $DAILY_ACTIONS_ICON_NAME TEXT NOT NULL,
  $DAILY_ACTIONS_IS_COMPLETED INTEGER NOT NULL DEFAULT 0,
  $DAILY_ACTIONS_ACTION_DATE TEXT NOT NULL,
  $DAILY_ACTIONS_CREATED_AT TEXT NOT NULL,
  $DAILY_ACTIONS_COMPLETED_AT TEXT,
  FOREIGN KEY ($DAILY_ACTIONS_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE
);

CREATE INDEX idx_daily_actions_user_date ON $TABLE_DAILY_ACTIONS($DAILY_ACTIONS_USER_ID, $DAILY_ACTIONS_ACTION_DATE);
''';
