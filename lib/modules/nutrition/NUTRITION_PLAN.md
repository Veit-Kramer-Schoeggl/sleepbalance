# Nutrition Module - Implementation Plan

## Overview
Implement the Nutrition Module to educate users about the relationship between diet and sleep quality. Unlike other modules (which track interventions), this is primarily an educational/content delivery module with optional food diary.

**Core Principle:** Nutrition directly impacts sleep quality. Certain foods, nutrients, and dietary patterns can enhance or hinder sleep. This module provides personalized, science-backed nutritional guidance.

## Prerequisites
- ✅ **Previous modules completed:** Pattern established
- 📚 **Read:** NUTRITION_README.md

## Goals
- Create educational content library (tips, articles, food database)
- Implement content recommendation system
- Build daily tip delivery with notifications
- Create optional food diary (simple logging)
- Track content engagement
- **Expected outcome:** Nutrition module delivers personalized educational content

---

## Step N.1: Database Migration - Nutrition Content & Food Diary

**File:** `lib/core/database/migrations/migration_v10.dart`

**SQL Migration:**
```sql
-- Nutrition educational content
CREATE TABLE IF NOT EXISTS nutrition_content (
  id TEXT PRIMARY KEY,
  content_type TEXT NOT NULL,        -- 'tip', 'article', 'recipe', 'food_spotlight'
  title TEXT NOT NULL,
  content_text TEXT NOT NULL,
  category TEXT NOT NULL,            -- 'sleep_promoting', 'foods_to_avoid', 'nutrients', 'myths'
  target_audience TEXT,              -- 'omnivore', 'vegetarian', 'vegan', 'gluten_free', etc.
  reading_time_minutes INTEGER,
  source_citation TEXT,              -- Research reference
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Food database
CREATE TABLE IF NOT EXISTS foods_library (
  id TEXT PRIMARY KEY,
  food_name TEXT NOT NULL,
  category TEXT NOT NULL,            -- 'protein', 'vegetable', 'fruit', 'grain', 'dairy', 'nuts', 'beverage'
  sleep_effect TEXT,                 -- 'promotes_sleep', 'neutral', 'disrupts_sleep'
  sleep_effect_reason TEXT,          -- Why it affects sleep (tryptophan, magnesium, etc.)
  key_nutrients TEXT,                -- JSON array: ['tryptophan', 'magnesium', 'melatonin']
  best_time_to_eat TEXT,             -- 'morning', 'afternoon', 'evening', 'anytime'
  portion_guidance TEXT,             -- Serving size guidance
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL
);

-- User's optional food diary
CREATE TABLE IF NOT EXISTS food_diary_entries (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  entry_date TEXT NOT NULL,
  meal_type TEXT NOT NULL,           -- 'breakfast', 'lunch', 'dinner', 'snack'
  food_id TEXT,                      -- FK to foods_library (nullable for free text)
  food_name_freetext TEXT,           -- If not in library
  portion_size TEXT,
  time_eaten TEXT,                   -- HH:mm
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (food_id) REFERENCES foods_library(id)
);

-- User's content engagement tracking
CREATE TABLE IF NOT EXISTS nutrition_content_views (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  content_id TEXT NOT NULL,
  viewed_at TEXT NOT NULL,
  time_spent_seconds INTEGER,
  was_helpful INTEGER,               -- Boolean: did user mark as helpful
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (content_id) REFERENCES nutrition_content(id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_nutrition_content_category
ON nutrition_content(category, content_type, is_active);

CREATE INDEX IF NOT EXISTS idx_foods_library_effect
ON foods_library(sleep_effect, category);

CREATE INDEX IF NOT EXISTS idx_food_diary_user_date
ON food_diary_entries(user_id, entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_nutrition_content_views_user
ON nutrition_content_views(user_id, viewed_at DESC);

-- No intervention_activities index needed (nutrition is educational, not activity-based)
```

**Why:** Content library for tips/articles, food database for reference, optional diary

---

## Step N.2: Nutrition Content Model

**File:** `lib/modules/nutrition/domain/models/nutrition_content.dart`

**Class: NutritionContent**

**Fields:**
```dart
class NutritionContent {
  final String id;
  final String contentType;          // 'tip', 'article', 'recipe', 'food_spotlight'
  final String title;
  final String contentText;
  final String category;              // 'sleep_promoting', 'foods_to_avoid', 'nutrients', 'myths'
  final String? targetAudience;       // 'omnivore', 'vegetarian', 'vegan', etc.
  final int? readingTimeMinutes;
  final String? sourceCitation;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Methods:**
- Constructor, fromJson, toJson, fromDatabase, toDatabase
- `String get displayReadingTime => '$readingTimeMinutes min read';`
- `bool matchesUserPreferences(List<String> userDietaryPreferences)` - Check if content suitable for user

---

## Step N.3: Food Library Model

**File:** `lib/modules/nutrition/domain/models/food_item.dart`

**Class: FoodItem**

**Fields:**
```dart
class FoodItem {
  final String id;
  final String foodName;
  final String category;
  final String sleepEffect;           // 'promotes_sleep', 'neutral', 'disrupts_sleep'
  final String sleepEffectReason;
  final List<String> keyNutrients;    // ['tryptophan', 'magnesium', 'melatonin']
  final String bestTimeToEat;
  final String? portionGuidance;
  final bool isActive;
  final DateTime createdAt;
}
```

**Methods:**
- Constructor, fromJson, toJson, fromDatabase, toDatabase
- `bool get promotesSleep => sleepEffect == 'promotes_sleep';`
- `bool get disruptsSleep => sleepEffect == 'disrupts_sleep';`

---

## Step N.4: Nutrition Configuration Model

**File:** `lib/modules/nutrition/domain/models/nutrition_config.dart`

**Class: NutritionConfig**

**Fields:**
```dart
class NutritionConfig {
  // User dietary preferences
  final String dietType;              // 'omnivore', 'vegetarian', 'vegan', 'pescatarian'
  final List<String> restrictions;    // ['gluten_free', 'dairy_free', 'nut_free']
  final List<String> allergies;       // ['peanuts', 'shellfish', etc.]

  // Content preferences
  final List<String> interestedCategories; // Which content categories user wants
  final bool enableDailyTips;         // Default: true
  final String preferredTipTime;      // HH:mm - when to deliver tip notification

  // Food diary
  final bool enableFoodDiary;         // Default: false (optional feature)

  // Notification settings
  final bool notificationsEnabled;
  final int tipsPerWeek;              // 1-7 (how many tips per week)

  final String mode;                  // 'education_only' or 'with_diary'
}
```

**Static Defaults:**
```dart
static NutritionConfig get defaultConfig => NutritionConfig(
  dietType: 'omnivore',
  restrictions: [],
  allergies: [],
  interestedCategories: ['sleep_promoting', 'nutrients'],
  enableDailyTips: true,
  preferredTipTime: '08:00',  // Morning tip
  enableFoodDiary: false,
  notificationsEnabled: true,
  tipsPerWeek: 3,
  mode: 'education_only',
);
```

---

## Step N.5: Nutrition Repository Interface

**File:** `lib/modules/nutrition/domain/repositories/nutrition_repository.dart`
**Purpose:** Data operations for nutrition content and food library
**Dependencies:** Models

**Educational module - does NOT extend InterventionRepository** (no activity tracking)

```dart
import '../models/nutrition_content.dart';
import '../models/food_item.dart';
import '../models/nutrition_config.dart';

/// Nutrition repository for content and food library
abstract class NutritionRepository {
  // Content operations
  Future<List<NutritionContent>> getAllContent();
  Future<List<NutritionContent>> getContentByCategory(String category);
  Future<NutritionContent?> getContentById(String id);

  // Food library operations
  Future<List<FoodItem>> getAllFoods();
  Future<List<FoodItem>> getFoodsByCategory(String category);
  Future<List<FoodItem>> searchFoods(String query);

  // User interaction tracking
  Future<void> recordContentView(String userId, String contentId);
  Future<void> markContentHelpful(String userId, String contentId);

  // Configuration
  Future<NutritionConfig?> getUserConfig(String userId);
  Future<void> saveConfig(NutritionConfig config);
}
```

**Why different?** Nutrition is educational (content delivery), not activity tracking.

---

## Step N.6: Content Recommendation Service

**File:** `lib/modules/nutrition/domain/services/nutrition_recommendation_service.dart`

**Abstract Class: NutritionRecommendationService**

**Purpose:** Recommend content based on user preferences and history

**Methods:**
```dart
abstract class NutritionRecommendationService {
  /// Get daily tip for user (personalized)
  Future<NutritionContent?> getDailyTip(
    String userId,
    NutritionConfig config,
    List<NutritionContent> viewedContent,
  );

  /// Get recommended articles for user
  Future<List<NutritionContent>> getRecommendedContent(
    String userId,
    NutritionConfig config,
    int limit,
  );

  /// Search foods by name or effect
  Future<List<FoodItem>> searchFoods(String query);

  /// Get foods by category
  Future<List<FoodItem>> getFoodsByCategory(String category);

  /// Get sleep-promoting foods
  Future<List<FoodItem>> getSleepPromotingFoods();

  /// Get foods to avoid
  Future<List<FoodItem>> getFoodsToAvoid();
}
```

**Implementation Strategy:**
- Filter content by user's diet type and restrictions
- Avoid showing already-viewed content recently
- Rotate through categories to ensure variety
- Prioritize content user marked as "helpful"

---

## Step N.7: Nutrition ViewModel

**File:** `lib/modules/nutrition/presentation/viewmodels/nutrition_module_viewmodel.dart`

**Class: NutritionModuleViewModel extends ChangeNotifier**

**Fields (beyond standard):**
```dart
NutritionContent? _todaysTip;
List<NutritionContent> _recommendedContent = [];
List<FoodItem> _sleepPromotingFoods = [];
List<FoodItem> _foodsToAvoid = [];
List<FoodItem> _searchResults = [];

// Food diary (if enabled)
Map<DateTime, List<FoodDiaryEntry>> _foodDiary = {};
```

**Content Methods:**
```dart
Future<void> loadDailyTip(String userId) async {
  try {
    _isLoading = true;
    notifyListeners();

    final viewedContent = await _repository.getViewedContent(userId);

    _todaysTip = await _recommendationService.getDailyTip(
      userId,
      _nutritionConfig ?? NutritionConfig.defaultConfig,
      viewedContent,
    );

  } catch (e) {
    _errorMessage = 'Failed to load daily tip: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> loadRecommendedContent(String userId) async {
  try {
    _isLoading = true;
    notifyListeners();

    _recommendedContent = await _recommendationService.getRecommendedContent(
      userId,
      _nutritionConfig ?? NutritionConfig.defaultConfig,
      10,
    );

  } catch (e) {
    _errorMessage = 'Failed to load content: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> markContentAsViewed(String userId, NutritionContent content, int timeSpentSeconds) async {
  await _repository.recordContentView(userId, content.id, timeSpentSeconds);
}

Future<void> markContentAsHelpful(String userId, String contentId) async {
  await _repository.markContentHelpful(userId, contentId);
}
```

**Food Diary Methods:**
```dart
Future<void> logFood(String userId, FoodDiaryEntry entry) async {
  try {
    await _repository.saveFoodDiaryEntry(entry);
    await loadFoodDiary(userId, entry.entryDate);
  } catch (e) {
    _errorMessage = 'Failed to log food: $e';
  }
}

Future<void> loadFoodDiary(String userId, DateTime date) async {
  try {
    final entries = await _repository.getFoodDiaryEntries(userId, date);
    _foodDiary[date] = entries;
    notifyListeners();
  } catch (e) {
    _errorMessage = 'Failed to load food diary: $e';
  }
}
```

---

## Step N.8: Nutrition Content Screen

**File:** `lib/modules/nutrition/presentation/screens/nutrition_content_screen.dart`

**UI Components:**
```dart
// Daily tip card (prominent)
if (viewModel.todaysTip != null)
  Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text('Today\'s Sleep Nutrition Tip', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          SizedBox(height: 12),
          Text(viewModel.todaysTip!.title, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          Text(viewModel.todaysTip!.contentText),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(Icons.thumb_up_outlined),
                label: Text('Helpful'),
                onPressed: () {
                  viewModel.markContentAsHelpful(userId, viewModel.todaysTip!.id);
                },
              ),
            ],
          ),
        ],
      ),
    ),
  ),

// Category tabs
TabBar(
  tabs: [
    Tab(text: 'For You'),
    Tab(text: 'Foods to Eat'),
    Tab(text: 'Foods to Avoid'),
    Tab(text: 'Nutrients'),
  ],
),

TabBarView(
  children: [
    // For You tab: Recommended content
    ListView.builder(
      itemCount: viewModel.recommendedContent.length,
      itemBuilder: (context, index) {
        final content = viewModel.recommendedContent[index];
        return ContentCard(
          content: content,
          onTap: () {
            _navigateToContentDetail(content);
          },
        );
      },
    ),

    // Foods to Eat tab
    ListView.builder(
      itemCount: viewModel.sleepPromotingFoods.length,
      itemBuilder: (context, index) {
        final food = viewModel.sleepPromotingFoods[index];
        return FoodCard(
          food: food,
          onTap: () {
            _showFoodDetail(food);
          },
        );
      },
    ),

    // Foods to Avoid tab
    ListView.builder(
      itemCount: viewModel.foodsToAvoid.length,
      itemBuilder: (context, index) {
        final food = viewModel.foodsToAvoid[index];
        return FoodCard(
          food: food,
          showWarning: true,
          onTap: () {
            _showFoodDetail(food);
          },
        );
      },
    ),

    // Nutrients tab
    NutrientsInfoWidget(),
  ],
),
```

---

## Step N.9: Food Diary Screen (Optional)

**File:** `lib/modules/nutrition/presentation/screens/food_diary_screen.dart`

**Purpose:** Simple food logging (if user enables this feature)

**UI Components:**
```dart
// Date selector
DateNavigationHeader(
  selectedDate: _selectedDate,
  onDateChanged: (date) {
    setState(() => _selectedDate = date);
    viewModel.loadFoodDiary(userId, date);
  },
),

// Add food button
FloatingActionButton(
  child: Icon(Icons.add),
  onPressed: () {
    _showAddFoodDialog();
  },
),

// Food diary entries for selected date
ListView.builder(
  itemCount: viewModel.foodDiary[_selectedDate]?.length ?? 0,
  itemBuilder: (context, index) {
    final entry = viewModel.foodDiary[_selectedDate]![index];
    return ListTile(
      leading: _getMealTypeIcon(entry.mealType),
      title: Text(entry.foodName),
      subtitle: Text('${entry.timeEaten} • ${entry.portionSize}'),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          viewModel.deleteFoodDiaryEntry(entry.id);
        },
      ),
    );
  },
),
```

---

## Testing Checklist

### Manual Tests:
- [ ] Enable Nutrition module, load daily tip
- [ ] View tip, verify marked as viewed in database
- [ ] Mark tip as helpful, verify saved
- [ ] Browse "Foods to Eat" tab, see sleep-promoting foods
- [ ] Browse "Foods to Avoid" tab, see caffeine/alcohol/heavy foods
- [ ] Search for specific food, verify results match query
- [ ] Set dietary preferences (vegan), verify content filtered
- [ ] Enable food diary, log a meal, verify saved
- [ ] View food diary for past date, verify entries shown
- [ ] Receive daily tip notification at configured time

### Content Tests:
- [ ] Verify tips rotate (don't show same tip twice in a row)
- [ ] Verify content respects dietary restrictions (no dairy for vegan)
- [ ] Verify content categories match user interests

### Database Tests:
```sql
-- Check nutrition content library
SELECT
  content_type,
  title,
  category,
  reading_time_minutes
FROM nutrition_content
WHERE is_active = 1
ORDER BY created_at DESC;

-- Check viewed content
SELECT
  nc.title,
  ncv.viewed_at,
  ncv.time_spent_seconds,
  ncv.was_helpful
FROM nutrition_content_views ncv
JOIN nutrition_content nc ON nc.id = ncv.content_id
WHERE ncv.user_id = 'test-user-id'
ORDER BY ncv.viewed_at DESC;

-- Check food diary
SELECT
  entry_date,
  meal_type,
  food_name_freetext,
  time_eaten
FROM food_diary_entries
WHERE user_id = 'test-user-id'
ORDER BY entry_date DESC, time_eaten;

-- Check sleep-promoting foods
SELECT
  food_name,
  sleep_effect,
  sleep_effect_reason,
  key_nutrients
FROM foods_library
WHERE sleep_effect = 'promotes_sleep'
ORDER BY food_name;
```

---

## Notes

**Nutrition Module Uniqueness:**
- First primarily educational module (not activity-tracking)
- Content library with recommendation system
- Optional food diary (not required)
- No time slider needed (educational content, not scheduled activity)
- Focus on content delivery and engagement

**Content Strategy:**
- Seed database with 50-100 tips/articles
- Rotate content to keep fresh
- Track engagement (views, time spent, helpful votes)
- Use engagement data to improve recommendations

**Food Library:**
- Pre-populate with common foods and sleep effects
- Based on research: tryptophan, magnesium, melatonin content
- Categorize by sleep impact

**Food Diary Design:**
- Simple, optional feature
- Not meant to replace full nutrition tracking apps
- Purpose: Quick logging to correlate with sleep
- Can integrate with other apps in future (MyFitnessPal, etc.)

**Notification Strategy:**
- Daily tips delivered at user-specified time
- Can reduce frequency (3 tips/week instead of daily)
- Module-level override for notifications

**Estimated Time:** 10-12 hours
- Database migration with content tables: 45 minutes
- Models (Content + Food + Config): 90 minutes
- Food library seed data: 60 minutes
- Content tips/articles seed data: 90 minutes
- Recommendation service: 90 minutes
- Repository + Datasource: 90 minutes
- ViewModel: 90 minutes
- Content screen: 120 minutes
- Food diary screen (optional): 90 minutes
- Testing: 60 minutes
