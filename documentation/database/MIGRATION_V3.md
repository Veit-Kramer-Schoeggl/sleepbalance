# Migration V3: Sleep Tables (Compatibility)

**Version:** 3
**Status:** ✅ Active (Compatibility Mode)
**Purpose:** Ensures sleep_records and user_sleep_baselines tables exist

## Overview

Migration V3 was originally created to add sleep tracking tables but these tables were later moved to Migration V1. This migration now uses `CREATE TABLE IF NOT EXISTS` to ensure backward compatibility with databases that might have been created before the refactoring.

**Note:** If the database was created with Migration V1, these tables already exist. The `IF NOT EXISTS` clause prevents errors during sequential migration execution.

## Tables Created/Verified

### 1. `sleep_records` (IF NOT EXISTS)

Identical to V1 specification with one addition:

**Additional Column in V3:**
- `avg_heart_rate_variability` (REAL) - Duplicate of `avg_hrv` field (legacy compatibility)

**Key Difference from V1:**
- V3 version lacks the `UNIQUE(user_id, sleep_date)` constraint
- V3 version has relaxed `quality_rating` CHECK constraint (accepts any TEXT, not just 'bad'/'average'/'good')

For full table specification, see [MIGRATION_V1.md](./MIGRATION_V1.md#2-sleep_records).

---

### 2. `user_sleep_baselines` (IF NOT EXISTS)

**Key Difference from V1:**
- V3 version lacks the `CHECK` constraint on `baseline_type`
- V3 version lacks the `UNIQUE` constraint on `(user_id, baseline_type, metric_name, data_range_end)`

For full table specification, see [MIGRATION_V1.md](./MIGRATION_V1.md#6-user_sleep_baselines).

## Indexes Created

- `idx_sleep_records_user_date` on `sleep_records(user_id, sleep_date)` (IF NOT EXISTS)
- `idx_user_sleep_baselines_user_type` on `user_sleep_baselines(user_id, baseline_type)` (IF NOT EXISTS)

## Migration Script Location

`lib/core/database/migrations/migration_v3.dart`

## Applied

This migration is applied during:
- Fresh database creation (version 3+) - Tables likely already exist from V1
- Upgrade from version 2 to version 3+

## Why This Migration Exists

This migration is part of a refactoring history:

1. **Original Design:** Sleep tables were planned for V3
2. **Refactoring:** Core tables consolidated into V1 for cleaner initial schema
3. **Compatibility:** V3 kept with `IF NOT EXISTS` to support existing databases and sequential migration logic

## Migration Strategy

The database helper applies migrations sequentially (V1 → V2 → V3 → ...). With `IF NOT EXISTS`:
- ✅ Fresh install at V8: V1 creates tables, V3 skips (already exist)
- ✅ Upgrade from V2 to V8: V3 creates tables (don't exist yet)
- ✅ No conflicts or errors either way

## Notes

- Minor schema differences (missing constraints) between V1 and V3 versions
- In practice, V1 version is used (since it runs first)
- V3 acts as safety net for databases that might have skipped V1
- Future cleanup: Could remove V3 once all users are on V1+ schema
