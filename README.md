# SleepBalance

A modular sleep optimization app that uses wearable data to provide personalized interventions for better sleep quality.

## Core Concept

SleepBalance helps people fall and stay asleep through data-driven, personalized interventions. The app connects with wearables (primarily watches) to track objective sleep data and provides customizable intervention modules that users can select, combine, and customize based on their preferences and needs.

## Key Features

### Authentication
- ✅ **FR-1 Completed**: User registration with email verification (PBKDF2 password hashing)
- ✅ **FR-2 Completed**: User login with local password verification
- Email verification with 6-digit codes (15-minute expiration)
- Secure password storage using PBKDF2-HMAC-SHA256 (600,000 iterations)
- Local-first authentication (offline-capable, no backend required in Phase 1)
- See [AUTH_DOCUMENTATION.md](documentation/authentication/AUTH_DOCUMENTATION.md) for complete details

### Onboarding Questionnaire
- 3-4 questions on first launch
- Pre-selects appropriate intervention modules
- Personalizes initial recommendations

### Modular Intervention System
- Users can select, combine, and customize individual modules.

### Wearable Integration
- Core feature: sync sleep data from watches
- Objective sleep metrics for improvement tracking
- Data-driven recommendation engine

### Main Navigation
Bottom navigation with 4 tabs (indexed 0-3):
1. **Settings** (index 0): Configure app preferences and modules
2. **Night Review** (index 1): Review previous night's sleep data with date navigation and expandable calendar
3. **Action Center** (index 2, default on launch): Actionable sleep recommendations with checkboxes
4. **Habits Lab** (index 3): Track and experiment with sleep habits

## Architecture

### Overview
- Feature-based architecture with clean separation of concerns
- Clean architecture with domain/data/presentation layers
- Bottom navigation with 4 tabs
- Custom background theming on all screens
- Custom splash screen with moon icon

### Folder Structure

```
lib/
├── core/                          # Core app infrastructure
│   ├── auth/                      # Authentication system (future)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── wearables/                 # ✅ Wearable integration (OAuth + sync)
│   │   ├── data/                  # ✅ Database & API datasources
│   │   │   ├── datasources/       # Local credentials storage
│   │   │   └── repositories/      # Repository implementations
│   │   ├── domain/                # ✅ Business logic & models
│   │   │   ├── enums/            # Provider types, sync status
│   │   │   ├── models/           # Credentials, sync records, sleep data
│   │   │   └── repositories/     # Repository interfaces
│   │   ├── presentation/          # ✅ Connection UI & ViewModels
│   │   │   ├── viewmodels/       # State management
│   │   │   └── screens/          # OAuth flow UI
│   │   ├── utils/                # OAuth configuration
│   │   └── WEARABLES_README.md   # Full documentation
│   │
│   ├── recommendations/           # AI recommendation engine (future)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── database/                  # 📊 SQLite database infrastructure
│   │   ├── database_helper.dart   # Database setup & version management
│   │   ├── migrations/            # Schema migrations (v1, v2, ...)
│   │   └── sync/                  # Local-to-server sync logic (future PostgreSQL)
│   │
│   ├── notifications/             # 🔔 Push notification service
│   │   ├── notification_service.dart      # Wrapper for flutter_local_notifications
│   │   ├── notification_scheduler.dart    # Schedule recurring reminders
│   │   └── notification_handler.dart      # Handle notification taps
│   │
│   └── utils/                     # Core utilities
│       ├── date_formatter.dart    # ✅ Localized date formatting (DE/EN)
│       └── uuid_generator.dart    # UUID generation for local-first IDs
│
├── modules/                       # 🧩 Intervention modules (pluggable)
│   ├── shared/                    # Shared module infrastructure
│   │   ├── data/                  # Base intervention repository implementation
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── module.dart                    # Module definition
│   │   │   │   ├── user_module_config.dart        # User's module settings
│   │   │   │   ├── intervention_activity.dart     # Daily activity record
│   │   │   │   └── module_notification.dart       # Notification config
│   │   │   ├── repositories/
│   │   │   │   └── intervention_repository.dart   # Base repository interface
│   │   │   └── services/
│   │   │       └── module_notification_service.dart
│   │   └── presentation/
│   │       ├── widgets/           # Reusable module UI components
│   │       └── viewmodels/
│   │           └── base_module_viewmodel.dart
│   │
│   ├── light/                     # ☀️ Light exposure module (FIRST IMPLEMENTATION)
│   │   ├── data/                  # Light activity database operations
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── light_activity.dart            # Daily light tracking
│   │   │   │   ├── light_config.dart              # User's light settings
│   │   │   │   └── light_notification_config.dart # Notification preferences
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   │       └── light_notification_scheduler.dart  # Morning/evening reminders
│   │   └── presentation/
│   │       ├── screens/           # Light configuration & activity log
│   │       ├── widgets/           # Light-specific UI components
│   │       └── viewmodels/
│   │
│   ├── sport/                     # Exercise module (future)
│   ├── temperature/               # Temperature exposure (future)
│   ├── nutrition/                 # Sleep-promoting nutrition (future)
│   ├── mealtime/                  # Meal timing optimization (future)
│   ├── sleep_hygiene/             # Bedtime routine (future)
│   ├── meditation/                # Relaxation techniques (future)
│   ├── journaling/                # Progress tracking (future)
│   └── medication/                # Medication tracking (future)
│       └── [Each module follows: data/, domain/, presentation/]
│
├── features/                      # 📱 Main app features (navigation tabs)
│   ├── onboarding/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── screens/questionnaire_screen.dart  # ✅ Implemented
│   │
│   ├── action_center/             # ✅ Action Center (daily tasks)
│   │   ├── data/                  # Action items database operations
│   │   ├── domain/
│   │   │   ├── models/daily_action.dart
│   │   │   └── repositories/action_repository.dart
│   │   └── presentation/
│   │       ├── screens/action_screen.dart         # To be refactored (MVVM)
│   │       └── viewmodels/action_viewmodel.dart
│   │
│   ├── night_review/              # 😴 Sleep review & analysis
│   │   ├── data/                  # Sleep record database operations
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── sleep_record.dart              # Nightly sleep data
│   │   │   │   ├── sleep_baseline.dart            # User's average metrics
│   │   │   │   └── sleep_comparison.dart          # Today vs personal average
│   │   │   ├── repositories/sleep_record_repository.dart
│   │   │   └── services/sleep_analysis_service.dart  # Calculate baselines
│   │   └── presentation/
│   │       ├── screens/night_screen.dart          # ✅ Implemented (to refactor)
│   │       ├── widgets/
│   │       │   ├── sleep_chart.dart
│   │       │   ├── sleep_phase_breakdown.dart
│   │       │   └── quality_rating_widget.dart     # 3-point scale input
│   │       └── viewmodels/night_review_viewmodel.dart
│   │
│   ├── habits_lab/                # 🧪 Habit experimentation
│   │   └── presentation/
│   │       └── screens/habits_screen.dart         # ✅ Implemented
│   │
│   └── settings/                  # ⚙️ Settings & module management
│       ├── data/                  # User profile database operations
│       ├── domain/
│       │   ├── models/user.dart
│       │   └── repositories/user_repository.dart
│       └── presentation/
│           ├── screens/
│           │   ├── settings_screen.dart           # ✅ Implemented (to expand)
│           │   ├── user_profile_screen.dart
│           │   └── module_management_screen.dart  # Enable/disable modules
│           └── viewmodels/settings_viewmodel.dart
│
└── shared/                        # 🔧 Shared utilities & components
    ├── services/
    │   ├── storage/
    │   │   └── preferences_service.dart  # ✅ SharedPreferences wrapper
    │   ├── analytics/             # Usage tracking (future)
    │   └── logging/               # Error logging (future)
    │
    ├── widgets/
    │   ├── ui/                    # ✅ Reusable UI components
    │   │   ├── background_wrapper.dart
    │   │   ├── date_navigation_header.dart
    │   │   ├── expandable_calendar.dart
    │   │   ├── checkbox_button.dart
    │   │   ├── acceptance_button.dart
    │   │   ├── time_picker_field.dart     # For module configuration
    │   │   └── duration_picker_field.dart # For module configuration
    │   └── navigation/
    │       └── main_navigation.dart  # ✅ Bottom tab navigation
    │
    ├── screens/
    │   └── app/
    │       └── splash_screen.dart # ✅ Launch screen with moon icon
    │
    ├── theme/                     # Theme configuration (planned)
    ├── constants/                 # App constants
    │   ├── notification_channels.dart  # Notification channel definitions
    │   └── database_constants.dart     # Table & column name constants
    └── utils/                     # Helper functions
        └── extensions/            # Dart extensions (DateTime, String, etc.)
```

### Architecture Principles

**Separation of Concerns:**
- `core/` - Foundational infrastructure (auth, wearables, database, notifications)
- `modules/` - Pluggable intervention modules (customizable, combinable)
- `features/` - Main app screens/flows (the 4 navigation tabs + onboarding)
- `shared/` - Cross-cutting utilities and reusable components

**Clean Architecture Layers:**
- `data/` - Database operations, external data sources, repository implementations
- `domain/` - Business logic, models, use cases, repository interfaces
- `presentation/` - UI screens, widgets, ViewModels (MVVM pattern)

**State Management:**
- **MVVM + Provider pattern** for reactive UI updates
- ViewModels manage business logic and state
- Screens consume ViewModels via Provider
- Clear data flow: UI → ViewModel → Repository → Database

**Module System:**
- Each intervention module is self-contained with its own data/domain/presentation layers
- Modules share common infrastructure via `modules/shared/`
- Base models: `InterventionActivity`, `UserModuleConfig`, `ModuleNotification`
- Users can enable multiple modules simultaneously and configure each individually
- Easy to add new modules by extending shared base classes

**Data Persistence:**
- **Local-first architecture** with SQLite for offline-capable data storage
- Hybrid schema: typed columns for common attributes + JSON for module-specific data
- Individual user baselines: Calculate personal averages (7-day, 30-day rolling windows)
- Future: PostgreSQL backend sync for cloud backup and multi-device support
- See [DATABASE.md](documentation/database/DATABASE.md) for detailed schema and design decisions

**Notifications:**
- Module-driven push notifications (e.g., Light module: morning reminders, evening dimming alerts)
- Configurable per-user via module settings
- Handled by `core/notifications/` service wrapping `flutter_local_notifications`

**Implementation Status:**
- ✅ **Fully Implemented**: Main navigation, splash screen, onboarding questionnaire (3 questions), night review screen with calendar, action center with checkboxes, shared UI widgets (6 components), date formatter utility, preferences service
- 🚧 **In Progress**: Database schema, MVVM refactoring, Light module (first intervention)
- 📋 **Planned**: Auth system, recommendation engine, remaining 8 intervention modules, PostgreSQL sync

## Assets

- Background image: `assets/images/main_background.png`
- Splash icon: `assets/images/moon_star.png`
- Icon folders: `assets/icons/{app,navigation,features}/`

## How It Works

### Core Components

**Database Layer** (`core/database/`)
- SQLite for local-first data persistence
- Schema migrations for version management
- Sync queue for future PostgreSQL backend integration
- See [DATABASE.md](documentation/database/DATABASE.md) for complete schema details

**Wearable Integration** (`core/wearables/`)
- OAuth 2.0 authentication with sleep tracking devices (Fitbit, Apple Health, Google Fit)
- Secure token storage and automatic refresh for continuous data access
- Fetches nightly sleep data: sleep phases, heart rate, HRV, breathing rate
- Sync history tracking with detailed error logging for troubleshooting
- Clean architecture with domain/data/presentation separation
- [Full documentation](lib/core/wearables/WEARABLES_README.md)

**Notification System** (`core/notifications/`)
- Module-specific reminders scheduled via user configuration
- Example: Light module sends morning light reminder at 7:00 AM, evening dimming alert at 8:00 PM
- Users can enable/disable and customize notification times per module

### Wearables Integration

**Phase 1 - Complete (OAuth & Authentication)**:
The wearables system enables users to connect their sleep tracking devices through industry-standard OAuth 2.0. Users authenticate directly with their wearable provider (Fitbit, Apple Health, etc.) and grant the app permission to access sleep data. Access tokens are stored securely in SQLite with automatic refresh to maintain continuous access.

**Supported Devices**:
- ✅ **Fitbit**: Full OAuth integration with sleep, activity, and heart rate data access
- 📋 **Apple Health**: Planned iOS HealthKit integration
- 📋 **Google Fit**: Planned Android fitness data integration
- 📋 **Garmin**: Planned OAuth connection

**Key Features**:
- Secure token management with automatic refresh before expiration
- Multi-provider support (users can connect multiple devices)
- Connection status tracking (connected since, last sync, token validity)
- Detailed sync history with error logging for troubleshooting
- Test UI for OAuth flow validation (accessible from Habits Lab)

**Architecture**:
The wearables system follows clean architecture with complete separation of concerns across domain (business logic), data (storage & APIs), and presentation (UI) layers. Each layer has clearly defined responsibilities and dependencies flow inward toward the domain. See [lib/core/wearables/WEARABLES_README.md](lib/core/wearables/WEARABLES_README.md) for complete architecture documentation.

**Next Phase (Data Sync)**:
Phase 2 will implement automatic sleep data fetching, transformation to the app's unified format, background sync scheduling, and conflict resolution between manual and wearable data entries.

### Module System

**Shared Infrastructure** (`modules/shared/`)
- Common patterns, base classes, and utilities used across all intervention modules
- Base models: `InterventionActivity`, `UserModuleConfig`, `ModuleInterface`
- Standard vs Advanced mode for all modules with science-based defaults
- [More details](lib/modules/shared/SHARED_README.md)

**Available Modules:**

- **[Light Module](lib/modules/light/LIGHT_README.md)**: Bright light therapy timing and type selection for circadian rhythm optimization. Morning exposure promotes alertness; evening red light supports melatonin production.

- **[Mealtime Module](lib/modules/mealtime/MEALTIME_README.md)**: Eating schedule optimization with visual time slider. Default 3-meal pattern or customizable eating windows for intermittent fasting, automatically adjusted to user's sleep schedule.

- **[Temperature Module](lib/modules/temperature/TEMPERATURE_README.md)**: Cold and heat exposure protocols for sleep enhancement. Morning cold showers boost alertness; evening saunas facilitate sleep onset through subsequent body cooling.

- **[Sport Module](lib/modules/sport/SPORT_README.md)**: Exercise timing and intensity guidance with wearable integration. Morning HIIT for optimal sleep benefit; intensity-based scheduling prevents evening exercise sleep disruption.

- **[Meditation Module](lib/modules/meditation/MEDITATION_README.md)**: Guided relaxation and breathwork library. Evening pre-sleep sessions reduce anxiety and racing thoughts; diverse techniques from multiple teachers and traditions.

- **[Journaling Module](lib/modules/journaling/JOURNALING_README.md)**: Reflective writing with multiple input methods (typing, voice-to-text, handwritten OCR). ML-based pattern recognition identifies factors affecting sleep and provides personalized insights.

- **[Nutrition Module](lib/modules/nutrition/NUTRITION_README.md)**: Evidence-based education on sleep-promoting foods and nutrients. Daily tips, comprehensive food database, and personalized recommendations based on dietary preferences.

- **Sleep Hygiene Module** *(planned)*: Comprehensive bedtime routine optimization and sleep environment setup guidance.

- **Medication Module** *(planned)*: Track medication intake timing and correlate with sleep effects for informed health discussions.

**[Shared Module Infrastructure](lib/modules/shared/SHARED_README.md)**: Common patterns, base classes, and utilities used across all intervention modules.

### Feature Screens

**Action Center** (`features/action_center/`)
- Displays daily recommended actions from enabled modules
- Checkbox-based completion tracking
- Data persists to database for correlation analysis
- Uses MVVM: ActionViewModel manages state, ActionRepository handles database

**Night Review** (`features/night_review/`)
- Shows previous night's sleep data from wearables
- Displays sleep phases breakdown (deep, REM, light, awake)
- User provides subjective quality rating (bad/average/good scale)
- Compares today's sleep to personal baseline: "Your 7-day average deep sleep: 85 min. Tonight: 95 min (+10!)"
- Date navigation with expandable calendar for historical review

**Habits Lab** (`features/habits_lab/`)
- Future: Experiment with module combinations
- Track correlations between interventions and sleep improvements
- Visualize which interventions work best for the individual user

**Settings** (`features/settings/`)
- User profile management (name, birth date, sleep goals)
- Module management: Enable/disable interventions, configure each module
- Notification preferences, timezone settings

### Data Flow Example (Light Module)

```
1. User Action: Completes morning light therapy
   ↓
2. UI: LightActivityLogScreen
   ↓
3. ViewModel: LightModuleViewModel.logActivity()
   ↓
4. Repository: LightModuleRepository.saveActivity()
   ↓
5. Database: INSERT into intervention_activities
   ↓
6. Analysis: Later correlate with tonight's sleep data
   ↓
7. Insights: "You slept 20 min longer on days with morning light exposure"
```

### Correlation & Analysis (to be implemented later)

**Individual Baselines:**
- System calculates user's personal averages (7-day, 30-day rolling windows)
- Metrics: average deep sleep, total sleep time, sleep efficiency, etc.
- Stored in `user_sleep_baselines` table
- UI shows relative performance: "above your average" or "below your average"

**Intervention Correlation:**
- Query: Get all interventions on Day N, join with sleep record for Night N→N+1
- Analyze: Does light therapy on Day N improve deep sleep on Night N?
- Multi-module: Compare sleep quality when using Light+Sport vs Light alone
- Time-range analysis: Last 7 days, last 30 days, or custom date ranges

## Development

### Setup

```bash
flutter pub get  # Install dependencies
flutter run      # Run the app
flutter test     # Run tests
```

### Dependencies

```yaml
# State Management
provider: ^6.1.1

# Local Database
sqflite: ^2.3.0
path_provider: ^2.1.1
path: ^1.8.3

# Notifications
flutter_local_notifications: ^17.0.0
timezone: ^0.9.2

# UUID generation (local-first IDs)
uuid: ^4.2.0

# JSON Serialization
json_annotation: ^4.8.1

# Dev dependencies
build_runner: ^2.4.6
json_serializable: ^6.7.1
```

### Debug Flags

- Set `FORCE_ONBOARDING = true` in `preferences_service.dart` to always show questionnaire

### Documentation

- [AUTH_DOCUMENTATION.md](documentation/authentication/AUTH_DOCUMENTATION.md) - Complete authentication system documentation with flow diagrams, security details, and implementation guide
- [DATABASE.md](documentation/database/DATABASE.md) - Complete database schema, design decisions, and migration strategy
