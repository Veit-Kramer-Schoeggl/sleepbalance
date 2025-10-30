# PHASE 4: Settings & User Profile

## Overview
Create user management system, refactor Settings screen with Provider, add user profile editing screen, replace hardcoded user IDs throughout app with actual authenticated user.

## Prerequisites
- **Phase 1-3 completed:** Database, Action Center, Night Review all using MVVM
- Understanding that we're still using hardcoded 'user123' ID
- Settings screen currently just a placeholder

## Goals
- Create User model matching database schema
- Implement UserRepository pattern
- Create SettingsViewModel
- Build UserProfileScreen for editing profile
- Expand SettingsScreen with navigation to profile
- Prepare for future authentication integration

---

## Step 4.1: Create Domain Model - User

**File:** `lib/features/settings/domain/models/user.dart`
**Purpose:** User profile and preferences model
**Dependencies:** `json_annotation`

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
- `factory User.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`
- `User copyWith({...})` - Immutable update
- `String get fullName => '$firstName $lastName'`
- `int get age` - Calculate from birthDate to now

**Annotations:**
- `@JsonSerializable()`

**Why:** Replaces hardcoded 'user123' strings, stores user preferences

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
- `Future<void> deleteUser(String userId)` - Remove user (soft delete)
- `Future<List<User>> getAllUsers()` - Get all users (for future multi-user support)
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
- Query users WHERE id = userId
- Convert Map to User or return null

**`Future<User?> getUserByEmail(String email)`**
- Query users WHERE email = email
- Convert to User or null

**`Future<void> insertUser(User user)`**
- Convert to Map
- INSERT into users table

**`Future<void> updateUser(User user)`**
- Convert to Map
- Set updated_at to now()
- UPDATE where id = user.id

**`Future<void> softDeleteUser(String userId)`**
- UPDATE users SET is_deleted = true WHERE id

**`Future<List<User>> getAllActiveUsers()`**
- Query users WHERE is_deleted = false
- Convert to List<User>

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
- If user exists: call updateUser
- Else: call `_dataSource.insertUser`

**`Future<void> updateUser(User user)`**
- Delegates to `_dataSource.updateUser(user)`

**`Future<void> deleteUser(String userId)`**
- Delegates to `_dataSource.softDeleteUser(userId)`

**`Future<List<User>> getAllUsers()`**
- Delegates to `_dataSource.getAllActiveUsers()`

**`Future<String?> getCurrentUserId()`**
- Returns `_prefs.getString(_currentUserIdKey)`

**`Future<void> setCurrentUserId(String userId)`**
- Calls `_prefs.setString(_currentUserIdKey, userId)`

**Why:** Combines database access with session management via SharedPreferences

---

## Step 4.5: Create ViewModel - SettingsViewModel

**File:** `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart`
**Purpose:** Manage settings state, user preferences, app configuration
**Dependencies:** `provider`, `user_repository`, `user`

**Class: SettingsViewModel extends ChangeNotifier**

**Constructor:**
- `SettingsViewModel({required UserRepository repository})`

**Fields:**
- `final UserRepository _repository`
- `User? _currentUser` - Currently logged-in user (nullable)
- `bool _isLoading = false`
- `String? _errorMessage`

**Getters:**
- `User? get currentUser`
- `bool get isLoading`
- `String? get errorMessage`
- `bool get isLoggedIn => currentUser != null`

**Methods:**

**`Future<void> loadCurrentUser()`**
- Set loading true
- Get userId from `_repository.getCurrentUserId()`
- If userId exists: Fetch user from database
- Set _currentUser
- Handle errors
- Set loading false, notify

**`Future<void> updateUserProfile(User updatedUser)`**
- Call `_repository.updateUser(updatedUser)`
- Set _currentUser = updatedUser
- Notify listeners

**`Future<void> updateLanguage(String language)`**
- Update currentUser with new language
- Save to database
- Notify listeners

**`Future<void> updateUnitSystem(String unitSystem)`**
- Update currentUser with new unit system
- Save to database
- Notify listeners

**`Future<void> logout()`**
- Clear currentUser
- Clear current user ID from SharedPreferences
- Notify listeners

**Why:** Manages user session and preferences

---

## Step 4.6: Create User Profile Screen

**File:** `lib/features/settings/presentation/screens/user_profile_screen.dart`
**Purpose:** Edit user profile (name, birthdate, sleep goals)
**Dependencies:** `provider`, `settings_viewmodel`, widgets

**Class: UserProfileScreen extends StatelessWidget**

**Build Method:**
- `final viewModel = context.watch<SettingsViewModel>()`
- `final user = viewModel.currentUser`
- If user null: Show loading or error

**Form Fields:**
- First Name (TextFormField)
- Last Name (TextFormField)
- Birth Date (DatePicker)
- Timezone (Dropdown)
- Target Sleep Duration (Slider: 6-10 hours)
- Target Bed Time (TimePicker)
- Target Wake Time (TimePicker)
- Has Sleep Disorder (Switch)
- If true: Sleep Disorder Type (Dropdown)
- Takes Sleep Medication (Switch)
- Preferred Unit System (Dropdown: metric/imperial)
- Language (Dropdown: en/de)

**Save Button:**
- Validates form
- Creates updated User with copyWith
- Calls `viewModel.updateUserProfile(updatedUser)`
- Shows success SnackBar
- Navigates back

**Why:** Allows user to set preferences that affect app behavior

---

## Step 4.7: Refactor Settings Screen

**File:** `lib/features/settings/presentation/screens/settings_screen.dart`
**Purpose:** Add Provider integration, navigation to profile, settings options
**Dependencies:** `provider`, `settings_viewmodel`, `user_profile_screen`

**Changes:**

### Convert to Provider Consumer:
- Keep as StatelessWidget (already is)
- Wrap content with `Consumer<SettingsViewModel>`

### New Structure:

**Build Method:**
```
Consumer<SettingsViewModel>(
  builder: (context, viewModel, child) {
    final user = viewModel.currentUser;

    return BackgroundWrapper(
      child: Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: ListView(
          children: [
            // User Profile Tile
            ListTile(
              leading: CircleAvatar(child: Text(user?.firstName[0] ?? '?')),
              title: Text(user?.fullName ?? 'Guest'),
              subtitle: Text(user?.email ?? 'Not logged in'),
              trailing: Icon(Icons.edit),
              onTap: () => Navigator.push(...UserProfileScreen),
            ),

            Divider(),

            // Sleep Goals Section
            ListTile(
              title: Text('Sleep Goal'),
              subtitle: Text('${user?.targetSleepDuration ?? 480} minutes'),
              trailing: Icon(Icons.nightlight),
            ),

            // Preferences Section
            SwitchListTile(
              title: Text('Dark Mode'),
              value: false, // TODO: Implement theme switching
              onChanged: (value) {},
            ),

            ListTile(
              title: Text('Language'),
              subtitle: Text(user?.language.toUpperCase() ?? 'EN'),
              trailing: Icon(Icons.language),
              onTap: () {
                // Show language picker dialog
              },
            ),

            // Modules Section
            ListTile(
              title: Text('Manage Modules'),
              subtitle: Text('Enable/disable intervention modules'),
              trailing: Icon(Icons.extension),
              onTap: () {
                // TODO: Navigate to module management (Phase 6)
              },
            ),

            Divider(),

            // Danger Zone
            ListTile(
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              leading: Icon(Icons.logout, color: Colors.red),
              onTap: () {
                viewModel.logout();
                // Navigate to login or onboarding
              },
            ),
          ],
        ),
      ),
    );
  },
)
```

**Why:** Centralized settings with navigation to detailed screens

---

## Step 4.8: Create Default User Setup

**File:** `lib/core/database/database_helper.dart` (modify onCreate)
**Purpose:** Create default user on first app launch
**Action:** Add to `_onCreate` method after executing migrations

**Additional Code in _onCreate:**
```dart
// After MIGRATION_V1 execution
// Insert default user if none exists
final defaultUser = {
  'id': UuidGenerator.generate(),
  'email': 'default@sleepbalance.app',
  'first_name': 'Sleep',
  'last_name': 'User',
  'birth_date': '1990-01-01',
  'timezone': 'UTC',
  'target_sleep_duration': 480,
  'preferred_unit_system': 'metric',
  'language': 'en',
  'has_sleep_disorder': 0,
  'takes_sleep_medication': 0,
  'created_at': DateTime.now().toIso8601String(),
  'updated_at': DateTime.now().toIso8601String(),
};

await db.insert('users', defaultUser);

// Set as current user in SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('current_user_id', defaultUser['id']);
```

**Why:** Ensures app has a user to work with before auth is implemented

---

## Testing Checklist

### Manual Tests:
- [ ] Launch app, Settings screen should load without errors
- [ ] Tap user profile tile, should navigate to profile screen
- [ ] Edit profile fields, tap save
- [ ] Go back to settings, changes should persist
- [ ] Check database, users table should have updated values
- [ ] Tap logout, current user should clear

### Unit Tests:
- [ ] Test User model fromJson/toJson
- [ ] Test User.age calculation
- [ ] Test UserRepository getCurrentUserId with mock SharedPreferences
- [ ] Test SettingsViewModel loadCurrentUser flow

### Integration Tests:
- [ ] Create user → Save → Fetch → Verify data integrity
- [ ] Update profile → Reload → Verify changes persisted

### Database Validation:
```sql
-- Check default user exists
SELECT id, first_name, last_name, email FROM users;

-- Update user profile
UPDATE users SET first_name = 'John', last_name = 'Doe' WHERE id = 'user-id';

-- Verify update
SELECT * FROM users WHERE id = 'user-id';
```

---

## Rollback Strategy

Same as previous phases:
- Keep original SettingsScreen as backup
- Can disable Provider temporarily
- Or full rollback via git

---

## Next Steps

After Phase 4:
- Proceed to **PHASE_5.md:** Wire up Provider in main.dart
- All pieces exist, need to connect them app-wide

---

## Notes

**Why Settings fourth?**
- Foundation for user-specific data
- Replaces hardcoded 'user123' strings
- Needed before implementing personalized modules

**Authentication:**
- For now, single default user
- Phase 5+ can add proper login/signup
- Current setup prepares for multi-user support

**Profile Fields:**
- Sleep disorder info useful for analysis
- Timezone critical for sleep timing calculations
- Unit system affects display formatting

**Estimated Time:** 4-5 hours
- User model: 45 minutes
- Repository: 60 minutes
- ViewModel: 60 minutes
- Profile screen: 90 minutes
- Settings refactoring: 45 minutes
- Testing: 30 minutes
