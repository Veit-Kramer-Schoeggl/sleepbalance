# PHASE 5: App Entry & Provider Setup

## Overview
Wire up remaining components app-wide: register ViewModels in main.dart, refactor SplashScreen to use Provider, replace hardcoded user IDs with actual current user.

**IMPORTANT UPDATE:** Phase 4 already completed the data layer setup! This includes:
- ✅ SharedPreferences initialization in main.dart
- ✅ Database initialization with migration V4
- ✅ Default user creation in database_helper.dart
- ✅ Provider registration for UserLocalDataSource and UserRepository
- ✅ Current user ID set in SharedPreferences on first launch

**What's left for Phase 5:** ViewModels, UI refactoring, and wiring up existing screens.

## Prerequisites
- **Phase 1-4 completed:** All infrastructure, repositories exist
- **Phase 4 specifically:**
  - UserLocalDataSource created
  - UserRepository implemented with SharedPreferences
  - Default user created automatically on first launch
  - Providers already registered in main.dart
- Currently: Data layer works, but UI screens don't use it yet
- Need: ViewModel layer and screen refactoring

## Goals
- Create SettingsViewModel for user management
- Create/update ViewModels for Action Center and Night Review (if needed)
- Refactor SplashScreen to load current user via Provider
- Replace hardcoded 'user123' strings with actual current user ID
- Ensure proper ViewModel disposal

---

## Step 5.1: Review Current Provider Setup (Already Done!)

**File:** `lib/main.dart`
**Status:** ✅ Already completed in Phase 4

**What's already in place:**

### Current main() function:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Database initialized
  final database = await DatabaseHelper.instance.database;

  // ✅ SharedPreferences initialized
  final prefs = await SharedPreferences.getInstance();

  // ✅ Default user ID set automatically
  if (prefs.getString('current_user_id') == null) {
    final users = await database.query(TABLE_USERS, limit: 1);
    if (users.isNotEmpty) {
      await prefs.setString('current_user_id', users.first[USERS_ID] as String);
    }
  }

  runApp(/* ... */);
}
```

### Current Provider registrations:
```dart
MultiProvider(
  providers: [
    // ✅ Action Center providers
    Provider<ActionLocalDataSource>(...),
    Provider<ActionRepository>(...),

    // ✅ Night Review providers
    Provider<SleepRecordLocalDataSource>(...),
    Provider<SleepRecordRepository>(...),

    // ✅ Settings providers (from Phase 4)
    Provider<SharedPreferences>(...),
    Provider<UserLocalDataSource>(...),
    Provider<UserRepository>(...),
  ],
)
```

**What this means:**
- All data layer providers are ready
- We only need to add ViewModel providers
- No need to modify database or SharedPreferences initialization

---

## Step 5.2: Create SettingsViewModel

**File:** `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart`
**Purpose:** Manage user state and settings operations
**Dependencies:** `UserRepository`, `ChangeNotifier`

**Class: SettingsViewModel extends ChangeNotifier**

**Fields:**
- `final UserRepository _repository` - Repository for user operations
- `User? _currentUser` - Currently logged-in user (nullable)
- `bool _isLoading = false` - Loading state
- `String? _errorMessage` - Error message if operation fails

**Constructor:**
```dart
SettingsViewModel({required UserRepository repository})
    : _repository = repository;
```

**Methods:**

### `Future<void> loadCurrentUser()`
Loads the current user from the repository.

**Steps:**
1. Set `_isLoading = true`, call `notifyListeners()`
2. Get current user ID from repository: `await _repository.getCurrentUserId()`
3. If user ID exists, load user: `await _repository.getUserById(userId)`
4. Set `_currentUser` with result
5. Handle errors in try-catch, set `_errorMessage` if failed
6. Set `_isLoading = false` in finally block, call `notifyListeners()`

**Example:**
```dart
Future<void> loadCurrentUser() async {
  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final userId = await _repository.getCurrentUserId();
    if (userId != null) {
      _currentUser = await _repository.getUserById(userId);
    }
  } catch (e) {
    _errorMessage = 'Failed to load user: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### `Future<void> updateUserProfile(User updatedUser)`
Updates user profile in database.

**Steps:**
1. Set `_isLoading = true`, call `notifyListeners()`
2. Call `await _repository.updateUser(updatedUser)`
3. Update `_currentUser = updatedUser`
4. Handle errors in try-catch
5. Set `_isLoading = false` in finally block, call `notifyListeners()`

### `Future<void> updateLanguage(String language)`
Quick method to update only language.

**Steps:**
1. If `_currentUser == null`, return
2. Create updated user: `_currentUser!.copyWith(language: language)`
3. Call `updateUserProfile(updatedUser)`

### `Future<void> updateUnitSystem(String unitSystem)`
Quick method to update only unit system.

**Similar to updateLanguage**

### `Future<void> logout()`
Logs out current user.

**Steps:**
1. Call `await _repository.setCurrentUserId('')` (clear current user ID)
2. Set `_currentUser = null`
3. Call `notifyListeners()`

**Getters:**
- `User? get currentUser => _currentUser`
- `bool get isLoading => _isLoading`
- `String? get errorMessage => _errorMessage`
- `bool get isLoggedIn => _currentUser != null`

**Pattern Reference:** Same structure as ActionViewModel and NightReviewViewModel!

---

## Step 5.3: Register SettingsViewModel in main.dart

**File:** `lib/main.dart`
**Action:** Add SettingsViewModel to providers list

**Import:**
```dart
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';
```

**Add to providers (AFTER UserRepository):**
```dart
// ============================================================================
// ViewModels
// ============================================================================

// Settings ViewModel
ChangeNotifierProvider<SettingsViewModel>(
  create: (context) => SettingsViewModel(
    repository: context.read<UserRepository>(),
  ),
),
```

**Why ChangeNotifierProvider:**
- ViewModels extend ChangeNotifier
- ChangeNotifierProvider automatically handles disposal
- UI rebuilds when `notifyListeners()` is called

**Why AFTER UserRepository:**
- SettingsViewModel depends on UserRepository
- Providers must be registered in dependency order

---

## Step 5.4: Refactor SplashScreen to Load Current User

**File:** `lib/shared/screens/app/splash_screen.dart`
**Purpose:** Load current user on app startup before navigating to main screen
**Dependencies:** `SettingsViewModel`, `Provider`

**Current issue:** SplashScreen doesn't load user data before navigation

**Changes:**

### Update _checkFirstLaunch method:

**Replace any direct SharedPreferences access with:**
```dart
Future<void> _checkFirstLaunch(BuildContext context) async {
  // Get SettingsViewModel from Provider
  final settingsViewModel = context.read<SettingsViewModel>();
  final prefs = context.read<SharedPreferences>();

  // Load current user first!
  await settingsViewModel.loadCurrentUser();

  // Check if first launch
  final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

  // Add delay for splash screen visibility
  await Future.delayed(Duration(seconds: 2));

  if (!context.mounted) return;

  if (isFirstLaunch) {
    // Navigate to onboarding
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => QuestionnaireScreen()),
    );
  } else {
    // Navigate to main app (user already loaded)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainNavigation()),
    );
  }
}
```

**Why load user in SplashScreen:**
- User data available immediately when app opens
- No delay in Action Center or Night Review screens
- Centralized user loading logic

**Critical:** Always check `context.mounted` before navigation in async methods!

---

## Step 5.5: Update Action Center to Use Current User

**File:** `lib/features/action_center/presentation/screens/action_screen.dart`
**Purpose:** Replace hardcoded user ID with actual current user ID

**Current issue (example):**
```dart
// Old - hardcoded
viewModel.loadActions('user123');
```

**New implementation:**

### Add SettingsViewModel access:

**In build method or initState:**
```dart
@override
void initState() {
  super.initState();

  // Load actions for current user
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final settingsViewModel = context.read<SettingsViewModel>();
    final actionViewModel = context.read<ActionViewModel>();

    final userId = settingsViewModel.currentUser?.id;
    if (userId != null) {
      actionViewModel.loadActions(userId, DateTime.now());
    } else {
      // Handle no user case - should not happen if SplashScreen loaded user
      debugPrint('Warning: No current user found in Action Center');
    }
  });
}
```

**Alternative using Consumer:**
```dart
Consumer<SettingsViewModel>(
  builder: (context, settingsVM, _) {
    final userId = settingsVM.currentUser?.id;

    if (userId == null) {
      return Center(child: Text('No user logged in'));
    }

    return Consumer<ActionViewModel>(
      builder: (context, actionVM, _) {
        // Use userId here
        // ...
      },
    );
  },
)
```

**Choose based on your current screen structure.**

---

## Step 5.6: Update Night Review to Use Current User

**File:** `lib/features/night_review/presentation/screens/night_screen.dart`
**Purpose:** Replace hardcoded user ID with actual current user ID

**Same pattern as Action Center:**

```dart
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final settingsViewModel = context.read<SettingsViewModel>();
    final nightViewModel = context.read<NightReviewViewModel>();

    final userId = settingsViewModel.currentUser?.id;
    if (userId != null) {
      nightViewModel.loadSleepRecord(userId, DateTime.now());
    }
  });
}
```

**Important:** If NightReviewViewModel doesn't exist yet, this step may need to wait until it's created.

---

## Step 5.7: Optional - Create ActionViewModel (If Not Exists)

**Status:** Check if ActionViewModel already exists.

**If it doesn't exist:**

**File:** `lib/features/action_center/presentation/viewmodels/action_viewmodel.dart`

**Follow same pattern as SettingsViewModel:**
- Extend ChangeNotifier
- Accept ActionRepository in constructor
- Methods: `loadActions()`, `toggleAction()`, etc.
- Use try-catch-finally pattern
- Call `notifyListeners()` after state changes

**Register in main.dart:**
```dart
ChangeNotifierProvider<ActionViewModel>(
  create: (context) => ActionViewModel(
    repository: context.read<ActionRepository>(),
  ),
),
```

---

## Step 5.8: Optional - Create NightReviewViewModel (If Not Exists)

**Similar to ActionViewModel, but for Night Review feature.**

---

## Testing Checklist

### Manual Tests:

#### App Startup:
- [ ] Launch app, should show splash screen for ~2 seconds
- [ ] If first launch: Navigate to questionnaire
- [ ] Complete questionnaire, set `is_first_launch = false`
- [ ] Restart app, should skip questionnaire and load main screen
- [ ] No errors in console about "Provider not found"

#### User Loading:
- [ ] SplashScreen loads user before navigation
- [ ] SettingsViewModel.currentUser is not null after startup
- [ ] Current user ID matches the default user created in Phase 4

#### Action Center:
- [ ] Navigate to Action Center
- [ ] Should load actions for current user (not hardcoded ID)
- [ ] Creating/completing actions uses current user ID
- [ ] No "user123" or hardcoded IDs in logs

#### Night Review:
- [ ] Navigate to Night Review
- [ ] Should load sleep data for current user
- [ ] No hardcoded user IDs used

#### Settings Screen:
- [ ] Navigate to Settings
- [ ] Should display current user's name and email
- [ ] "Sleep User" and "default@sleepbalance.app" should be visible
- [ ] No crashes or null pointer exceptions

### Provider Tests:

- [ ] All ViewModels registered in correct order (after their repositories)
- [ ] ChangeNotifierProvider used for ViewModels
- [ ] Provider<T> used for repositories and services
- [ ] No duplicate provider registrations
- [ ] ViewModels dispose correctly (check with Flutter DevTools)

### Error Handling Tests:

- [ ] What if user is null? (Should be handled gracefully)
- [ ] What if repository call fails? (Should show error message)
- [ ] What if database is empty? (Default user should exist from Phase 4)

### Performance Tests:

- [ ] App startup time < 3 seconds
- [ ] No lag when switching between tabs
- [ ] ViewModel operations don't block UI thread

---

## Rollback Strategy

**If Phase 5 fails:**

### Option A: Minimal ViewModel
1. Only create SettingsViewModel
2. Keep Action Center and Night Review with hardcoded IDs temporarily
3. Gradually add ViewModels one at a time

### Option B: Local ViewModels
1. Create ViewModels inside each screen (not global)
2. Use `ChangeNotifierProvider` in each screen's build method
3. Less efficient but safer for testing

### Option C: Full rollback
1. Revert ViewModel files
2. Keep Phase 4 data layer intact
3. Screens use repositories directly (context.read<UserRepository>())

---

## Common Issues & Solutions

### Issue: "Provider<SettingsViewModel> not found"
**Solution:**
- Check SettingsViewModel is registered in main.dart providers list
- Ensure it's registered AFTER UserRepository
- Verify import statement is correct

### Issue: "currentUser is null"
**Solution:**
- Check SplashScreen calls `loadCurrentUser()`
- Verify default user was created in database (check with SQLite viewer)
- Verify SharedPreferences has `current_user_id` key

### Issue: "setState called after dispose"
**Solution:**
- Add `if (!mounted)` checks before setState in async methods
- Ensure ViewModels don't call notifyListeners() after disposal
- Use `context.mounted` in Flutter 3.10+

### Issue: App hangs on splash screen
**Solution:**
- Add try-catch in _checkFirstLaunch
- Check for infinite loops in navigation logic
- Verify database initialization completes successfully

### Issue: Hardcoded user IDs still appear
**Solution:**
- Search project for 'user123' or other hardcoded IDs
- Replace with `context.read<SettingsViewModel>().currentUser?.id`
- Add null checks for when user might not be loaded

---

## Next Steps

After Phase 5:
- App is fully wired with MVVM + Provider architecture
- All screens use actual user data (no hardcoded IDs)
- Ready for Settings UI implementation
- Proceed to **SETTINGS_IMPLEMENTATION_PLAN.md:** Build Settings and User Profile screens
- Then **PHASE_6:** Implement first intervention module (Light)

---

## Notes

**What Phase 4 Already Gave Us:**
- Database with users table (migration V4)
- User model with fromDatabase/toDatabase methods
- UserLocalDataSource for SQLite operations
- UserRepositoryImpl with SharedPreferences integration
- Default user automatically created on first launch
- Current user ID automatically set in SharedPreferences
- All providers registered in main.dart

**What Phase 5 Adds:**
- SettingsViewModel for UI state management
- SplashScreen user loading logic
- Replacement of hardcoded user IDs throughout app
- ViewModel layer for MVVM pattern completion

**Key Learnings Applied:**
1. **Provider dependency order matters:** Services → DataSources → Repositories → ViewModels
2. **ChangeNotifierProvider for ViewModels:** Automatic disposal and rebuild on notifyListeners()
3. **context.read vs context.watch:** read for one-time access, watch for reactive updates
4. **Null safety critical:** Always check if currentUser is null
5. **async operations need mounted checks:** Prevent setState after disposal
6. **Load user in SplashScreen:** Centralized user loading before app navigation

**Architecture Benefits:**
- Clean separation of concerns (Model-View-ViewModel)
- Easy to test (mock repositories, test ViewModels in isolation)
- Scalable (add new features following same pattern)
- Maintainable (changes in one layer don't affect others)

**Performance Considerations:**
- ChangeNotifierProvider rebuilds only widgets using Consumer or watch
- context.read doesn't rebuild, only fetches value
- Lazy initialization - providers created only when first accessed
- ViewModels automatically disposed when removed from widget tree

**Alternative Approaches:**
- **Riverpod:** Modern provider alternative, compile-time safety
- **BLoC:** Event-driven architecture, more complex but powerful
- **GetX:** All-in-one solution, but less community support

For this project, Provider + MVVM is the sweet spot:
- Simple enough for junior developers
- Powerful enough for complex apps
- Well-documented and widely used
- Official Flutter recommendation

**Estimated Time:** 2-3 hours
- SettingsViewModel creation: 45 minutes
- Provider registration: 15 minutes
- SplashScreen refactoring: 30 minutes
- Screen updates (Action Center, Night Review): 45 minutes
- Testing & debugging: 45 minutes
