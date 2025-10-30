# PHASE 4: Settings & User Profile - Data Layer

## Overview
Create user management system data layer: database migration, User model, repository pattern, and default user setup. UI implementation will be done separately.

## Prerequisites
- **Phase 1 completed:** Database infrastructure with migrations and constants
- **Phase 2 completed:** Action Center validates MVVM pattern
- **Phase 3 completed:** Night Review validates complex data handling
- **IMPORTANT:** Review Action Center implementation as reference pattern
- Understanding of Provider dependency order (DataSource before Repository)
- **Uninstall app before testing** to force database migration from V2 to V4

## Goals
- Create database migrations FIRST (migration_v4.dart)
- Create User model with proper fromDatabase/toDatabase methods
- Implement UserRepository pattern following Phase 2 example
- Set up default user in database_helper.dart
- Register providers in main.dart
- **Expected outcome:** 0 analyzer warnings, all tests passing
- **Note:** UI layer (ViewModel, Screens) will be implemented separately

---

## Step 4.0: Create Database Migration (DO THIS FIRST!)

**File:** `lib/core/database/migrations/migration_v4.dart`
**Purpose:** Add users table with full profile and preferences
**Dependencies:** None

**CRITICAL:** Create this migration BEFORE creating models! This establishes the database schema.

**Add to file header:**
```dart
// ignore_for_file: constant_identifier_names
/// Migration V4: Users table for profile and preferences
///
/// Creates table for user profiles, authentication, preferences,
/// and sleep-related settings. Supports future multi-user capability.
library;
```

**Class: MigrationV4**

**Static constant: MIGRATION_V4**
- SQL string creating `users` table with all fields from schema
- Add indexes for frequently queried columns: email (unique)
- Include is_deleted for soft delete pattern
- Include synced_at for future cloud sync support

**Example Structure:**
```dart
class MigrationV4 {
  static const String MIGRATION_V4 = '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      birth_date TEXT NOT NULL,
      timezone TEXT NOT NULL,
      target_sleep_duration INTEGER,
      target_bed_time TEXT,
      target_wake_time TEXT,
      has_sleep_disorder INTEGER NOT NULL DEFAULT 0,
      sleep_disorder_type TEXT,
      takes_sleep_medication INTEGER NOT NULL DEFAULT 0,
      preferred_unit_system TEXT NOT NULL DEFAULT 'metric',
      language TEXT NOT NULL DEFAULT 'en',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      synced_at TEXT,
      is_deleted INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX idx_users_email ON users(email);
  ''';
}
```

**Next Steps:**
1. **Users table constants already exist** in `database_constants.dart` (lines 28-49)
2. Update `lib/core/database/database_helper.dart`:
   - Increment `DATABASE_VERSION` to 4
   - Add MIGRATION_V4 to `_onCreate` method
   - Add version 4 case to `_onUpgrade` switch statement
3. **Uninstall app before testing** to force database recreation

**Why:** Following Phase 1/2/3 pattern - migrations first, then models, prevents SQL string hardcoding

---

## Step 4.1: Create Domain Model - User

**File:** `lib/features/settings/domain/models/user.dart`
**Purpose:** User profile and preferences model
**Dependencies:** `json_annotation`

**CRITICAL - Two Conversion Methods Required:**
- **fromJson/toJson:** For API communication (if future backend integration)
- **fromDatabase/toDatabase:** For SQLite operations (must handle DateTime/boolean conversion)

**Class: User**

**Fields:**
- `String id` - UUID primary key
- `String email` - Email address
- `String? passwordHash` - Password (nullable, not used yet)
- `String firstName` - First name
- `String lastName` - Last name
- `DateTime birthDate` - Date of birth
- `String timezone` - IANA timezone (e.g., 'America/New_York')
- `int? targetSleepDuration` - Minutes (nullable, e.g., 480 = 8 hours)
- `String? targetBedTime` - HH:mm format (nullable, e.g., '22:30')
- `String? targetWakeTime` - HH:mm format (nullable)
- `bool hasSleepDisorder` - Default false
- `String? sleepDisorderType` - 'insomnia', 'sleep_apnea', etc. (nullable)
- `bool takesSleepMedication` - Default false
- `String preferredUnitSystem` - 'metric' or 'imperial', default 'metric'
- `String language` - 'en', 'de', etc., default 'en'
- `DateTime createdAt`
- `DateTime updatedAt`

**Methods:**
- Constructor with required and optional named parameters
- `factory User.fromJson(Map<String, dynamic> json)` - Deserialize (API)
- `Map<String, dynamic> toJson()` - Serialize (API)
- **`factory User.fromDatabase(Map<String, dynamic> map)`** - Deserialize from SQLite
  - Use `DatabaseDateUtils.fromString()` for DateTime fields
  - Convert INTEGER (0/1) to bool for has_sleep_disorder, takes_sleep_medication
  - Use DatabaseConstants for all column names
- **`Map<String, dynamic> toDatabase()`** - Serialize to SQLite
  - Use `DatabaseDateUtils.toDateString()` for birthDate (date-only)
  - Use `DatabaseDateUtils.toTimestamp()` for createdAt, updatedAt
  - Convert bool to INTEGER (0/1)
  - Use DatabaseConstants for all column names
- `User copyWith({...})` - Immutable update
- `String get fullName => '$firstName $lastName'`
- `int get age` - Calculate from birthDate to now

**Annotations:**
- `@JsonSerializable()`

**After Creating Model:**
1. Run `dart run build_runner build` to generate `user.g.dart`
2. Verify no analyzer warnings
3. Reference Action Center's `DailyAction` model for pattern

**Pattern Reference:** See `/home/veit/AndroidStudioProjects/sleepbalance/lib/features/action_center/domain/models/daily_action.dart` for fromDatabase/toDatabase implementation

**Why:** Replaces hardcoded 'user123' strings, stores user preferences. Proper DateTime and boolean handling critical for SQLite storage.

---

## Step 4.2: Create Repository Interface

**File:** `lib/features/settings/domain/repositories/user_repository.dart`
**Purpose:** Abstract interface for user operations
**Dependencies:** `user.dart`

**Abstract Class: UserRepository**

**Methods:**
- `Future<User?> getUserById(String userId)` - Get user by ID
- `Future<User?> getUserByEmail(String email)` - Get user by email (for future auth)
- `Future<void> saveUser(User user)` - Insert or update user
- `Future<void> updateUser(User user)` - Update existing user
- `Future<void> deleteUser(String userId)` - Soft delete user
- `Future<List<User>> getAllUsers()` - Get all non-deleted users (for future multi-user)
- `Future<String?> getCurrentUserId()` - Get currently logged-in user ID (from SharedPreferences)
- `Future<void> setCurrentUserId(String userId)` - Set current user in SharedPreferences

**Why:** Abstracts user data access, prepares for authentication

---

## Step 4.3: Create Local Data Source

**File:** `lib/features/settings/data/datasources/user_local_datasource.dart`
**Purpose:** SQLite operations for users table
**Dependencies:** `sqflite`, `database_helper`, `database_constants`, `user`

**Class: UserLocalDataSource**

**Constructor:**
- `UserLocalDataSource({required Database database})`

**Methods:**

**`Future<User?> getUserById(String userId)`**
- Query: `SELECT * FROM ${DatabaseConstants.TABLE_USERS} WHERE ${DatabaseConstants.USERS_ID} = ?`
- **IMPORTANT:** Convert Map to User using **`fromDatabase`** (NOT fromJson!)
- Return user or null if not found

**`Future<User?> getUserByEmail(String email)`**
- Query: `SELECT * FROM ${DatabaseConstants.TABLE_USERS} WHERE ${DatabaseConstants.USERS_EMAIL} = ?`
- **IMPORTANT:** Convert Map to User using **`fromDatabase`**
- Return user or null

**`Future<void> insertUser(User user)`**
- Convert to Map using **`toDatabase()`** (NOT toJson!)
- Use INSERT OR REPLACE for upsert behavior
- Use DatabaseConstants for table name

**`Future<void> updateUser(User user)`**
- Convert to Map using **`toDatabase()`**
- Set updated_at to DateTime.now() converted to ISO 8601
- UPDATE WHERE id = user.id
- Use DatabaseConstants for all column names

**`Future<void> softDeleteUser(String userId)`**
- UPDATE users SET is_deleted = 1, updated_at = ? WHERE id = ?
- Use parameterized queries to prevent SQL injection
- Use DatabaseConstants for column names

**`Future<List<User>> getAllActiveUsers()`**
- Query: `SELECT * FROM ${DatabaseConstants.TABLE_USERS} WHERE ${DatabaseConstants.USERS_IS_DELETED} = 0`
- **IMPORTANT:** Convert List<Map> to List<User> using **`fromDatabase`**
- Order by created_at DESC

**Pattern Reference:** See Action Center's DataSource for database query patterns with constants

---

## Step 4.4: Implement Repository

**File:** `lib/features/settings/data/repositories/user_repository_impl.dart`
**Purpose:** Concrete implementation with datasource + SharedPreferences
**Dependencies:** Repository interface, datasource, `shared_preferences`

**Class: UserRepositoryImpl implements UserRepository**

**Constructor:**
- `UserRepositoryImpl({required UserLocalDataSource dataSource, required SharedPreferences prefs})`

**Fields:**
- `final UserLocalDataSource _dataSource`
- `final SharedPreferences _prefs`
- `static const String _currentUserIdKey = 'current_user_id'`

**Methods:**

**`Future<User?> getUserById(String userId)`**
- Delegates to `_dataSource.getUserById(userId)`

**`Future<User?> getUserByEmail(String email)`**
- Delegates to `_dataSource.getUserByEmail(email)`

**`Future<void> saveUser(User user)`**
- Check if user exists with `getUserById(user.id)`
- If exists: call updateUser
- Else: call `_dataSource.insertUser(user)`

**`Future<void> updateUser(User user)`**
- Create updated user with copyWith to set updatedAt = DateTime.now()
- Delegates to `_dataSource.updateUser(user)`

**`Future<void> deleteUser(String userId)`**
- Delegates to `_dataSource.softDeleteUser(userId)`

**`Future<List<User>> getAllUsers()`**
- Delegates to `_dataSource.getAllActiveUsers()`

**`Future<String?> getCurrentUserId()`**
- Returns `_prefs.getString(_currentUserIdKey)`

**`Future<void> setCurrentUserId(String userId)`**
- Calls `await _prefs.setString(_currentUserIdKey, userId)`

**Why:** Combines database access with session management via SharedPreferences

---

## Step 4.5: Create Default User Setup

**File:** `lib/core/database/database_helper.dart` (modify _onCreate)
**Purpose:** Create default user on first app launch
**Action:** Add to `_onCreate` method after executing MIGRATION_V4

**Additional Code in _onCreate:**
```dart
// After MIGRATION_V4 execution
// Insert default user if none exists
final defaultUserId = UuidGenerator.generate();
final now = DateTime.now();

final defaultUser = {
  DatabaseConstants.USERS_ID: defaultUserId,
  DatabaseConstants.USERS_EMAIL: 'default@sleepbalance.app',
  DatabaseConstants.USERS_FIRST_NAME: 'Sleep',
  DatabaseConstants.USERS_LAST_NAME: 'User',
  DatabaseConstants.USERS_BIRTH_DATE: DatabaseDateUtils.toDateString(DateTime(1990, 1, 1)),
  DatabaseConstants.USERS_TIMEZONE: 'UTC',
  DatabaseConstants.USERS_TARGET_SLEEP_DURATION: 480,
  DatabaseConstants.USERS_PREFERRED_UNIT_SYSTEM: 'metric',
  DatabaseConstants.USERS_LANGUAGE: 'en',
  DatabaseConstants.USERS_HAS_SLEEP_DISORDER: 0,
  DatabaseConstants.USERS_TAKES_SLEEP_MEDICATION: 0,
  DatabaseConstants.USERS_CREATED_AT: DatabaseDateUtils.toTimestamp(now),
  DatabaseConstants.USERS_UPDATED_AT: DatabaseDateUtils.toTimestamp(now),
  DatabaseConstants.USERS_IS_DELETED: 0,
};

await db.insert(DatabaseConstants.TABLE_USERS, defaultUser);

// Note: SharedPreferences will be set in main.dart initialization
```

**Why:** Ensures app has a user to work with before auth is implemented. Uses DatabaseConstants and DatabaseDateUtils for consistency.

---

## Step 4.6: Wire Up Providers in main.dart

**File:** `lib/main.dart`
**Purpose:** Register Settings data layer components with Provider
**Dependencies:** UserLocalDataSource, UserRepository

**CRITICAL - Provider Dependency Order (from Phase 2):**
Datasources MUST be registered BEFORE repositories!

**Add to MultiProvider (after existing providers):**
```dart
// Settings - User DataSource
Provider<UserLocalDataSource>(
  create: (context) => UserLocalDataSource(
    database: context.read<DatabaseHelper>().database,
  ),
),

// Settings - User Repository
Provider<UserRepository>(
  create: (context) => UserRepositoryImpl(
    dataSource: context.read<UserLocalDataSource>(),
    prefs: context.read<SharedPreferences>(),
  ),
),
```

**Additional Setup in main():**
```dart
// After database initialization, set default user ID if not exists
final prefs = await SharedPreferences.getInstance();
if (prefs.getString('current_user_id') == null) {
  final db = await DatabaseHelper.instance.database;
  final users = await db.query(
    DatabaseConstants.TABLE_USERS,
    limit: 1,
  );
  if (users.isNotEmpty) {
    await prefs.setString('current_user_id', users.first['id'] as String);
  }
}
```

**Pattern:** Same as Action Center registration (without ViewModel for now)

**Why:** Proper dependency injection with correct initialization order

---

## Testing Checklist

### Manual Tests (Data Layer):
- [ ] Uninstall app completely
- [ ] Launch app fresh, database should create with V4 schema
- [ ] Verify default user created in database
- [ ] Verify current user ID set in SharedPreferences
- [ ] Check database with SQL query, users table should have correct schema
- [ ] Verify 0 analyzer warnings in terminal

### Unit Tests (Data Layer Only):
- [ ] Test User model fromDatabase/toDatabase with all nullable fields
- [ ] Test User.age calculation with various birthdates
- [ ] Test User.fullName getter
- [ ] Test User model handles null values correctly
- [ ] Test UserLocalDataSource getUserById returns correct user
- [ ] Test UserLocalDataSource getUserByEmail queries correctly
- [ ] Test UserLocalDataSource insertUser stores data correctly
- [ ] Test UserLocalDataSource updateUser modifies existing records
- [ ] Test UserLocalDataSource softDeleteUser sets is_deleted flag
- [ ] Test UserRepositoryImpl getCurrentUserId with mock SharedPreferences
- [ ] Test UserRepositoryImpl setCurrentUserId updates preferences

### Integration Tests (Data Layer):
- [ ] Create user → Save → Fetch → Verify data integrity
- [ ] Update user → Reload → Verify changes persisted
- [ ] Test boolean fields convert correctly (has_sleep_disorder, takes_sleep_medication)
- [ ] Test DateTime fields convert correctly (birthDate, createdAt, updatedAt)
- [ ] Test nullable fields (targetSleepDuration, sleepDisorderType) handle nulls
- [ ] Test soft delete does not return user in getAllActiveUsers
- [ ] Test SharedPreferences integration with repository

### Database Validation:
```sql
-- Check default user exists
SELECT id, first_name, last_name, email, has_sleep_disorder, birth_date
FROM users
WHERE is_deleted = 0;

-- Update user profile
UPDATE users
SET first_name = 'John',
    last_name = 'Doe',
    updated_at = datetime('now')
WHERE id = 'user-id';

-- Verify update
SELECT * FROM users WHERE id = 'user-id';

-- Test soft delete
UPDATE users SET is_deleted = 1 WHERE id = 'user-id';
SELECT * FROM users WHERE is_deleted = 0; -- Should return empty
```

---

## Rollback Strategy

Same as previous phases:
- Keep original SettingsScreen as backup
- Can disable Provider temporarily
- Or full rollback via git: `git checkout HEAD -- lib/features/settings/`

---

## Next Steps

After Phase 4:
- Replace all hardcoded 'user123' strings throughout app
- Update Action Center to use actual user ID from SettingsViewModel
- Update Night Review to use actual user ID
- Proceed to **PHASE_5.md:** Module Management System

---

## Notes

**Why Settings fourth?**
- Foundation for user-specific data
- Replaces hardcoded 'user123' strings
- Needed before implementing personalized modules

**UI Implementation:**
- **UI Implementation will be done separately**
- **See SETTINGS_IMPLEMENTATION_PLAN.md for UI layer details**
- **This phase focuses on data layer only**
- ViewModel, UserProfileScreen, and SettingsScreen refactoring are deferred

**Authentication:**
- For now, single default user
- Phase 5+ can add proper login/signup
- Current setup prepares for multi-user support

**Profile Fields:**
- Sleep disorder info useful for analysis
- Timezone critical for sleep timing calculations
- Unit system affects display formatting

**Database Migration:**
- MUST uninstall app to force V2→V4 migration
- Alternative: Implement proper onUpgrade logic (more complex)
- For development, uninstall is fastest approach

**Key Learnings Applied:**
1. Migration created FIRST (Step 4.0)
2. Models use fromDatabase/toDatabase (separate from fromJson/toJson)
3. DatabaseDateUtils for all DateTime conversions
4. DatabaseConstants for all table/column names
5. Provider dependency order: DataSource → Repository
6. Run build_runner after creating models
7. Goal: 0 analyzer warnings

**Estimated Time:** 3-4 hours (Data Layer Only)
- Migration: 30 minutes
- User model: 45 minutes (with fromDatabase/toDatabase)
- DataSource implementation: 45 minutes
- Repository implementation: 45 minutes
- Default user setup: 45 minutes
- Provider wiring: 15 minutes
- Testing: 30 minutes
