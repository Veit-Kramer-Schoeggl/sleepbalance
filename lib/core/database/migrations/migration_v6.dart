// ignore_for_file: constant_identifier_names

import 'package:sqflite/sqflite.dart';
import '../../../shared/constants/database_constants.dart';

/// Migration V6: Light Module Optimizations
///
/// Adds Light module-specific database optimizations:
/// - Index for efficient Light module queries
/// - Validation triggers for Light activity duration (5-120 minutes)
///
/// This migration supports Phase 2: Light Module Implementation
///
/// NOTE: SQLite triggers must be executed as separate statements.
/// This migration provides a function to execute all statements in order.

/// Light Module Index
const String MIGRATION_V6_INDEX = '''
CREATE INDEX IF NOT EXISTS idx_intervention_activities_light
ON $TABLE_INTERVENTION_ACTIVITIES(
  $INTERVENTION_ACTIVITIES_USER_ID,
  $INTERVENTION_ACTIVITIES_MODULE_ID,
  $INTERVENTION_ACTIVITIES_ACTIVITY_DATE
)
WHERE $INTERVENTION_ACTIVITIES_MODULE_ID = 'light'
''';

/// Light Module Validation Trigger (Insert)
const String MIGRATION_V6_TRIGGER_INSERT = '''
CREATE TRIGGER IF NOT EXISTS validate_light_duration_insert
BEFORE INSERT ON $TABLE_INTERVENTION_ACTIVITIES
WHEN NEW.$INTERVENTION_ACTIVITIES_MODULE_ID = 'light'
  AND NEW.$INTERVENTION_ACTIVITIES_DURATION_MINUTES IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'Light therapy duration must be between 5 and 120 minutes')
  WHERE NEW.$INTERVENTION_ACTIVITIES_DURATION_MINUTES NOT BETWEEN 5 AND 120;
END
''';

/// Light Module Validation Trigger (Update)
const String MIGRATION_V6_TRIGGER_UPDATE = '''
CREATE TRIGGER IF NOT EXISTS validate_light_duration_update
BEFORE UPDATE ON $TABLE_INTERVENTION_ACTIVITIES
WHEN NEW.$INTERVENTION_ACTIVITIES_MODULE_ID = 'light'
  AND NEW.$INTERVENTION_ACTIVITIES_DURATION_MINUTES IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'Light therapy duration must be between 5 and 120 minutes')
  WHERE NEW.$INTERVENTION_ACTIVITIES_DURATION_MINUTES NOT BETWEEN 5 AND 120;
END
''';

/// Execute all Migration V6 statements
///
/// Sqflite requires each CREATE TRIGGER statement to be executed separately.
/// This function executes all V6 migration statements in the correct order.
Future<void> executeMigrationV6(Database db) async {
  await db.execute(MIGRATION_V6_INDEX);
  await db.execute(MIGRATION_V6_TRIGGER_INSERT);
  await db.execute(MIGRATION_V6_TRIGGER_UPDATE);
}
