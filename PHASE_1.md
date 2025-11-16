# PHASE 1: Infrastructure Setup

## Overview
Set up foundational architecture for MVVM + Provider pattern: add dependencies, create database layer, establish base patterns for repositories and models.

## Prerequisites
- None (this is the starting phase)
- Existing codebase is functional

## Goals
- Add required packages for Provider, SQLite, JSON serialization
- Create database helper with migration system
- Establish UUID generation for local-first IDs
- Define database constants for consistency
- Create initial database schema (Version 1)

---

## Step 1.1: Update Dependencies

**File:** `pubspec.yaml`
**Purpose:** Add packages required for MVVM + Provider + Database architecture
**Action:** Add to dependencies and dev_dependencies sections

**Dependencies to Add:**
```yaml
dependencies:
  provider: ^6.1.1              # State management
  sqflite: ^2.3.0               # Local SQLite database
  path_provider: ^2.1.1         # File system paths
  path: ^1.8.3                  # Path manipulation
  uuid: ^4.2.0                  # UUID generation
  json_annotation: ^4.8.1       # JSON serialization annotations

dev_dependencies:
  build_runner: ^2.4.6          # Code generation
  json_serializable: ^6.7.1     # JSON serialization generator
```

**Testing:** Run `flutter pub get` to verify no conflicts

---

## Step 1.2: Create UUID Generator Utility

**File:** `lib/core/utils/uuid_generator.dart`
**Purpose:** Generate UUIDs for local-first database IDs
**Dependencies:** `package:uuid/uuid.dart`

**Class: UuidGenerator**
- `static final Uuid _uuid` - Private UUID instance
- `static String generate()` - Returns a new UUID v4 string

**Why:** UUIDs allow offline ID generation without server coordination

---

## Step 1.3: Create Database Constants

**File:** `lib/shared/constants/database_constants.dart`
**Purpose:** Centralize all database table and column names
**Dependencies:** None

**Constants:**

**Database Config:**
- `DATABASE_NAME` - 'sleepbalance.db'
- `DATABASE_VERSION` - 1

**Table Names:**
- `TABLE_USERS` - 'users'
- `TABLE_SLEEP_RECORDS` - 'sleep_records'
- `TABLE_MODULES` - 'modules'
- `TABLE_USER_MODULE_CONFIGURATIONS` - 'user_module_configurations'
- `TABLE_INTERVENTION_ACTIVITIES` - 'intervention_activities'
- `TABLE_USER_SLEEP_BASELINES` - 'user_sleep_baselines'

**Users Table Columns:**
- `USERS_ID`, `USERS_EMAIL`, `USERS_PASSWORD_HASH`
- `USERS_FIRST_NAME`, `USERS_LAST_NAME`, `USERS_BIRTH_DATE`
- `USERS_TIMEZONE`, `USERS_TARGET_SLEEP_DURATION`
- `USERS_CREATED_AT`, `USERS_UPDATED_AT`, `USERS_SYNCED_AT`, `USERS_IS_DELETED`

**Sleep Records Table Columns:**
- `SLEEP_RECORDS_ID`, `SLEEP_RECORDS_USER_ID`, `SLEEP_RECORDS_SLEEP_DATE`
- `SLEEP_RECORDS_BED_TIME`, `SLEEP_RECORDS_SLEEP_START_TIME`
- `SLEEP_RECORDS_TOTAL_SLEEP_TIME`, `SLEEP_RECORDS_DEEP_SLEEP_DURATION`
- `SLEEP_RECORDS_REM_SLEEP_DURATION`, `SLEEP_RECORDS_LIGHT_SLEEP_DURATION`
- `SLEEP_RECORDS_AVG_HEART_RATE`, `SLEEP_RECORDS_AVG_HRV`
- `SLEEP_RECORDS_QUALITY_RATING`, `SLEEP_RECORDS_QUALITY_NOTES`
- `SLEEP_RECORDS_DATA_SOURCE`, `SLEEP_RECORDS_CREATED_AT`

**Modules Table Columns:**
- `MODULES_ID`, `MODULES_NAME`, `MODULES_DISPLAY_NAME`
- `MODULES_DESCRIPTION`, `MODULES_ICON`, `MODULES_IS_ACTIVE`

**User Module Configurations Columns:**
- `USER_MODULE_CONFIGS_ID`, `USER_MODULE_CONFIGS_USER_ID`
- `USER_MODULE_CONFIGS_MODULE_ID`, `USER_MODULE_CONFIGS_IS_ENABLED`
- `USER_MODULE_CONFIGS_CONFIGURATION`, `USER_MODULE_CONFIGS_ENROLLED_AT`

**Intervention Activities Columns:**
- `INTERVENTION_ACTIVITIES_ID`, `INTERVENTION_ACTIVITIES_USER_ID`
- `INTERVENTION_ACTIVITIES_MODULE_ID`, `INTERVENTION_ACTIVITIES_ACTIVITY_DATE`
- `INTERVENTION_ACTIVITIES_WAS_COMPLETED`, `INTERVENTION_ACTIVITIES_COMPLETED_AT`
- `INTERVENTION_ACTIVITIES_DURATION_MINUTES`, `INTERVENTION_ACTIVITIES_TIME_OF_DAY`
- `INTERVENTION_ACTIVITIES_INTENSITY`, `INTERVENTION_ACTIVITIES_MODULE_SPECIFIC_DATA`
- `INTERVENTION_ACTIVITIES_NOTES`, `INTERVENTION_ACTIVITIES_CREATED_AT`

**User Sleep Baselines Columns:**
- `USER_SLEEP_BASELINES_ID`, `USER_SLEEP_BASELINES_USER_ID`
- `USER_SLEEP_BASELINES_BASELINE_TYPE`, `USER_SLEEP_BASELINES_METRIC_NAME`
- `USER_SLEEP_BASELINES_METRIC_VALUE`, `USER_SLEEP_BASELINES_DATA_RANGE_START`
- `USER_SLEEP_BASELINES_DATA_RANGE_END`, `USER_SLEEP_BASELINES_COMPUTED_AT`

**Why:** Prevents typos, enables refactoring, centralizes schema definition

---

## Step 1.4: Create Migration V1 (Initial Schema)

**File:** `lib/core/database/migrations/migration_v1.dart`
**Purpose:** Define initial database schema as SQL string
**Dependencies:** `database_constants.dart`

**Constant: MIGRATION_V1**
- Single multi-line SQL string containing:
  - CREATE TABLE statements for all 6 tables
  - INSERT statements for pre-populating modules table (9 modules)
  - CREATE INDEX statements for performance

**Tables Created:**
1. `users` - User profiles and preferences
2. `sleep_records` - Nightly sleep data from wearables
3. `modules` - Intervention module definitions
4. `user_module_configurations` - User's module settings (JSON config)
5. `intervention_activities` - Daily intervention tracking (hybrid: typed + JSON)
6. `user_sleep_baselines` - Computed personal averages

**Pre-populated Data:**
- 9 module records: light, sport, temperature, nutrition, mealtime, sleep_hygiene, meditation, journaling, medication

**Indexes Created:**
- `idx_sleep_records_user_date` on sleep_records(user_id, sleep_date)
- `idx_sleep_records_quality` on sleep_records(user_id, quality_rating)
- `idx_intervention_activities_user_date` on intervention_activities(user_id, activity_date)
- `idx_intervention_activities_module` on intervention_activities(module_id, activity_date)
- `idx_baselines_user` on user_sleep_baselines(user_id, baseline_type, metric_name)
- `idx_user_modules_user` on user_module_configurations(user_id)

**Why:** Version-controlled schema allows safe migrations as app evolves

---

## Step 1.5: Create Database Helper

**File:** `lib/core/database/database_helper.dart`
**Purpose:** Manage SQLite database lifecycle, handle migrations, provide database instance
**Dependencies:** `sqflite`, `path_provider`, `path`, `migration_v1.dart`

**Class: DatabaseHelper**
- `static final DatabaseHelper instance` - Singleton instance
- `static Database? _database` - Cached database instance
- `DatabaseHelper._privateConstructor()` - Private constructor for singleton

**Methods:**

**`Future<Database> get database`**
- Getter that returns existing database or initializes if null
- Lazy initialization pattern

**`Future<Database> _initDatabase()`**
- Gets app documents directory path
- Constructs database file path
- Calls `openDatabase()` with version and onCreate callback
- Returns Database instance

**`Future<void> _onCreate(Database db, int version)`**
- Called when database is created for first time
- Executes appropriate migration based on version number
- For version 1: Executes MIGRATION_V1 SQL

**`Future<void> _onUpgrade(Database db, int oldVersion, int newVersion)`**
- Called when database version increases
- Executes migrations sequentially from oldVersion to newVersion
- Placeholder for future migrations (v2, v3, etc.)

**`Future<void> close()`**
- Closes database connection
- Sets _database to null

**`Future<void> deleteDatabase()`**
- Deletes database file (for testing/reset)
- Useful during development

**Why:** Centralized database management, handles versioning, ensures single instance

---

## Step 1.6: Create Database Constants Directory

**Directory:** `lib/core/database/migrations/`
**Purpose:** House all migration files
**Action:** Create directory structure (migration_v1.dart already goes here)

**Future Files:**
- `migration_v2.dart` - Future schema changes
- `migration_v3.dart` - More future changes
- `migration_registry.dart` - (Optional) Migration orchestrator

---

## Testing Checklist

### Manual Tests:
- [ ] Run `flutter pub get` - Should complete without errors
- [ ] Build app - Should compile without errors
- [ ] Launch app - Should initialize database
- [ ] Check app documents directory - `sleepbalance.db` file should exist
- [ ] Use SQLite browser to inspect database - All 6 tables should exist
- [ ] Verify modules table - Should have 9 pre-populated rows

### Unit Tests to Create:
- [ ] Test UuidGenerator.generate() returns valid UUID format
- [ ] Test DatabaseHelper.instance is singleton
- [ ] Test database initialization creates all tables
- [ ] Test migration system (mock oldVersion/newVersion)

### Validation Queries:
```sql
-- Check all tables exist
SELECT name FROM sqlite_master WHERE type='table';

-- Check modules are populated
SELECT id, display_name FROM modules;

-- Check indexes exist
SELECT name FROM sqlite_master WHERE type='index';
```

---

## Rollback Strategy

**If Phase 1 fails:**
1. Remove added dependencies from `pubspec.yaml`
2. Delete created files:
   - `lib/core/database/` directory
   - `lib/core/utils/uuid_generator.dart`
   - `lib/shared/constants/database_constants.dart`
3. Run `flutter clean && flutter pub get`
4. App reverts to original state (no database layer)

**Safe because:**
- No existing files modified in Phase 1
- Only additive changes
- Database file is local to app, can be deleted

---

## Next Steps

After Phase 1 completion:
- Proceed to **PHASE_2.md** - Refactor Action Center as pilot feature
- Action Center will be first screen to use database + ViewModel + Provider
- Validates entire architecture before rolling out to other screens

---

## Notes

**Why start with database?**
- Foundation for all data persistence
- ViewModels need repositories which need database
- Better to catch database issues early

**Why UUID generation?**
- Local-first architecture requires client-generated IDs
- UUIDs prevent ID collisions when syncing to server later
- No need for auto-increment integers

**Why constants file?**
- Prevents SQL typos (compile-time checking)
- Easier to refactor table/column names
- Centralizes schema definition

**Estimated Time:** 2-3 hours
- Adding dependencies: 10 minutes
- UUID generator: 15 minutes
- Database constants: 30 minutes
- Migration V1: 45 minutes
- Database helper: 60 minutes
- Testing: 30 minutes
