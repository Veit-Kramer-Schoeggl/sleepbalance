# Migration V6: Light Module Optimizations

**Version:** 6
**Status:** ⚠️ DISABLED
**Purpose:** Light module-specific database optimizations (index + validation triggers)

## Overview

Migration V6 was created to add Light module-specific database optimizations:
1. Partial index for efficient Light module activity queries
2. Validation triggers to enforce Light therapy duration constraints (5-120 minutes)

**Current Status:** This migration is **disabled** due to SQLite multi-statement execution limitations in sqflite.

## Intended Changes

### 1. Partial Index for Light Module

```sql
CREATE INDEX IF NOT EXISTS idx_intervention_activities_light
ON intervention_activities(user_id, module_id, activity_date)
WHERE module_id = 'light';
```

**Purpose:**
- Faster queries for Light module activities
- Uses partial index (WHERE clause) to only index Light module rows
- Reduces index size and improves query performance

**Use Case:**
```sql
-- Query Light therapy history for user (would use this index)
SELECT * FROM intervention_activities
WHERE user_id = 'user123'
  AND module_id = 'light'
  AND activity_date >= '2025-10-01'
ORDER BY activity_date DESC;
```

---

### 2. Validation Triggers

#### Trigger on INSERT

```sql
CREATE TRIGGER IF NOT EXISTS validate_light_duration_insert
BEFORE INSERT ON intervention_activities
WHEN NEW.module_id = 'light' AND NEW.duration_minutes IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'Light therapy duration must be between 5 and 120 minutes')
  WHERE NEW.duration_minutes NOT BETWEEN 5 AND 120;
END;
```

#### Trigger on UPDATE

```sql
CREATE TRIGGER IF NOT EXISTS validate_light_duration_update
BEFORE UPDATE ON intervention_activities
WHEN NEW.module_id = 'light' AND NEW.duration_minutes IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'Light therapy duration must be between 5 and 120 minutes')
  WHERE NEW.duration_minutes NOT BETWEEN 5 AND 120;
END;
```

**Purpose:**
- Enforce Light module business rules at database level
- Prevent invalid duration values (< 5 minutes or > 2 hours)
- Provides data integrity safety net beyond application validation

**Rationale:**
- Clinical guidelines: Light therapy sessions typically 10-60 minutes
- 5-minute minimum: Too short to be effective
- 120-minute maximum: Safety limit (prolonged exposure can cause eye strain)

---

## Why Migration V6 is Disabled

**Technical Issue:** SQLite triggers must be executed as separate statements, but sqflite's migration system passes entire migration strings to a single `execute()` call.

**Problem:**
```dart
// This doesn't work - only first statement executes
await db.execute('''
  CREATE INDEX ...;
  CREATE TRIGGER ...;  -- Never executed
  CREATE TRIGGER ...;  -- Never executed
''');
```

**Attempted Solution:**
Created `executeMigrationV6(Database db)` function that executes each statement separately:

```dart
Future<void> executeMigrationV6(Database db) async {
  await db.execute(MIGRATION_V6_INDEX);
  await db.execute(MIGRATION_V6_TRIGGER_INSERT);
  await db.execute(MIGRATION_V6_TRIGGER_UPDATE);
}
```

**Current Status:**
- Function exists in `migration_v6.dart`
- NOT called in `database_helper.dart` (commented out)
- Migration skipped during database creation and upgrades

---

## Impact of Disabled Migration

**Good News:** V6 optimizations are **nice-to-have, not required** for functionality.

### What Still Works:

1. **Light Module Functionality:** ✅ Fully functional
   - Activities can be created and tracked
   - All queries work (just slightly slower without partial index)
   - Existing composite index still used: `idx_intervention_activities_user_date`

2. **Duration Validation:** ✅ Handled at application layer
   - Repository validates duration before INSERT
   - UI prevents invalid input
   - No database-level enforcement, but app-level is sufficient

### Performance Impact:

- **Minimal:** Light module queries use existing index on `(user_id, activity_date)`
- **Partial index would help** if querying Light module specifically (rare)
- **Most queries** filter by date first, then module (existing index works well)

---

## Future Resolution Options

### Option 1: Custom Migration System (Recommended)
Implement custom migration runner that executes multi-statement migrations:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  for (int version = oldVersion + 1; version <= newVersion; version++) {
    switch (version) {
      case 6:
        await executeMigrationV6(db);  // Custom execution
        break;
      default:
        await _executeMultiStatement(db, getMigration(version));
    }
  }
}
```

### Option 2: Move to V9 with Proper Execution
Re-implement V6 changes in a future migration (V9+) with proper multi-statement handling.

### Option 3: Accept Application-Layer Validation
Keep validation in repository layer, skip database triggers entirely (current approach).

---

## Migration Script Location

`lib/core/database/migrations/migration_v6.dart`

## Applied

**Never applied** - migration skipped in database creation and upgrade logic.

## Notes

- Commented out in `database_helper.dart`: Lines 106-110, 197-200
- All 3 SQL components defined separately for easy individual execution
- `executeMigrationV6()` function ready to use once migration system supports it
- Not blocking any features - Light module works perfectly without V6
- Future modules (Sport, Meditation, etc.) won't need similar triggers if we rely on app-level validation
