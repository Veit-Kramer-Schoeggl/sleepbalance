# PHASE 2: Action Center Refactoring (Pilot Feature)

## Overview
Refactor Action Center as the pilot feature to demonstrate full MVVM + Provider + Database architecture. This validates the pattern before rolling out to other screens.

## Prerequisites
- **Phase 1 completed:** Database infrastructure, UUID generator, constants
- Database initialized with all tables (verified via tests)
- Provider package added to dependencies (verified in pubspec.yaml)
- All 118 analyzer warnings resolved

## Goals
- Create first domain model with JSON serialization
- Implement repository pattern (interface + implementation)
- Create first ViewModel with ChangeNotifier
- Refactor ActionScreen from StatefulWidget to StatelessWidget + Provider
- Migrate from hardcoded data to database persistence
- Add new `daily_actions` table via migration

---

## Step 2.1: Create Migration V2 for Daily Actions Table

**File:** `lib/core/database/migrations/migration_v2.dart`
**Purpose:** Add daily_actions table to existing database
**Dependencies:** `database_constants.dart`

**Why First:** Based on Phase 1 learning, create migration before models to ensure schema exists

**Add to database_constants.dart:**
```dart
// Daily Actions Table
const String TABLE_DAILY_ACTIONS = 'daily_actions';
const String DAILY_ACTIONS_ID = 'id';
const String DAILY_ACTIONS_USER_ID = 'user_id';
const String DAILY_ACTIONS_TITLE = 'title';
const String DAILY_ACTIONS_ICON_NAME = 'icon_name';
const String DAILY_ACTIONS_IS_COMPLETED = 'is_completed';
const String DAILY_ACTIONS_CREATED_AT = 'created_at';
const String DAILY_ACTIONS_COMPLETED_AT = 'completed_at';
const String DAILY_ACTIONS_ACTION_DATE = 'action_date';
```

**Create migration_v2.dart:**
```dart
// ignore_for_file: constant_identifier_names

import '../../../shared/constants/database_constants.dart';

const String MIGRATION_V2 = '''
-- Add daily_actions table
CREATE TABLE $TABLE_DAILY_ACTIONS (
  $DAILY_ACTIONS_ID TEXT PRIMARY KEY,
  $DAILY_ACTIONS_USER_ID TEXT NOT NULL,
  $DAILY_ACTIONS_TITLE TEXT NOT NULL,
  $DAILY_ACTIONS_ICON_NAME TEXT NOT NULL,
  $DAILY_ACTIONS_IS_COMPLETED INTEGER NOT NULL DEFAULT 0,
  $DAILY_ACTIONS_ACTION_DATE TEXT NOT NULL,
  $DAILY_ACTIONS_CREATED_AT TEXT NOT NULL,
  $DAILY_ACTIONS_COMPLETED_AT TEXT,
  FOREIGN KEY ($DAILY_ACTIONS_USER_ID) REFERENCES $TABLE_USERS($USERS_ID) ON DELETE CASCADE
);

CREATE INDEX idx_daily_actions_user_date ON $TABLE_DAILY_ACTIONS($DAILY_ACTIONS_USER_ID, $DAILY_ACTIONS_ACTION_DATE);
''';
```

**Update database_helper.dart:**
- Change `DATABASE_VERSION` from 1 to 2 in database_constants.dart
- Update `_onUpgrade` method:
```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute(MIGRATION_V2);
  }
}
```

**Why:** Following Phase 1 pattern: migration → constants → helper update

---

## Step 2.2: Create Domain Model - DailyAction

**File:** `lib/features/action_center/domain/models/daily_action.dart`
**Purpose:** Data model for action items displayed in Action Center
**Dependencies:** `json_annotation`

**Part directive required:**
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'daily_action.g.dart';
```

**Class: DailyAction**

```dart
@JsonSerializable()
class DailyAction {
  final String id;
  final String userId;
  final String title;
  final String iconName;
  final bool isCompleted;
  final DateTime actionDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DailyAction({
    required this.id,
    required this.userId,
    required this.title,
    required this.iconName,
    required this.isCompleted,
    required this.actionDate,
    required this.createdAt,
    this.completedAt,
  });

  // JSON serialization (auto-generated)
  factory DailyAction.fromJson(Map<String, dynamic> json) =>
      _$DailyActionFromJson(json);
  Map<String, dynamic> toJson() => _$DailyActionToJson(this);

  // Database conversion (manual - handles DateTime as ISO strings)
  factory DailyAction.fromDatabase(Map<String, dynamic> map) {
    return DailyAction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      iconName: map['icon_name'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      actionDate: DateTime.parse(map['action_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'icon_name': iconName,
      'is_completed': isCompleted ? 1 : 0,
      'action_date': actionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // Immutable update helper
  DailyAction copyWith({
    String? id,
    String? userId,
    String? title,
    String? iconName,
    bool? isCompleted,
    DateTime? actionDate,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DailyAction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      iconName: iconName ?? this.iconName,
      isCompleted: isCompleted ?? this.isCompleted,
      actionDate: actionDate ?? this.actionDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper to convert iconName to IconData
  IconData get icon {
    switch (iconName) {
      case 'local_drink': return Icons.local_drink;
      case 'air': return Icons.air;
      case 'accessibility_new': return Icons.accessibility_new;
      default: return Icons.check_circle;
    }
  }
}
```

**Generate code:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Why separate fromDatabase/toDatabase:** SQLite stores dates as TEXT (ISO 8601) and booleans as INTEGER, requiring manual conversion

---

## Step 2.3: Create Repository Interface

**File:** `lib/features/action_center/domain/repositories/action_repository.dart`
**Purpose:** Abstract interface defining action data operations
**Dependencies:** `daily_action.dart`

```dart
import '../models/daily_action.dart';

abstract class ActionRepository {
  Future<List<DailyAction>> getActionsForDate(String userId, DateTime date);
  Future<void> saveAction(DailyAction action);
  Future<void> toggleActionCompletion(String actionId);
  Future<int> getCompletionCount(String userId, DateTime date);
}
```

**Note:** Simplified from Phase 2 draft - removed methods that aren't needed yet (YAGNI principle learned from Phase 1)

---

## Step 2.4: Create Local Data Source

**File:** `lib/features/action_center/data/datasources/action_local_datasource.dart`
**Purpose:** SQLite operations for action items
**Dependencies:** `sqflite`, `database_helper`, `database_constants`, `daily_action`

**Class: ActionLocalDataSource**

```dart
import 'package:sqflite/sqflite.dart';
import '../../../../shared/constants/database_constants.dart';
import '../../domain/models/daily_action.dart';

class ActionLocalDataSource {
  final Database database;

  ActionLocalDataSource({required this.database});

  Future<List<DailyAction>> getActionsByDate(String userId, DateTime date) async {
    final dateStr = _formatDate(date);

    final results = await database.query(
      TABLE_DAILY_ACTIONS,
      where: '$DAILY_ACTIONS_USER_ID = ? AND $DAILY_ACTIONS_ACTION_DATE = ?',
      whereArgs: [userId, dateStr],
      orderBy: '$DAILY_ACTIONS_CREATED_AT ASC',
    );

    return results.map((map) => DailyAction.fromDatabase(map)).toList();
  }

  Future<void> insertOrUpdateAction(DailyAction action) async {
    await database.insert(
      TABLE_DAILY_ACTIONS,
      action.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> toggleCompletion(String actionId) async {
    // Fetch current state
    final result = await database.query(
      TABLE_DAILY_ACTIONS,
      where: '$DAILY_ACTIONS_ID = ?',
      whereArgs: [actionId],
      limit: 1,
    );

    if (result.isEmpty) return;

    final action = DailyAction.fromDatabase(result.first);
    final newCompleted = !action.isCompleted;

    await database.update(
      TABLE_DAILY_ACTIONS,
      {
        DAILY_ACTIONS_IS_COMPLETED: newCompleted ? 1 : 0,
        DAILY_ACTIONS_COMPLETED_AT: newCompleted
            ? DateTime.now().toIso8601String()
            : null,
      },
      where: '$DAILY_ACTIONS_ID = ?',
      whereArgs: [actionId],
    );
  }

  Future<int> countCompletedActions(String userId, DateTime date) async {
    final dateStr = _formatDate(date);

    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $TABLE_DAILY_ACTIONS '
      'WHERE $DAILY_ACTIONS_USER_ID = ? '
      'AND $DAILY_ACTIONS_ACTION_DATE = ? '
      'AND $DAILY_ACTIONS_IS_COMPLETED = 1',
      [userId, dateStr],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0]; // YYYY-MM-DD
  }
}
```

**Key learning from Phase 1:** Use database constants instead of hardcoded strings, handle null safety explicitly

---

## Step 2.5: Implement Repository

**File:** `lib/features/action_center/data/repositories/action_repository_impl.dart`
**Purpose:** Concrete implementation of ActionRepository
**Dependencies:** `action_repository`, `action_local_datasource`

```dart
import '../../domain/models/daily_action.dart';
import '../../domain/repositories/action_repository.dart';
import '../datasources/action_local_datasource.dart';

class ActionRepositoryImpl implements ActionRepository {
  final ActionLocalDataSource _dataSource;

  ActionRepositoryImpl({required ActionLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<DailyAction>> getActionsForDate(String userId, DateTime date) {
    return _dataSource.getActionsByDate(userId, date);
  }

  @override
  Future<void> saveAction(DailyAction action) {
    return _dataSource.insertOrUpdateAction(action);
  }

  @override
  Future<void> toggleActionCompletion(String actionId) {
    return _dataSource.toggleCompletion(actionId);
  }

  @override
  Future<int> getCompletionCount(String userId, DateTime date) {
    return _dataSource.countCompletedActions(userId, date);
  }
}
```

**Simple delegation pattern** - keeps repository thin, business logic in ViewModel

---

## Step 2.6: Create ViewModel

**File:** `lib/features/action_center/presentation/viewmodels/action_viewmodel.dart`
**Purpose:** Manage Action Center state, handle business logic
**Dependencies:** `provider`, `action_repository`, `daily_action`, `uuid_generator`

```dart
import 'package:flutter/foundation.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/models/daily_action.dart';
import '../../domain/repositories/action_repository.dart';

class ActionViewModel extends ChangeNotifier {
  final ActionRepository _repository;
  final String userId;

  ActionViewModel({
    required ActionRepository repository,
    required this.userId,
  }) : _repository = repository;

  List<DailyAction> _actions = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _currentDate = DateTime.now();

  // Getters
  List<DailyAction> get actions => _actions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get currentDate => _currentDate;
  int get completedCount => _actions.where((a) => a.isCompleted).length;

  Future<void> loadActions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _actions = await _repository.getActionsForDate(userId, _currentDate);
    } catch (e) {
      _errorMessage = 'Failed to load actions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAction(String actionId) async {
    try {
      await _repository.toggleActionCompletion(actionId);
      await loadActions(); // Reload to get updated state
    } catch (e) {
      _errorMessage = 'Failed to toggle action: $e';
      notifyListeners();
    }
  }

  Future<void> changeDate(DateTime newDate) async {
    _currentDate = newDate;
    await loadActions();
  }

  Future<void> addDefaultActions() async {
    // Helper method to populate with default actions
    final defaultActions = [
      DailyAction(
        id: UuidGenerator.generate(),
        userId: userId,
        title: 'Drink a glass of water',
        iconName: 'local_drink',
        isCompleted: false,
        actionDate: _currentDate,
        createdAt: DateTime.now(),
      ),
      DailyAction(
        id: UuidGenerator.generate(),
        userId: userId,
        title: 'Take 5 deep breaths',
        iconName: 'air',
        isCompleted: false,
        actionDate: _currentDate,
        createdAt: DateTime.now(),
      ),
      DailyAction(
        id: UuidGenerator.generate(),
        userId: userId,
        title: 'Stretch for 2 minutes',
        iconName: 'accessibility_new',
        isCompleted: false,
        actionDate: _currentDate,
        createdAt: DateTime.now(),
      ),
    ];

    for (final action in defaultActions) {
      await _repository.saveAction(action);
    }

    await loadActions();
  }
}
```

**Key Pattern:** Always `notifyListeners()` after state changes. Use try-catch-finally for async operations.

---

## Step 2.7: Refactor ActionScreen

**File:** `lib/features/action_center/presentation/screens/action_screen.dart`
**Purpose:** Convert to StatelessWidget consuming ViewModel
**Dependencies:** `provider`, `action_viewmodel`, existing widgets

**Replace entire file:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/date_navigation_header.dart';
import '../../../../shared/widgets/ui/checkbox_button.dart';
import '../../../../shared/widgets/ui/acceptance_button.dart';
import '../viewmodels/action_viewmodel.dart';

class ActionScreen extends StatelessWidget {
  const ActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActionViewModel(
        repository: context.read(), // Reads ActionRepository from parent MultiProvider
        userId: 'temp-user-id', // TODO: Replace with actual user ID from auth
      )..loadActions(),
      child: const _ActionScreenContent(),
    );
  }
}

class _ActionScreenContent extends StatelessWidget {
  const _ActionScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ActionViewModel>();

    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Action Center', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            DateNavigationHeader(
              currentDate: viewModel.currentDate,
              onPreviousDay: () {
                viewModel.changeDate(
                  viewModel.currentDate.subtract(const Duration(days: 1)),
                );
              },
              onNextDay: () {
                viewModel.changeDate(
                  viewModel.currentDate.add(const Duration(days: 1)),
                );
              },
            ),

            // Error message
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Loading or content
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.actions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No actions for today',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: viewModel.addDefaultActions,
                                child: const Text('Add Default Actions'),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            itemCount: viewModel.actions.length,
                            itemBuilder: (context, index) {
                              final action = viewModel.actions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CheckboxButton(
                                  text: action.title,
                                  icon: action.icon,
                                  isChecked: action.isCompleted,
                                  onChanged: (_) => viewModel.toggleAction(action.id),
                                ),
                              );
                            },
                          ),
                        ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: AcceptanceButton(
                text: 'Complete Actions',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${viewModel.completedCount} of ${viewModel.actions.length} actions completed!',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Key Changes:**
- StatefulWidget → StatelessWidget
- Local state → ViewModel state
- setState → notifyListeners (automatic via Provider)
- Hardcoded data → Database queries
- Added empty state with "Add Default Actions" button

---

## Step 2.8: Register Providers in Main

**File:** `lib/main.dart`
**Purpose:** Provide dependencies to widget tree
**Dependencies:** `provider`, `database_helper`, repositories, datasources

**Update main.dart:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'features/action_center/data/datasources/action_local_datasource.dart';
import 'features/action_center/data/repositories/action_repository_impl.dart';
import 'features/action_center/domain/repositories/action_repository.dart';
// ... other imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        // Data sources
        Provider<ActionLocalDataSource>(
          create: (_) => ActionLocalDataSource(database: database),
        ),

        // Repositories
        Provider<ActionRepository>(
          create: (context) => ActionRepositoryImpl(
            dataSource: context.read<ActionLocalDataSource>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

**Critical:** Providers must be registered in dependency order (datasources before repositories)

---

## Testing Checklist

### Pre-Test Setup:
- [ ] Run `flutter pub run build_runner build`
- [ ] Verify `DATABASE_VERSION = 2` in constants
- [ ] Run app once to trigger migration
- [ ] Check database file has `daily_actions` table

### Manual Tests:
- [ ] Launch app, navigate to Action Center
- [ ] Should show "No actions for today" message
- [ ] Tap "Add Default Actions" button
- [ ] Should display 3 actions from database
- [ ] Tap checkbox - should toggle completion state
- [ ] Restart app - actions should persist
- [ ] Change date - should show empty list
- [ ] Return to today - should show saved actions
- [ ] Tap "Complete Actions" - SnackBar shows correct count

### Database Validation:
```sql
-- Check table created
SELECT name FROM sqlite_master WHERE type='table' AND name='daily_actions';

-- Verify data
SELECT * FROM daily_actions ORDER BY created_at;

-- Check toggle updates
SELECT id, title, is_completed, completed_at FROM daily_actions;
```

### Unit Tests:
Create `test/features/action_center/domain/models/daily_action_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/action_center/domain/models/daily_action.dart';

void main() {
  group('DailyAction', () {
    test('fromDatabase and toDatabase are inverse operations', () {
      final original = DailyAction(
        id: 'test-id',
        userId: 'user-123',
        title: 'Test Action',
        iconName: 'check',
        isCompleted: false,
        actionDate: DateTime(2025, 10, 30),
        createdAt: DateTime.now(),
      );

      final map = original.toDatabase();
      final restored = DailyAction.fromDatabase(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.isCompleted, original.isCompleted);
    });
  });
}
```

---

## Rollback Strategy

**If Phase 2 fails:**

1. **Revert database version:**
   ```dart
   const int DATABASE_VERSION = 1; // in database_constants.dart
   ```

2. **Restore original ActionScreen:**
   ```bash
   git checkout HEAD -- lib/features/action_center/presentation/screens/action_screen.dart
   ```

3. **Remove new files:**
   ```bash
   rm -rf lib/features/action_center/domain
   rm -rf lib/features/action_center/data
   rm lib/features/action_center/presentation/viewmodels/action_viewmodel.dart
   rm lib/core/database/migrations/migration_v2.dart
   ```

4. **Clean build:**
   ```bash
   flutter clean && flutter pub get
   ```

---

## Common Issues & Solutions

### Issue: "Provider not found in context"
**Cause:** ActionRepository not registered before ActionViewModel tries to read it
**Solution:** Check provider order in main.dart - datasources → repositories → consumers

### Issue: "Table already exists" error
**Cause:** Migration ran multiple times or version not incremented
**Solution:**
```bash
# Delete app data and reinstall
flutter clean
# Uninstall from device
# Reinstall - will create fresh database
```

### Issue: Actions disappear after restart
**Cause:** Not using `await` for database operations
**Solution:** Ensure all repository methods use `await` and return Futures

### Issue: "MissingPluginException"
**Cause:** Hot reload doesn't reinitialize native plugins
**Solution:** Full restart app (not hot reload) after database changes

---

## Key Learnings from Phase 1 Applied

1. **Suppress linter warnings early:** Add `// ignore_for_file: constant_identifier_names` to migration files
2. **Use `library;` directive:** Prevents dangling doc comment warnings
3. **Database constants:** Use typed constants from database_constants.dart, never hardcode strings
4. **DateTime handling:** SQLite stores as TEXT ISO 8601, requires manual parsing
5. **Boolean conversion:** SQLite uses INTEGER (0/1), convert in fromDatabase/toDatabase
6. **Testing pattern:** Always test database operations with in-memory or test database
7. **Error handling:** Wrap async operations in try-catch-finally, set loading states
8. **Code generation:** Run build_runner before testing JSON models

---

## Next Steps

After Phase 2 completion:
- **Validate:** Action Center fully functional with database persistence
- **Pattern established:** Repository → ViewModel → Provider → UI
- **Ready for replication:** Apply to Night Review (Phase 3)

---

## Notes

**Estimated Time:** 4-5 hours
- Migration & constants: 30 min
- Domain model: 45 min
- Repository & datasource: 90 min
- ViewModel: 60 min
- Screen refactoring: 60 min
- Testing & debugging: 45 min

**Success Criteria:**
- [ ] No analyzer warnings
- [ ] All tests pass
- [ ] Actions persist across app restarts
- [ ] Date navigation loads correct actions
- [ ] Toggle updates database immediately
- [ ] Empty state shows helpful message
