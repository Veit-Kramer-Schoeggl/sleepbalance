# Phase 4 Implementation Prompt

## Context
You are implementing **Phase 4** of the SleepBalance Flutter app development. This is a sleep optimization app with MVVM + Provider architecture.

## Project Overview
- **App**: SleepBalance - Sleep tracking and intervention app
- **Architecture**: MVVM + Provider pattern, Clean Architecture (domain/data/presentation layers)
- **Database**: SQLite with migrations, using DatabaseConstants for all table/column names
- **Current State**:
  - Phase 1 ✅: Database infrastructure completed
  - Phase 2 ✅: Action Center data layer completed
  - Phase 3 ✅: Night Review data layer completed (sleep records & baselines)
  - Database currently at VERSION 3

## Your Task: Phase 4 - Settings & User Profile (DATA LAYER ONLY)

### CRITICAL: Scope Limitation
**ONLY implement the DATA LAYER.** UI implementation (ViewModel, Screens) is intentionally excluded and will be done by junior developers separately.

### What to Implement:
1. **Database Migration V4** - Users table
2. **User Domain Model** - With fromDatabase/toDatabase methods
3. **UserRepository Interface** - Abstract repository pattern
4. **UserLocalDataSource** - SQLite operations
5. **UserRepositoryImpl** - Concrete repository implementation
6. **Default User Setup** - In database_helper.dart onCreate
7. **Provider Registration** - Wire up in main.dart
8. **Validation** - Run `flutter analyze` (must be 0 warnings)

### Key Requirements:
- Database version: 2 → 3 → **4**
- All database constants already exist in `database_constants.dart`
- Follow exact same pattern as Phase 2 (Action Center) and Phase 3 (Night Review)
- Use `DatabaseDateUtils` for all DateTime conversions
- Use `DatabaseConstants` for all table/column names (zero hardcoded strings)
- Boolean fields: Store as INTEGER (0/1) in SQLite
- DateTime fields: Use `toDateString()` for dates, `toTimestamp()` for timestamps
- Library directive BEFORE imports in migration files
- Run `dart run build_runner build` after creating models

### Files to Create/Modify:

#### Create:
1. `lib/core/database/migrations/migration_v4.dart`
2. `lib/features/settings/domain/models/user.dart`
3. `lib/features/settings/domain/repositories/user_repository.dart`
4. `lib/features/settings/data/datasources/user_local_datasource.dart`
5. `lib/features/settings/data/repositories/user_repository_impl.dart`

#### Modify:
1. `lib/shared/constants/database_constants.dart` - Update DATABASE_VERSION to 4
2. `lib/core/database/database_helper.dart` - Add migration V4, create default user
3. `lib/main.dart` - Register UserLocalDataSource and UserRepository providers

### User Model Fields:
- `String id` - UUID primary key
- `String email` - Email address
- `String? passwordHash` - Password (nullable)
- `String firstName` - First name
- `String lastName` - Last name
- `DateTime birthDate` - Date of birth (use toDateString)
- `String timezone` - IANA timezone
- `int? targetSleepDuration` - Minutes (nullable)
- `String? targetBedTime` - HH:mm format (nullable)
- `String? targetWakeTime` - HH:mm format (nullable)
- `bool hasSleepDisorder` - Store as INTEGER 0/1
- `String? sleepDisorderType` - nullable
- `bool takesSleepMedication` - Store as INTEGER 0/1
- `String preferredUnitSystem` - 'metric' or 'imperial'
- `String language` - 'en', 'de', etc.
- `DateTime createdAt` - Use toTimestamp
- `DateTime updatedAt` - Use toTimestamp

### Getters:
- `String get fullName` - Returns "$firstName $lastName"
- `int get age` - Calculate from birthDate

### Repository Methods:
- `getUserById(String userId)`
- `getUserByEmail(String email)`
- `saveUser(User user)`
- `updateUser(User user)`
- `deleteUser(String userId)` - Soft delete
- `getAllUsers()` - Active users only
- `getCurrentUserId()` - From SharedPreferences
- `setCurrentUserId(String userId)` - To SharedPreferences

### Default User Setup:
In `database_helper.dart` after MIGRATION_V4:
- Create default user with email: 'default@sleepbalance.app'
- First name: 'Sleep', Last name: 'User'
- Birth date: 1990-01-01
- Target sleep: 480 minutes (8 hours)
- Timezone: 'UTC'
- Use UuidGenerator for ID
- Use DatabaseDateUtils and DatabaseConstants

### Provider Registration Pattern:
```dart
// Settings - User DataSource
Provider<UserLocalDataSource>(
  create: (_) => UserLocalDataSource(database: database),
),

// Settings - User Repository
Provider<UserRepository>(
  create: (context) => UserRepositoryImpl(
    dataSource: context.read<UserLocalDataSource>(),
    prefs: context.read<SharedPreferences>(),
  ),
),
```

### Success Criteria:
✅ Migration V4 created with library directive BEFORE imports
✅ Database version updated to 4
✅ User model with fromDatabase/toDatabase methods
✅ build_runner generates user.g.dart successfully
✅ UserLocalDataSource uses DatabaseConstants for all queries
✅ UserRepositoryImpl integrates with SharedPreferences
✅ Default user created in database_helper onCreate
✅ Providers registered in main.dart in correct order
✅ `flutter analyze` returns 0 warnings
✅ NO UI/ViewModel implementation (data layer only)

### Reference Files:
- Pattern: `lib/features/action_center/domain/models/daily_action.dart`
- Pattern: `lib/features/action_center/data/datasources/action_local_datasource.dart`
- Pattern: `lib/features/night_review/domain/models/sleep_record.dart`
- Constants: `lib/shared/constants/database_constants.dart`
- Utils: `lib/core/utils/database_date_utils.dart`

### Implementation Order:
1. Create migration_v4.dart (library directive FIRST!)
2. Update database_constants.dart (VERSION to 4)
3. Update database_helper.dart (add migration, default user)
4. Create User model
5. Run build_runner
6. Create UserRepository interface
7. Create UserLocalDataSource
8. Create UserRepositoryImpl
9. Register providers in main.dart
10. Run flutter analyze
11. Verify 0 warnings

### Important Notes:
- MUST use `fromDatabase()` not `fromJson()` when reading from SQLite
- MUST use `toDatabase()` not `toJson()` when writing to SQLite
- MUST handle nullable fields with inline null checks
- MUST use DatabaseConstants for ALL column names
- MUST use DatabaseDateUtils for ALL DateTime conversions
- NO hardcoded strings in SQL queries
- NO UI implementation in this phase

## Detailed Instructions
Read `/home/veit/AndroidStudioProjects/sleepbalance/PHASE_4.md` for complete step-by-step instructions.

Start by reading the README.md and PHASE_4.md, then implement each step sequentially as outlined in PHASE_4.md.
