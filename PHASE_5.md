# PHASE 5: App Entry & Provider Setup

## Overview
Wire up all components app-wide: configure MultiProvider in main.dart, initialize database on startup, inject dependencies throughout app, refactor SplashScreen for Provider.

## Prerequisites
- **Phase 1-4 completed:** All infrastructure, repositories, ViewModels exist
- Currently: Components work in isolation but not connected
- Need: Global Provider setup to make everything work together

## Goals
- Set up MultiProvider at app root
- Initialize database on app startup
- Register all repositories and services as providers
- Register all ViewModels
- Refactor SplashScreen to use injected dependencies
- Remove hardcoded 'user123' strings, use actual current user
- Ensure proper Provider disposal

---

## Step 5.1: Modify main.dart - Add Provider Initialization

**File:** `lib/main.dart`
**Purpose:** Set up MultiProvider, initialize database, register all dependencies
**Dependencies:** `provider`, all repositories, all ViewModels, `database_helper`, `shared_preferences`

**Changes:**

### Add Imports:
```dart
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/database_helper.dart';
// Import all repositories
// Import all ViewModels
// Import all services
```

### Modify main() function:

**`Future<void> main() async`**
- Add `WidgetsFlutterBinding.ensureInitialized()`
- Initialize database: `await DatabaseHelper.instance.database`
- Initialize SharedPreferences: `final prefs = await SharedPreferences.getInstance()`
- Run app: `runApp(MyApp(prefs: prefs))`

**Why async main:**
- Database must be initialized before app starts
- SharedPreferences needed for dependency injection

---

## Step 5.2: Create Providers Setup Function

**File:** `lib/main.dart` (continued)
**Purpose:** Factory function to create all Provider instances

**Function: `List<SingleChildWidget> _createProviders(SharedPreferences prefs, Database database)`**

**Returns list of providers in order:**

### 1. Services & Utilities (no dependencies):
```dart
Provider<SharedPreferences>.value(value: prefs),
Provider<Database>.value(value: database),
```

### 2. Data Sources (depend on Database):
```dart
Provider<ActionLocalDataSource>(
  create: (_) => ActionLocalDataSource(database: database),
),
Provider<SleepRecordLocalDataSource>(
  create: (_) => SleepRecordLocalDataSource(database: database),
),
Provider<UserLocalDataSource>(
  create: (_) => UserLocalDataSource(database: database),
),
```

### 3. Repositories (depend on DataSources):
```dart
ProxyProvider<ActionLocalDataSource, ActionRepository>(
  update: (_, dataSource, __) => ActionRepositoryImpl(dataSource: dataSource),
),
ProxyProvider2<SleepRecordLocalDataSource, SharedPreferences, SleepRecordRepository>(
  update: (_, dataSource, prefs, __) => SleepRecordRepositoryImpl(dataSource: dataSource),
),
ProxyProvider2<UserLocalDataSource, SharedPreferences, UserRepository>(
  update: (_, dataSource, prefs, __) => UserRepositoryImpl(dataSource: dataSource, prefs: prefs),
),
```

### 4. ViewModels (depend on Repositories):
```dart
ChangeNotifierProxyProvider<ActionRepository, ActionViewModel>(
  create: (_) => ActionViewModel(repository: /* temporary placeholder */),
  update: (_, repository, previous) => ActionViewModel(repository: repository),
),
ChangeNotifierProxyProvider<SleepRecordRepository, NightReviewViewModel>(
  create: (_) => NightReviewViewModel(repository: /* placeholder */),
  update: (_, repository, previous) => NightReviewViewModel(repository: repository),
),
ChangeNotifierProxyProvider<UserRepository, SettingsViewModel>(
  create: (_) => SettingsViewModel(repository: /* placeholder */),
  update: (_, repository, previous) => SettingsViewModel(repository: repository),
),
```

**Why ProxyProvider:**
- Automatically rebuilds ViewModels when dependencies change
- Handles disposal correctly

**Why this order:**
- Services → DataSources → Repositories → ViewModels
- Each layer depends on previous layer

---

## Step 5.3: Modify MyApp class

**File:** `lib/main.dart` (continued)
**Purpose:** Wrap MaterialApp with MultiProvider

**Class: MyApp extends StatelessWidget**

**Constructor:**
```dart
const MyApp({super.key, required this.prefs});

final SharedPreferences prefs;
```

**Build Method:**
```dart
@override
Widget build(BuildContext context) {
  return FutureBuilder<Database>(
    future: DatabaseHelper.instance.database,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (snapshot.hasError) {
        return MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Database initialization failed')),
          ),
        );
      }

      final database = snapshot.data!;

      return MultiProvider(
        providers: _createProviders(prefs, database),
        child: MaterialApp(
          title: 'SleepBalance',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: SplashScreen(), // Will use Provider internally
        ),
      );
    },
  );
}
```

**Why FutureBuilder:**
- Ensures database is ready before providers are created
- Shows loading while initializing

---

## Step 5.4: Refactor SplashScreen

**File:** `lib/shared/screens/app/splash_screen.dart`
**Purpose:** Use Provider to inject PreferencesService, use UserRepository for current user
**Dependencies:** `provider`, `preferences_service`, `user_repository`, `settings_viewmodel`

**Changes:**

### Remove Direct Instantiation:
- Delete `final prefsService = PreferencesService();` (line creating instance)

### Use Provider Instead:

**Build Method:**
```dart
@override
Widget build(BuildContext context) {
  return FutureBuilder<void>(
    future: _checkFirstLaunch(context),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return Container(); // Will navigate away
      }
      return BackgroundWrapper(
        imagePath: 'assets/images/main_background.png',
        overlayOpacity: 0.3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/moon_star.png', width: 150, height: 150),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
    },
  );
}
```

**`Future<void> _checkFirstLaunch(BuildContext context) async`**
```dart
// Get services from Provider
final prefs = context.read<SharedPreferences>();
final userRepository = context.read<UserRepository>();

// Check first launch
final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

// Load current user (will be default user created in Phase 4)
final userId = await userRepository.getCurrentUserId();

if (isFirstLaunch || userId == null) {
  // Navigate to onboarding
  await Future.delayed(Duration(seconds: 2));
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => QuestionnaireScreen()),
  );
} else {
  // Load user into SettingsViewModel
  final settingsVM = context.read<SettingsViewModel>();
  await settingsVM.loadCurrentUser();

  // Navigate to main app
  await Future.delayed(Duration(seconds: 2));
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => MainNavigation()),
  );
}
```

**Why:**
- Removes direct service instantiation
- Uses Provider for dependency injection
- Loads current user on startup

---

## Step 5.5: Update All Screens to Use Current User

**Files to Modify:**
- `action_screen.dart`
- `night_screen.dart`

**Changes in ActionScreen:**
```dart
// Old: hardcoded user ID
..loadActions('hardcoded-user-id')

// New: get from SettingsViewModel
final userId = context.read<SettingsViewModel>().currentUser?.id ?? '';
..loadActions(userId)
```

**Changes in NightScreen:**
```dart
// Old: hardcoded user ID
..loadSleepData('hardcoded-user-id')

// New: get from SettingsViewModel
final userId = context.read<SettingsViewModel>().currentUser?.id ?? '';
..loadSleepData(userId)
```

**Why:** Uses actual user ID instead of placeholder

---

## Step 5.6: Optional - Update MainNavigation with Provider

**File:** `lib/shared/widgets/navigation/main_navigation.dart`
**Purpose:** Optionally manage tab state with Provider (not critical)
**Action:** Can keep existing setState() implementation or migrate later

**Note:** MainNavigation state is simple enough that setState() is fine. Provider here is optional.

---

## Testing Checklist

### Manual Tests:
- [ ] Launch app, should show splash screen briefly
- [ ] If first launch: Navigate to questionnaire
- [ ] Complete questionnaire, mark first launch as done
- [ ] Restart app, should skip questionnaire and load main screen
- [ ] Navigate to Action Center, should load actions for current user
- [ ] Navigate to Night Review, should load sleep data for current user
- [ ] Navigate to Settings, should show current user's name
- [ ] Edit profile, changes should persist across app restarts

### Provider Tests:
- [ ] Verify all providers are registered in correct order
- [ ] Verify no "Provider not found" errors in console
- [ ] Verify ViewModels dispose correctly on screen exit (no memory leaks)

### Error Handling Tests:
- [ ] What if database initialization fails? (Should show error screen)
- [ ] What if no current user? (Should handle gracefully, maybe force onboarding)

### Performance Tests:
- [ ] App startup time (should be < 3 seconds on device)
- [ ] Database queries are not blocking UI thread

---

## Rollback Strategy

**If Phase 5 fails:**

### Option A: Minimal Provider
1. Only register repositories, not ViewModels
2. Create ViewModels locally in each screen
3. Gradually migrate to global Provider

### Option B: Full rollback
1. Revert main.dart to original
2. Keep Providers in individual screens (ChangeNotifierProvider in each screen's build)
3. This still works but less efficient

---

## Common Issues & Solutions

### Issue: "Provider not found in ancestor"
**Solution:** Ensure Provider is registered before it's used. Check provider order in _createProviders.

### Issue: "setState called after dispose"
**Solution:** Ensure ViewModels properly dispose of listeners, use mounted checks in async methods.

### Issue: "Database is locked"
**Solution:** Don't call database operations from initState, use FutureBuilder or post-frame callbacks.

### Issue: App hangs on splash screen
**Solution:** Check for exceptions in _checkFirstLaunch, add try-catch blocks.

---

## Next Steps

After Phase 5:
- App is now fully wired up with MVVM + Provider
- Proceed to **PHASE_6.md:** Implement first intervention module (Light)
- Light module demonstrates full module pattern for future modules

---

## Notes

**Why Provider order matters:**
- Providers are created top-to-bottom
- Dependencies must exist before dependents
- ProxyProvider automatically handles updates

**Disposal:**
- ChangeNotifier ViewModels auto-dispose when removed from tree
- No manual cleanup needed for most cases

**Performance:**
- MultiProvider has minimal overhead
- Lazy initialization only creates providers when first accessed
- Proper use of context.read vs context.watch prevents unnecessary rebuilds

**Alternative: Riverpod**
- Could use Riverpod instead of Provider
- Similar concepts, different syntax
- Provider is simpler for this use case

**Estimated Time:** 3-4 hours
- main.dart setup: 60 minutes
- Provider configuration: 60 minutes
- SplashScreen refactoring: 45 minutes
- Screen updates: 30 minutes
- Testing & debugging: 60 minutes
