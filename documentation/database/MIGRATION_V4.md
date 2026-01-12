# Migration V4: Users Table (Compatibility)

**Version:** 4
**Status:** ✅ Active (Compatibility Mode)
**Purpose:** Ensures users table exists

## Overview

Migration V4 was originally created to add the `users` table but this table was later moved to Migration V1. This migration now uses `CREATE TABLE IF NOT EXISTS` to ensure backward compatibility with databases that might have been created before the refactoring.

**Note:** If the database was created with Migration V1, this table already exists. The `IF NOT EXISTS` clause prevents errors during sequential migration execution.

## Table Created/Verified

### `users` (IF NOT EXISTS)

Stores user profiles, authentication credentials, sleep preferences, and health context.

**Schema:** Identical to V1 specification.

For full table specification, see [MIGRATION_V1.md](./MIGRATION_V1.md#1-users).

## Indexes Created

- `idx_users_email` on `users(email)` (IF NOT EXISTS)

## Default User Creation

**Important:** For database versions 4-7, a default user was automatically created during fresh installation to enable immediate app usage without authentication:

```dart
{
  id: UUID,
  email: 'default@sleepbalance.app',
  first_name: 'Sleep',
  last_name: 'User',
  birth_date: '1990-01-01',
  timezone: 'UTC',
  target_sleep_duration: 480, // 8 hours
  preferred_unit_system: 'metric',
  language: 'en',
  has_sleep_disorder: 0,
  takes_sleep_medication: 0,
  email_verified: 1  // Pre-verified
}
```

**Note:** As of V8, default user creation is disabled. V8+ requires proper user registration with email verification.

## Migration Script Location

`lib/core/database/migrations/migration_v4.dart`

## Applied

This migration is applied during:
- Fresh database creation (version 4+) - Table likely already exists from V1
- Upgrade from version 3 to version 4+

## Why This Migration Exists

Similar to V3, this migration is part of refactoring history:

1. **Original Design:** Users table planned for V4
2. **Refactoring:** Moved to V1 for logical grouping with core schema
3. **Compatibility:** V4 kept with `IF NOT EXISTS` to support existing databases

## Migration Strategy

Sequential migration execution with `IF NOT EXISTS`:
- ✅ Fresh install at V8: V1 creates table, V4 skips (already exists)
- ✅ Upgrade from V3 to V8: V4 creates table (doesn't exist yet)
- ✅ No conflicts or errors

## Notes

- Users table is fundamental to entire schema (required by foreign keys)
- Default user creation simplifies development but is removed in production (V8+)
- V1 and V4 versions are identical
- Future cleanup: Could remove V4 once all users are on V1+ schema
