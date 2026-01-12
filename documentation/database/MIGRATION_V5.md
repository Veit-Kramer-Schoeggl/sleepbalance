# Migration V5: User Module Configurations (Compatibility)

**Version:** 5
**Status:** ✅ Active (Compatibility Mode)
**Purpose:** Ensures user_module_configurations table exists with proper indexes

## Overview

Migration V5 was created during Phase 7 (Module System Framework) to ensure the `user_module_configurations` table exists with optimized indexes. This table was already defined in Migration V1, but V5 adds important indexes for query performance and ensures the table exists for databases that might have upgraded from earlier versions.

## Table Created/Verified

### `user_module_configurations` (IF NOT EXISTS)

Stores user-specific module settings and activation status. Each module stores its configuration as JSON for maximum flexibility.

**Schema:** Nearly identical to V1 specification, with one minor difference:

**Difference from V1:**
- V5 version lacks `synced_at` column (will be added in future sync implementation)
- V5 uses hardcoded table/column names instead of constants

For full table specification, see [MIGRATION_V1.md](./MIGRATION_V1.md#4-user_module_configurations).

## Indexes Created

Migration V5 adds three important indexes for query optimization:

1. **`idx_user_module_unique`** - `UNIQUE INDEX` on `(user_id, module_id)`
   - Ensures one configuration per user per module
   - Prevents duplicate configs
   - Enables fast upsert operations

2. **`idx_user_module_user_id`** on `(user_id)`
   - Fast lookups: "Get all modules for this user"
   - Common query pattern in module listing

3. **`idx_user_module_enabled`** on `(user_id, is_enabled)`
   - Fast filtering: "Get user's active modules"
   - Critical for dashboard and intervention tracking

## Use Cases

1. **Module Enrollment:**
   ```dart
   // User enables Light Therapy module
   INSERT INTO user_module_configurations (
     id, user_id, module_id, is_enabled, configuration, enrolled_at, updated_at
   ) VALUES (
     'uuid', 'user123', 'light', 1,
     '{"target_time": "07:30", "target_duration_minutes": 30}',
     '2025-10-29 10:00:00', '2025-10-29 10:00:00'
   );
   ```

2. **Configuration Updates:**
   ```dart
   // User changes light therapy settings
   UPDATE user_module_configurations
   SET configuration = '{"target_time": "08:00", "target_duration_minutes": 45}',
       updated_at = '2025-10-30 09:00:00'
   WHERE user_id = 'user123' AND module_id = 'light';
   ```

3. **Active Module Queries:**
   ```sql
   -- Get all active modules for user (uses idx_user_module_enabled)
   SELECT module_id, configuration
   FROM user_module_configurations
   WHERE user_id = 'user123' AND is_enabled = 1;
   ```

## Phase 7: Module System Framework

This migration was added as part of Phase 7 implementation, which introduced:

- **ModuleInterface:** Standardized interface for all modules
- **ModuleRegistry:** Central registration system for modules
- **ModuleConfigRepository:** Repository pattern for configuration persistence
- **Light Module:** First reference implementation

**Key Design Decision:** JSON configuration storage
- Each module has different settings (Light has "light_type", Sport has "exercise_type")
- Avoids creating 9 separate configuration tables
- Easy to add new configuration options without schema migrations
- Perfect for complex nested objects like notification settings

## Migration Script Location

`lib/core/database/migrations/migration_v5.dart`

## Applied

This migration is applied during:
- Fresh database creation (version 5+)
- Upgrade from version 4 to version 5+

## Migration Strategy

Uses `CREATE TABLE IF NOT EXISTS` and `CREATE INDEX IF NOT EXISTS`:
- ✅ Fresh install: Table exists from V1, indexes are added
- ✅ Upgrade from V4: Table and indexes are created
- ✅ No conflicts

## Notes

- Critical for Phase 7+ module system functionality
- Indexes significantly improve module configuration queries
- UNIQUE index prevents configuration conflicts
- Future: Will add `synced_at` column when backend sync is implemented
- Configuration JSON validated at application layer, not database layer
