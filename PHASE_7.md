# PHASE 7: Habits Lab & Onboarding - Data Layer

## Overview
Create the data layer foundation for Habits Lab and Onboarding features. This phase focuses exclusively on repositories, models, and data structures. No UI or ViewModel implementation.

**Note:** UI Implementation will be done separately. See HABITS_LAB_IMPLEMENTATION_PLAN.md for UI details.

## Prerequisites
- **Phase 1-6 completed:** Full MVVM architecture working, Light module functional
- Database infrastructure in place
- Shared repository patterns established

## Goals
- Define Habits Lab scope and data requirements
- Create shared intervention repository for cross-module queries
- Extract hardcoded questionnaire questions to data models
- Define questionnaire data structure
- Prepare data layer for future UI implementation

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

## Step 7.2: Create Shared Intervention Repository

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

## Step 7.3: Create Onboarding Models - Question

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

## Step 7.4: Create Questionnaire Data

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

## Testing Checklist

### Data Layer Tests:

**Intervention Repository Tests:**
- [ ] Test `getAllActivitiesBetween()` returns correct activities for date range
- [ ] Test `getActivitiesForModule()` filters by module ID correctly
- [ ] Test `getCompletionCountsByModule()` calculates counts correctly
- [ ] Test edge cases: empty results, invalid date ranges

**Question Model Tests:**
- [ ] Test Question model creation with all question types
- [ ] Test copyWith method preserves/updates fields correctly
- [ ] Test nullable fields (minValue, maxValue) behavior

**Questionnaire Data Tests:**
- [ ] Verify all questions have valid IDs
- [ ] Verify question types match their option structures
- [ ] Verify scale questions have valid min/max values
- [ ] Verify choice questions have at least 2 options

---

## Rollback Strategy

- Phase 7 data layer is additive - doesn't modify existing features
- Repository can be added without breaking current code
- Models can coexist with current hardcoded implementations
- Safe to implement incrementally

---

## Data Layer Completion Checklist

### Code Quality:
- [ ] Remove unused imports from new files
- [ ] Run `flutter analyze` on new files - Fix all warnings
- [ ] Run `dart format .` on new files
- [ ] Add documentation comments to all public APIs

### Database:
- [ ] Verify intervention_activities table has necessary indexes
- [ ] Test repository queries with sample data
- [ ] Verify query performance with larger datasets

---

## After Phase 7 Data Layer Complete

**Data Foundation Ready:**
- ✅ Shared intervention repository for cross-module queries
- ✅ Question model for dynamic questionnaire system
- ✅ Questionnaire data extracted from hardcoded screens
- ✅ Data layer ready for UI implementation

**Next Steps:**
1. **UI Implementation:** See HABITS_LAB_IMPLEMENTATION_PLAN.md
2. **ViewModels:** Create ViewModels once UI requirements are clear
3. **Screen Refactoring:** Refactor screens to use new data models
4. **Integration:** Connect UI to data layer through ViewModels

---

## Notes

**Why Data Layer First?**
- Establishes clear contracts before UI implementation
- Allows parallel work on data access and UI design
- Data models can be tested independently
- Reduces rework if UI requirements change

**Questionnaire Data Structure:**
- Data-driven approach allows easy question changes
- Can add/remove questions without code changes
- Could even load questions from server in future
- Type-safe with enums for question types

**Intervention Repository Benefits:**
- Centralized access to all intervention data
- Enables cross-module analytics
- Foundation for Habits Lab feature
- Reusable for future correlation analysis

**Estimated Time:** 2-3 hours (Data Layer Only)
- Intervention repository: 60 minutes
- Question model: 30 minutes
- Questionnaire data: 30 minutes
- Testing & documentation: 30 minutes
