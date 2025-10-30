# PHASE 2: Action Center Refactoring (Pilot Feature)

## Overview
Refactor Action Center as the pilot feature to demonstrate full MVVM + Provider + Database architecture. This validates the pattern before rolling out to other screens.

## Prerequisites
- **Phase 1 completed:** Database infrastructure, UUID generator, constants
- Database initialized with all tables
- Provider package added to dependencies

## Goals
- Create first domain model with JSON serialization
- Implement repository pattern (interface + implementation)
- Create first ViewModel with ChangeNotifier
- Refactor ActionScreen from StatefulWidget to StatelessWidget + Provider
- Migrate from hardcoded data to database persistence

---

## Step 2.1: Create Domain Model - DailyAction

**File:** `lib/features/action_center/domain/models/daily_action.dart`
**Purpose:** Data model for action items displayed in Action Center
**Dependencies:** `json_annotation`, `uuid_generator`

**Class: DailyAction**

**Fields:**
- `String id` - UUID, primary key
- `String userId` - Foreign key to users table
- `String title` - Action text (e.g., "Drink a glass of water")
- `String iconName` - Icon identifier (e.g., "local_drink")
- `bool isCompleted` - Completion status
- `DateTime createdAt` - When action was created
- `DateTime? completedAt` - When action was completed (nullable)

**Methods:**
- `DailyAction({required fields})` - Constructor
- `factory DailyAction.fromJson(Map<String, dynamic> json)` - Deserialize from JSON/database
- `Map<String, dynamic> toJson()` - Serialize to JSON/database
- `DailyAction copyWith({...})` - Immutable update helper
- `IconData get icon` - Helper to convert iconName string to IconData

**Annotations:**
- `@JsonSerializable()` for code generation

**Why:** Replaces hardcoded `Map<String, dynamic>` in ActionScreen (line 19-35)

---

## Step 2.2: Create Repository Interface

**File:** `lib/features/action_center/domain/repositories/action_repository.dart`
**Purpose:** Abstract interface defining action data operations
**Dependencies:** `daily_action.dart`

**Abstract Class: ActionRepository**

**Methods:**
- `Future<List<DailyAction>> getActionsForDate(String userId, DateTime date)` - Fetch actions for specific date
- `Future<List<DailyAction>> getTodayActions(String userId)` - Convenience method for today's actions
- `Future<void> saveAction(DailyAction action)` - Insert or update action
- `Future<void> deleteAction(String actionId)` - Remove action
- `Future<void> toggleActionCompletion(String actionId)` - Mark as completed/uncompleted
- `Future<int> getCompletionCount(String userId, DateTime date)` - Count completed actions

**Why:** Allows swapping implementations (SQLite, mock, future API) without changing business logic

---

## Step 2.3: Create Local Data Source

**File:** `lib/features/action_center/data/datasources/action_local_datasource.dart`
**Purpose:** SQLite operations for action items
**Dependencies:** `sqflite`, `database_helper`, `database_constants`, `daily_action`

**Class: ActionLocalDataSource**

**Constructor:**
- `ActionLocalDataSource({required Database database})` - Inject database instance

**Methods:**

**`Future<List<DailyAction>> getActionsByDate(String userId, DateTime date)`**
- Query actions table filtered by userId and date
- Convert List<Map> to List<DailyAction> using fromJson
- Return list sorted by createdAt

**`Future<DailyAction?> getActionById(String actionId)`**
- Query single action by ID
- Return DailyAction or null if not found

**`Future<void> insertAction(DailyAction action)`**
- Convert action to Map using toJson
- Execute INSERT into actions table
- Handle conflicts (replace if ID exists)

**`Future<void> updateAction(DailyAction action)`**
- Convert to Map
- Execute UPDATE where id = action.id

**`Future<void> deleteAction(String actionId)`**
- Execute DELETE where id = actionId

**`Future<void> toggleCompletion(String actionId)`**
- Fetch current action
- Flip isCompleted boolean
- Set completedAt to now() if completing, null if uncompleting
- Update in database

**`Future<int> countCompletedActions(String userId, DateTime date)`**
- Query COUNT(*) where userId, date, and isCompleted = true
- Return integer count

**Why:** Separates raw SQL operations from business logic

---

## Step 2.4: Implement Repository

**File:** `lib/features/action_center/data/repositories/action_repository_impl.dart`
**Purpose:** Concrete implementation of ActionRepository using ActionLocalDataSource
**Dependencies:** `action_repository`, `action_local_datasource`, `daily_action`

**Class: ActionRepositoryImpl implements ActionRepository**

**Constructor:**
- `ActionRepositoryImpl({required ActionLocalDataSource dataSource})` - Inject datasource

**Fields:**
- `final ActionLocalDataSource _dataSource` - Private datasource instance

**Methods:**

**`Future<List<DailyAction>> getActionsForDate(String userId, DateTime date)`**
- Delegates to `_dataSource.getActionsByDate(userId, date)`
- Returns result directly

**`Future<List<DailyAction>> getTodayActions(String userId)`**
- Calls `getActionsForDate(userId, DateTime.now())`

**`Future<void> saveAction(DailyAction action)`**
- If action.id exists in database: calls `_dataSource.updateAction(action)`
- Else: calls `_dataSource.insertAction(action)`

**`Future<void> deleteAction(String actionId)`**
- Delegates to `_dataSource.deleteAction(actionId)`

**`Future<void> toggleActionCompletion(String actionId)`**
- Delegates to `_dataSource.toggleCompletion(actionId)`

**`Future<int> getCompletionCount(String userId, DateTime date)`**
- Delegates to `_dataSource.countCompletedActions(userId, date)`

**Why:** Repository pattern allows easy mocking for tests, could switch to API datasource later

---

## Step 2.5: Create ViewModel

**File:** `lib/features/action_center/presentation/viewmodels/action_viewmodel.dart`
**Purpose:** Manage Action Center state, handle business logic, notify UI of changes
**Dependencies:** `provider`, `action_repository`, `daily_action`

**Class: ActionViewModel extends ChangeNotifier**

**Constructor:**
- `ActionViewModel({required ActionRepository repository})` - Inject repository

**Fields:**
- `final ActionRepository _repository` - Private repository instance
- `List<DailyAction> _actions = []` - Current actions list
- `bool _isLoading = false` - Loading state
- `String? _errorMessage` - Error message (nullable)
- `DateTime _currentDate = DateTime.now()` - Selected date

**Getters:**
- `List<DailyAction> get actions => _actions` - Expose actions list
- `bool get isLoading => _isLoading` - Expose loading state
- `String? get errorMessage => _errorMessage` - Expose error message
- `DateTime get currentDate => _currentDate` - Expose current date
- `int get completedCount => _actions.where((a) => a.isCompleted).length` - Count completed actions

**Methods:**

**`Future<void> loadActions(String userId)`**
- Set `_isLoading = true`, notify listeners
- Try: Fetch actions from repository for currentDate
- Assign to `_actions`
- Catch errors: Set `_errorMessage`
- Finally: Set `_isLoading = false`, notify listeners

**`Future<void> toggleAction(String actionId)`**
- Call `_repository.toggleActionCompletion(actionId)`
- Reload actions to reflect change
- Notify listeners

**`Future<void> addAction(String userId, String title, String iconName)`**
- Create new DailyAction with UUID, current date
- Call `_repository.saveAction(action)`
- Reload actions
- Notify listeners

**`Future<void> deleteAction(String actionId)`**
- Call `_repository.deleteAction(actionId)`
- Remove from `_actions` list locally
- Notify listeners

**`Future<void> changeDate(DateTime newDate)`**
- Set `_currentDate = newDate`
- Reload actions for new date
- Notify listeners

**`void clearError()`**
- Set `_errorMessage = null`
- Notify listeners

**Why:** Separates business logic from UI, reactive updates via ChangeNotifier

---

## Step 2.6: Refactor ActionScreen

**File:** `lib/features/action_center/presentation/screens/action_screen.dart`
**Purpose:** Transform from StatefulWidget with local state to StatelessWidget consuming ViewModel
**Dependencies:** `provider`, `action_viewmodel`, `daily_action`, existing widgets

**Changes:**

### Remove (DELETE):
- `class _ActionScreenState extends State<ActionScreen>` (lines 15-110)
- `List<Map<String, dynamic>> _actionItems` (lines 19-35) - HARDCODED DATA
- `DateTime _currentDate` (line 16) - Moved to ViewModel
- All `setState()` calls

### Convert:
- `class ActionScreen extends StatefulWidget` → `class ActionScreen extends StatelessWidget`

### New Structure:

**`class ActionScreen extends StatelessWidget`**

**Build Method:**
```
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => ActionViewModel(
      repository: context.read<ActionRepository>(), // Injected from main.dart
    )..loadActions('hardcoded-user-id'), // TODO: Get from auth
    child: _ActionScreenContent(),
  );
}
```

**`class _ActionScreenContent extends StatelessWidget`**

**Build Method:**
- Use `context.watch<ActionViewModel>()` to consume ViewModel
- Show loading spinner if `viewModel.isLoading`
- Show error message if `viewModel.errorMessage != null`
- Use `viewModel.actions` instead of `_actionItems`
- Call `viewModel.toggleAction(id)` on checkbox change
- Call `viewModel.changeDate()` on date navigation
- Use `DateNavigationHeader` with ViewModel's currentDate

**ListView.builder:**
- `itemCount: viewModel.actions.length`
- Access action via `viewModel.actions[index]`
- CheckboxButton receives action data
- `onChanged: (value) => viewModel.toggleAction(action.id)`

**AcceptanceButton:**
- Shows `viewModel.completedCount` in SnackBar

**Why:** UI is now a pure reflection of ViewModel state, no local state management

---

## Testing Checklist

### Manual Tests:
- [ ] Launch app, navigate to Action Center
- [ ] Should display empty list (no actions in database yet)
- [ ] Manually insert test action via SQLite browser
- [ ] Restart app, action should appear
- [ ] Tap checkbox, action should toggle completion
- [ ] Check database, `isCompleted` field should change
- [ ] Tap "Complete Actions" button, SnackBar shows correct count
- [ ] Change date, actions for that date should load

### Unit Tests to Create:
- [ ] Test DailyAction.fromJson / toJson
- [ ] Test ActionLocalDataSource CRUD operations (use in-memory database)
- [ ] Test ActionRepositoryImpl delegates correctly
- [ ] Test ActionViewModel state changes and notifyListeners calls

### Integration Tests:
- [ ] End-to-end: Create action → Save to DB → Display in UI → Toggle → Verify in DB

### Database Validation:
```sql
-- Check actions table exists
SELECT * FROM daily_actions;

-- Insert test action
INSERT INTO daily_actions (id, user_id, title, icon_name, is_completed, created_at)
VALUES ('test-uuid', 'user123', 'Test Action', 'check', 0, datetime('now'));

-- Verify toggle updates completedAt
SELECT id, is_completed, completed_at FROM daily_actions;
```

---

## Rollback Strategy

**If Phase 2 fails:**

### Option A: Keep old ActionScreen
1. Rename refactored file to `action_screen_new.dart`
2. Keep original `action_screen.dart` active
3. Toggle between implementations in `main_navigation.dart`

### Option B: Full rollback
1. Delete all new files:
   - `lib/features/action_center/domain/`
   - `lib/features/action_center/data/`
   - `lib/features/action_center/presentation/viewmodels/`
2. Restore original `action_screen.dart` from git:
   ```bash
   git checkout -- lib/features/action_center/presentation/screens/action_screen.dart
   ```

### Option C: Disable Provider temporarily
1. Keep files but don't use in UI
2. Test individually in isolation
3. Fix issues before UI integration

---

## Common Issues & Solutions

### Issue: "Provider not found"
**Solution:** Ensure ActionRepository is registered in main.dart MultiProvider before ActionViewModel tries to read it

### Issue: "Database locked"
**Solution:** Ensure database operations use async/await, don't call from initState synchronously

### Issue: "Actions not updating"
**Solution:** Check that `notifyListeners()` is called after state changes in ViewModel

### Issue: "null check operator on null value"
**Solution:** Ensure proper null safety, use `?` and `??` operators for nullable fields

---

## Next Steps

After Phase 2 completion:
- **Validate pattern works:** Action Center should fully function with database persistence
- Proceed to **PHASE_3.md:** Apply same pattern to Night Review screen
- Pattern is now proven and can be replicated for other features

---

## Notes

**Why Action Center as pilot?**
- Simplest data model (just action items)
- No complex relationships or calculations
- Clear user interactions (toggle checkbox)
- Easy to test manually

**Key Learning from Phase 2:**
- Repository pattern isolates data access
- ViewModel simplifies UI logic
- Provider makes state reactiv
- Database persistence "just works" once plumbing is set up

**Database Schema for Actions:**
```sql
CREATE TABLE daily_actions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,  -- SQLite boolean
  created_at TEXT NOT NULL,                 -- ISO 8601 datetime
  completed_at TEXT,                        -- Nullable
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_daily_actions_user_date ON daily_actions(user_id, created_at);
```

**Estimated Time:** 4-6 hours
- Domain model: 30 minutes
- Repository interface: 20 minutes
- Data source: 60 minutes
- Repository impl: 30 minutes
- ViewModel: 90 minutes
- Screen refactoring: 90 minutes
- Testing: 60 minutes
