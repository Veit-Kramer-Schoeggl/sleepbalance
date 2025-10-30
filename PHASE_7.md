# PHASE 7: Habits Lab & Onboarding (Final Cleanup)

## Overview
Complete the refactoring by migrating the remaining screens (Habits Lab, Onboarding Questionnaire) to MVVM + Provider pattern. Extract hardcoded questionnaire data to models, polish UI, add final touches.

## Prerequisites
- **Phase 1-6 completed:** Full MVVM architecture working, Light module functional
- Only Habits Lab and Onboarding remain as StatefulWidget with local state
- App is fully functional, this phase is cleanup and polish

## Goals
- Refactor Habits Lab screen (currently placeholder)
- Extract hardcoded questionnaire questions to data models
- Create Onboarding ViewModel for questionnaire flow
- Refactor QuestionnaireScreen to use ViewModel
- Polish navigation and UX
- Final testing and cleanup

---

## Step 7.1: Decide Habits Lab Scope

**Decision Point:** What should Habits Lab do?

### Option A: Module Activity History
- Show all intervention activities across all modules
- Display charts/graphs of adherence
- "Experiments" = trying different module combinations

### Option B: Habit Tracking (Separate from Modules)
- Custom habits user wants to track (e.g., "No caffeine after 2pm")
- Not intervention modules, but personal habits

### Option C: Defer Implementation
- Keep as placeholder for now
- Focus on core features (modules, sleep tracking)

**Recommendation:** **Option A** - Module activity history and correlation analysis

**Why:** Leverages existing intervention_activities data, provides value immediately

---

## Step 7.2: Create Habits Lab ViewModel (Option A)

**File:** `lib/features/habits_lab/presentation/viewmodels/habits_viewmodel.dart`
**Purpose:** Aggregate and display intervention activity history
**Dependencies:** `provider`, `intervention_repository` (create shared repo)

**Class: HabitsViewModel extends ChangeNotifier**

**Constructor:**
- `HabitsViewModel({required InterventionRepository repository})`

**Fields:**
- `final InterventionRepository _repository`
- `List<InterventionActivity> _allActivities = []`
- `Map<String, int> _moduleCompletionCounts = {}` - Module ID → count
- `DateTime _startDate = DateTime.now().subtract(Duration(days: 30))`
- `DateTime _endDate = DateTime.now()`
- `bool _isLoading = false`

**Getters:**
- `List<InterventionActivity> get activities`
- `Map<String, int> get completionCounts`
- `double getCompletionRate(String moduleId)` - % of days completed

**Methods:**

**`Future<void> loadActivities(String userId)`**
- Fetch all activities between startDate and endDate
- Group by module ID, calculate counts
- Notify listeners

**`Future<void> changeDateRange(DateTime start, DateTime end)`**
- Update date range
- Reload activities

**`List<InterventionActivity> getActivitiesForModule(String moduleId)`**
- Filter _allActivities by moduleId

---

## Step 7.3: Refactor Habits Lab Screen (Option A)

**File:** `lib/features/habits_lab/presentation/screens/habits_screen.dart`
**Purpose:** Display module activity history and stats
**Dependencies:** `provider`, `habits_viewmodel`, widgets

**Changes:**

### Remove:
- Placeholder UI (lines 24-64)

### Add:

**Build Method:**
```
ChangeNotifierProvider(
  create: (_) => HabitsViewModel(
    repository: context.read<InterventionRepository>(),
  )..loadActivities(userId),
  child: _HabitsScreenContent(),
)
```

**`class _HabitsScreenContent`**

**Build:**
- `final viewModel = context.watch<HabitsViewModel>()`
- Show loading spinner if loading
- **Module Cards:**
  - For each enabled module (Light, Sport, etc.)
  - Show completion count: "15/30 days"
  - Show completion rate: "50%"
  - Tap to see details
- **Activity Timeline:**
  - List of recent activities
  - Date, module, completed status
- **Date Range Selector:**
  - Last 7 days, 30 days, custom range

**Why:** Provides insights into module adherence

---

## Step 7.4: Create Shared Intervention Repository (if needed)

**File:** `lib/modules/shared/domain/repositories/intervention_repository.dart`
**Purpose:** Query all intervention activities across modules
**Dependencies:** `intervention_activity`

**Abstract Class: InterventionRepository**

**Methods:**
- `Future<List<InterventionActivity>> getAllActivitiesBetween(String userId, DateTime start, DateTime end)`
- `Future<List<InterventionActivity>> getActivitiesForModule(String userId, String moduleId, DateTime start, DateTime end)`
- `Future<Map<String, int>> getCompletionCountsByModule(String userId, DateTime start, DateTime end)`

**Implementation:** `InterventionRepositoryImpl` queries intervention_activities table

**Register in Provider:** Add to main.dart

---

## Step 7.5: Create Onboarding Models - Question

**File:** `lib/features/onboarding/domain/models/question.dart`
**Purpose:** Model for questionnaire questions
**Dependencies:** None

**Class: Question**

**Fields:**
- `String id` - Unique question ID
- `String text` - Question text
- `QuestionType type` - Enum: single_choice, multiple_choice, scale, text_input
- `List<String> options` - Answer options (for choice questions)
- `int? minValue` - For scale questions (nullable)
- `int? maxValue` - For scale questions (nullable)

**Enum: QuestionType**
- `single_choice`, `multiple_choice`, `scale`, `text_input`

**Methods:**
- Constructor, copyWith

**Why:** Replaces hardcoded question text in QuestionnaireScreen

---

## Step 7.6: Create Questionnaire Data

**File:** `lib/features/onboarding/data/questionnaire_data.dart`
**Purpose:** Define actual questionnaire questions
**Dependencies:** `question.dart`

**Constant: List<Question> questionnaireQuestions**
```dart
final List<Question> questionnaireQuestions = [
  Question(
    id: 'q1',
    text: 'How would you rate your current sleep quality?',
    type: QuestionType.scale,
    minValue: 1,
    maxValue: 5,
  ),
  Question(
    id: 'q2',
    text: 'How many hours of sleep do you typically get per night?',
    type: QuestionType.single_choice,
    options: ['Less than 6', '6-7', '7-8', '8-9', 'More than 9'],
  ),
  Question(
    id: 'q3',
    text: 'What sleep issues do you experience? (Select all that apply)',
    type: QuestionType.multiple_choice,
    options: [
      'Difficulty falling asleep',
      'Waking up during the night',
      'Waking up too early',
      'Not feeling rested',
    ],
  ),
  Question(
    id: 'q4',
    text: 'Which interventions are you interested in trying?',
    type: QuestionType.multiple_choice,
    options: [
      'Light therapy',
      'Exercise',
      'Meditation',
      'Sleep hygiene improvements',
    ],
  ),
];
```

**Why:** Centralized question data, easy to modify

---

## Step 7.7: Create Onboarding ViewModel

**File:** `lib/features/onboarding/presentation/viewmodels/questionnaire_viewmodel.dart`
**Purpose:** Manage questionnaire flow state
**Dependencies:** `provider`, `question`, `questionnaire_data`, `user_repository`

**Class: QuestionnaireViewModel extends ChangeNotifier**

**Constructor:**
- `QuestionnaireViewModel({required UserRepository userRepository})`

**Fields:**
- `final UserRepository _userRepository`
- `final List<Question> _questions = questionnaireQuestions`
- `int _currentQuestionIndex = 0`
- `Map<String, dynamic> _answers = {}` - Question ID → Answer
- `bool _isComplete = false`

**Getters:**
- `Question get currentQuestion => _questions[_currentQuestionIndex]`
- `int get currentIndex => _currentQuestionIndex`
- `int get totalQuestions => _questions.length`
- `double get progress => (_currentQuestionIndex + 1) / _questions.length`
- `bool get isComplete => _isComplete`
- `bool get canGoNext => _answers.containsKey(currentQuestion.id)`

**Methods:**

**`void answerQuestion(String questionId, dynamic answer)`**
- Store answer in _answers map
- Notify listeners

**`void nextQuestion()`**
- If currentIndex < totalQuestions - 1: increment index
- Else: set isComplete = true
- Notify listeners

**`void previousQuestion()`**
- If currentIndex > 0: decrement index
- Notify listeners

**`Future<void> submitAnswers(String userId)`**
- Process answers (e.g., pre-enable modules based on Q4 answer)
- Create/update user profile based on answers
- Mark onboarding as complete in SharedPreferences
- Notify listeners

**`void reset()`**
- Reset to first question, clear answers

---

## Step 7.8: Refactor Questionnaire Screen

**File:** `lib/features/onboarding/presentation/screens/questionnaire_screen.dart`
**Purpose:** Transform to ViewModel-driven flow
**Dependencies:** `provider`, `questionnaire_viewmodel`, widgets

**Changes:**

### Remove:
- All 4 screen classes (QuestionnaireScreen, SleepDifficultiesScreen, ExampleQuestion1Screen, etc.)
- Hardcoded question text
- Manual navigation between screens

### Create Single Screen:

**`class QuestionnaireScreen extends StatelessWidget`**

**Build Method:**
```
ChangeNotifierProvider(
  create: (_) => QuestionnaireViewModel(
    userRepository: context.read<UserRepository>(),
  ),
  child: _QuestionnaireContent(),
)
```

**`class _QuestionnaireContent extends StatelessWidget`**

**Build:**
- `final viewModel = context.watch<QuestionnaireViewModel>()`
- **Progress Indicator:** LinearProgressIndicator(value: viewModel.progress)
- **Question Display:**
  - Show `viewModel.currentQuestion.text`
  - Render answer UI based on question type:
    - `single_choice`: Radio buttons
    - `multiple_choice`: Checkboxes
    - `scale`: Slider
    - `text_input`: TextField
- **Navigation Buttons:**
  - Previous (if not first question)
  - Next / Submit (if answer provided)
- **On Submit:**
  - Call `viewModel.submitAnswers(userId)`
  - Navigate to MainNavigation

**Why:** Single screen with dynamic content, data-driven questions

---

## Step 7.9: Update Splash Screen Navigation

**File:** `lib/shared/screens/app/splash_screen.dart` (modify)
**Purpose:** Navigate to refactored QuestionnaireScreen
**Action:** Already navigates correctly, no changes needed

---

## Step 7.10: Polish and Final Touches

### Add Missing Widgets:
- `lib/shared/widgets/ui/time_picker_field.dart` - Time selection widget
- `lib/shared/widgets/ui/duration_picker_field.dart` - Duration selection widget

**TimePicker Widget:**
- Displays formatted time (HH:mm)
- Taps to show time picker dialog
- Callback with selected time

**Duration Picker Widget:**
- Slider for duration (15-120 minutes)
- Shows formatted duration ("30 minutes")

### Update App Theme (Optional):
- `lib/shared/theme/app_theme.dart` - Centralize colors, text styles
- Apply consistent styling across all screens

### Add Loading States:
- Ensure all screens show loading indicators during async operations
- Consistent error handling with SnackBars

---

## Testing Checklist

### Manual Tests - Habits Lab:
- [ ] Navigate to Habits Lab
- [ ] Should show message if no activities yet
- [ ] After logging light activity, should display in Habits Lab
- [ ] Show completion counts and rates
- [ ] Date range selector works

### Manual Tests - Onboarding:
- [ ] Clear app data, relaunch
- [ ] Should show splash → questionnaire
- [ ] Answer all questions, can navigate back/forward
- [ ] Submit answers, should navigate to main app
- [ ] Restart app, should skip questionnaire (not first launch)
- [ ] Check database, user preferences should reflect answers

### Unit Tests:
- [ ] Test QuestionnaireViewModel state transitions
- [ ] Test answer storage and validation
- [ ] Test HabitsViewModel completion rate calculations

### Integration Tests:
- [ ] Full onboarding flow → main app → no errors

---

## Rollback Strategy

- Phase 7 is final polish, doesn't break existing features
- Can keep old screens if needed
- Habits Lab can stay as placeholder if Option A is too complex

---

## Final Cleanup Tasks

### Code Quality:
- [ ] Remove unused imports
- [ ] Run `flutter analyze` - Fix all warnings
- [ ] Run `dart format .` - Format all code
- [ ] Add documentation comments to public APIs

### Performance:
- [ ] Profile app startup time
- [ ] Check for memory leaks (use DevTools)
- [ ] Optimize database queries (add missing indexes)

### Documentation:
- [ ] Update README.md if needed
- [ ] Document any environment setup required
- [ ] Create CONTRIBUTING.md if planning to open-source

---

## Project Complete!

After Phase 7:
- ✅ Full MVVM + Provider architecture
- ✅ Database persistence with SQLite
- ✅ Action Center with database integration
- ✅ Night Review with sleep tracking
- ✅ Settings with user profile management
- ✅ Light module (first intervention) fully functional
- ✅ Habits Lab showing activity history
- ✅ Onboarding questionnaire refactored

**Next Steps:**
1. **Add more modules:** Sport, Meditation, Temperature, etc. (follow Light pattern)
2. **Wearable integration:** Connect to Apple Health / Google Fit
3. **Baseline calculation:** Automated calculation of personal averages
4. **Correlation analysis:** UI to show which interventions improve sleep
5. **Notifications:** Expand notification system with more triggers
6. **Authentication:** Add proper login/signup (currently single user)
7. **PostgreSQL sync:** Implement server sync for cloud backup
8. **Charts & Visualizations:** Add charts to Night Review and Habits Lab
9. **Recommendation engine:** AI-powered sleep improvement suggestions
10. **Testing:** Comprehensive unit and integration tests

---

## Notes

**Why Habits Lab last?**
- Depends on intervention data existing
- Less critical than core features
- Can be placeholder until modules are used

**Questionnaire Refactoring:**
- Data-driven approach allows easy question changes
- Can add/remove questions without code changes
- Could even load questions from server in future

**Technical Debt Addressed:**
- All hardcoded data moved to models/database
- All screens using MVVM + Provider
- Consistent architecture across features

**Estimated Time:** 4-5 hours
- Habits Lab: 120 minutes
- Onboarding models: 45 minutes
- Questionnaire ViewModel: 60 minutes
- Screen refactoring: 60 minutes
- Testing & polish: 60 minutes

---

## Congratulations!

You've successfully migrated your Flutter app to a professional MVVM + Provider architecture with:
- Clean separation of concerns
- Testable business logic
- Scalable module system
- Offline-first data persistence
- Reactive UI updates

The codebase is now ready for feature expansion, team collaboration, and long-term maintenance.
