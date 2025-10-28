# SleepBalance

A modular sleep optimization app that uses wearable data to provide personalized interventions for better sleep quality.

## Core Concept

SleepBalance helps people fall and stay asleep through data-driven, personalized interventions. The app connects with wearables (primarily watches) to track objective sleep data and provides customizable intervention modules that users can select, combine, and customize based on their preferences and needs.

## Key Features

### Authentication
- Placeholder implementation (skipped during initial development)
- Basic auth flow for future integration

### Onboarding Questionnaire
- 3-4 questions on first launch
- Pre-selects appropriate intervention modules
- Personalizes initial recommendations

### Modular Intervention System
Users can select, combine, and customize individual modules:
- **Light Module**: Morning/evening light exposure settings
- **Sport Module**: Morning movement and exercise routines
- **Temperature Module**: Sauna, heat and cold exposure protocols
- **Nutrition Module**: Information about sleep-promoting foods
- **Meal-time Module**: Eating schedule optimization (when to eat/avoid eating)
- **Sleep Hygiene Module**: Bedtime routine optimization
- **Meditation Module**: Calming and relaxation techniques
- **Journaling Module**: Progress tracking and reflection exercises
- **Medication Module**: Track medication intake and effects on sleep

### Wearable Integration
- Core feature: sync sleep data from watches
- Objective sleep metrics for improvement tracking
- Data-driven recommendation engine

### Main Navigation
- **Action Center** (default tab): Actionable sleep recommendations
- **Night Review**: Review previous night's sleep data
- **Habits Lab**: Track and experiment with sleep habits
- **Settings**: Configure app preferences and modules

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
│   ├── auth/                      # Authentication system
│   │   ├── data/                  # Auth data sources & repositories
│   │   ├── domain/                # Auth models, interfaces & use cases
│   │   └── presentation/          # Login/signup screens & widgets
│   │
│   ├── wearables/                 # Wearable integration (CRITICAL)
│   │   ├── data/                  # Wearable data sources & repositories
│   │   ├── domain/                # Sleep data models & services
│   │   └── presentation/          # Wearable connection & sync UI
│   │
│   └── recommendations/           # Recommendation engine
│       ├── data/                  # Recommendation data repositories
│       ├── domain/                # Analysis algorithms & use cases
│       └── presentation/          # Recommendation widgets
│
├── modules/                       # Intervention modules (pluggable)
│   ├── shared/                    # Shared module infrastructure
│   │   ├── domain/                # Base module models & interfaces
│   │   └── presentation/          # Common module widgets
│   │
│   ├── light/                     # Light exposure module
│   ├── sport/                     # Exercise & movement module
│   ├── temperature/               # Temperature exposure module
│   ├── nutrition/                 # Sleep-promoting nutrition module
│   ├── mealtime/                  # Meal timing module
│   ├── sleep_hygiene/             # Bedtime routine module
│   ├── meditation/                # Meditation & relaxation module
│   ├── journaling/                # Journaling & tracking module
│   └── medication/                # Medication tracking module
│       └── [Each module: data/, domain/, presentation/]
│
├── features/                      # Main app features (navigation tabs)
│   ├── onboarding/                # First-time setup questionnaire
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── action_center/             # Action tab (recommendations)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── night_review/              # Night tab (sleep review)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── habits_lab/                # Habits tab (experimentation)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── settings/                  # Settings tab
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── shared/                        # Shared utilities & components
    ├── services/                  # Cross-cutting services
    │   └── storage/               # Persistent storage services
    ├── widgets/                   # Reusable widgets
    │   ├── ui/                    # UI components (backgrounds, etc.)
    │   └── navigation/            # Navigation components
    ├── screens/                   # Shared screens
    │   └── app/                   # App-level screens (splash, etc.)
    ├── theme/                     # Theme configuration
    ├── constants/                 # App constants
    └── utils/                     # Helper functions
```

### Architecture Principles

**Separation of Concerns:**
- `core/` - Foundational infrastructure (auth, wearables, recommendations)
- `modules/` - Pluggable intervention modules (customizable, combinable)
- `features/` - Main app screens/flows (the 4 navigation tabs + onboarding)
- `shared/` - Cross-cutting utilities and reusable components

**Clean Architecture Layers:**
- `data/` - External data sources, API clients, repository implementations
- `domain/` - Business logic, models, use cases, repository interfaces
- `presentation/` - UI screens, widgets, and view logic

**Module System:**
- Each intervention module is self-contained
- Modules share common infrastructure via `modules/shared/`
- Users can select, combine, and customize individual modules
- Easy to add new modules without affecting existing code

## Assets

- Background image: `assets/images/main_background.png`
- Splash icon: `assets/images/moon_star.png`
- Icon folders: `assets/icons/{app,navigation,features}/`

## Data Model

- `SleepData` model with sleep phases, heart rate, breathing rate, fragmentation
- JSON serialization for API integration
- Comprehensive test coverage

## Development

```bash
flutter run  # Run the app
flutter test # Run tests
```

**Debug flag**: Set `FORCE_ONBOARDING = true` in `preferences_service.dart` to always show questionnaire.