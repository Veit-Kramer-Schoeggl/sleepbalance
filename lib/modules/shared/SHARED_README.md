# Shared Module Infrastructure

## Overview
The Shared Module Infrastructure provides common patterns, base classes, utilities, and services used across all intervention modules in SleepBalance. By extracting shared functionality, we ensure consistency, reduce code duplication, and establish a unified user experience across all sleep interventions.

## Core Principle
**Consistency through shared infrastructure.** All intervention modules share fundamental patterns: timing optimization, activity tracking, sleep correlation, and user education. This shared foundation allows users to understand and combine multiple interventions seamlessly while developers can rapidly build new modules following established patterns.

## Common Patterns Across All Modules

### 1. Standard vs Advanced Mode
**Every intervention module offers two configuration levels:**

**Standard Mode (Default)**:
- Science-based default settings that work out of the box
- Single primary session/activity with optimal timing
- Minimal user configuration required
- Simple completion tracking (yes/no)
- Push notification reminders
- Zero learning curve for new users

**Advanced Mode (Customizable)**:
- Full control over all parameters
- Multiple sessions per day
- Custom timing, duration, and intensity
- Different intervention types/methods
- Fine-grained notification control
- Experienced users and optimization enthusiasts

**Benefits**:
- New users get immediate value without complexity
- Advanced users aren't limited by simplification
- Clear upgrade path as users learn and engage

### 2. Visual Time Slider with Color-Coded Guidance
**Used by**: Mealtime, Light, Temperature, Sport modules

**Common Features**:
- Interactive 24-hour timeline visualization
- User's sleep/wake times prominently displayed
- Draggable handles for setting times/windows
- Real-time color-coded feedback as user adjusts timing
- Clear distinction between optimal and suboptimal timing

**Color Scheme Pattern**:
- **Dark Green**: Optimal timing for the intervention
- **Light Green**: Good timing, effective
- **Yellow**: Neutral, no strong benefit or harm
- **Orange**: Suboptimal, less effective or mildly counterproductive
- **Red**: Bad timing, may interfere with sleep
- **Dark Red**: Strongly discouraged, sleep disruption likely

**Color Variations by Intervention Type**:
- Different intervention types (e.g., cold vs heat, morning vs evening light) use adapted color schemes
- Context-sensitive: Same time may be green for one intervention type, red for another

### 3. Module-Level Notification Override
**Every module has independent notification control:**

- Users can enable/disable all notifications for a specific module
- Override works independently of global app notification settings
- Per-session/per-meal notification customization
- Timing preferences (exact time, 15 min before, etc.)
- Permission handling with clear explanations of notification value

**Why This Matters**:
- Users may want reminders for morning exercise but not for meditation
- Allows gradual adoption (start with one module's notifications, expand later)
- Respects user preference for control

### 4. Integration with User's Sleep Schedule
**All modules automatically sync with settings:**

- **Wake Time**: Used by Sport, Light, Temperature, Mealtime for morning timing
- **Bed Time**: Used by Meditation, Journaling, Mealtime, Temperature for evening timing
- **Sleep Goals**: Influence recommendations and target metrics
- **Dynamic Updates**: When user changes sleep schedule, all module recommendations update automatically

**Implementation Pattern**:
- Modules subscribe to Settings changes
- Recalculate optimal timing when wake/bed time changes
- Visual sliders update to reflect new sleep window

### 5. Activity Tracking System
**Every module tracks user adherence:**

**Common Data Points**:
- Completion status (boolean or scale)
- Planned time vs actual time
- Duration (planned vs actual)
- Intervention type/method used
- Optional user notes
- Environmental context (weather, location, etc.)

**Shared Analytics**:
- Consistency metrics (streaks, frequency)
- Adherence percentage
- Time-of-day patterns
- Correlation with sleep quality
- Long-term trend visualization

**Database Storage**:
- `intervention_activities` table (shared across modules)
- Common columns: user_id, module_id, timestamp, completed, duration
- Module-specific data stored in JSON column
- Enables cross-module analysis

### 6. Educational Content Framework
**All modules provide scientific context:**

**Content Types**:
- **Core Principle**: One-sentence explanation of why intervention works
- **Mechanisms**: Physiological/psychological explanation
- **Research References**: Science-backed evidence
- **Personalized Data**: User's own effectiveness metrics
- **Tips & Guidance**: Practical advice for building habits

**Delivery Methods**:
- Inline explanations in configuration screens
- Dedicated info/help sections
- Contextual tooltips
- Quick tips in notifications
- Deep-dive articles in educational library

### 7. Notification Architecture
**Common notification patterns:**

**Notification Types**:
1. **Session Reminders**: Time to perform intervention
2. **Pre-Reminders**: Advance warning (e.g., for preparation)
3. **Completion Prompts**: Did you complete this?
4. **Streak Maintenance**: Motivational consistency reminders
5. **Insight Alerts**: New correlations or patterns discovered
6. **Warning Alerts**: Suboptimal timing attempts (e.g., late exercise)

**Shared Properties**:
- Module-specific notification channels
- User-customizable timing and frequency
- Rich content (images, actions)
- Deep links to relevant screens
- Analytics tracking (delivered, opened, acted upon)

### 8. Session/Activity Configuration Model
**All modules configure interventions with:**

- **Timing**: When to perform (time of day, relative to wake/sleep)
- **Duration**: How long (minutes, hours)
- **Type/Method**: What specific intervention (e.g., cold shower vs ice bath)
- **Intensity/Level**: How intense (high/medium/low or custom scales)
- **Frequency**: How often (daily, specific days, custom pattern)
- **Conditions**: When to skip (weather, health, schedule conflicts)

### 9. Progressive Disclosure Pattern
**Modules guide users from simple to complex:**

**Week 1-2: Establishment**
- Use default settings
- Focus on consistency
- Build basic habit

**Week 3-4: Experimentation**
- Introduce one customization at a time
- Try different intervention types
- Begin tracking subjective response

**Week 5+: Optimization**
- Fine-tune timing based on data
- Combine multiple interventions
- Advanced scheduling

**This pattern appears in**: Sport, Temperature, Meditation, Light modules

### 10. Correlation & Analysis Engine
**All modules feed into sleep quality analysis:**

**Individual Module Analysis**:
- Did intervention improve sleep? (night-by-night)
- Optimal timing for this user (personalized)
- Effectiveness trends over time

**Cross-Module Analysis**:
- Which combination of interventions works best?
- Synergies and conflicts between modules
- Daily intervention load and diminishing returns

**Personal Baseline Comparison**:
- User's 7-day rolling average
- User's 30-day rolling average
- Comparison to general population benchmarks

### 11. Safety & Health Considerations
**Where applicable, modules include:**

- Contraindication warnings (medical conditions)
- Gradual progression guidance
- Duration/intensity limits
- When to consult healthcare professionals
- Emergency information
- Accessibility accommodations

### 12. Use Case Documentation
**Each module documents typical user personas:**

1. **Beginner**: Minimal experience, wants simple guidance
2. **Intermediate**: Some knowledge, ready to customize
3. **Advanced**: Expert optimizer, wants full control
4. **Special Cases**: Shift workers, medical conditions, athletes

## Shared Data Models

### Base Models (All Modules Use)

```
InterventionActivity
├── id: String (UUID)
├── userId: String
├── moduleId: String (light, sport, meditation, etc.)
├── timestamp: DateTime
├── completed: bool
├── plannedTime: DateTime?
├── actualTime: DateTime?
├── plannedDuration: int (minutes)
├── actualDuration: int? (minutes)
├── type: String (module-specific type)
├── intensity: String? (high/medium/low or module scale)
├── notes: String?
├── moduleData: JSON (module-specific fields)
├── createdAt: DateTime
└── updatedAt: DateTime

UserModuleConfig
├── id: String (UUID)
├── userId: String
├── moduleId: String
├── isEnabled: bool
├── mode: String (standard/advanced)
├── notificationsEnabled: bool
├── sessionConfigs: List<SessionConfig>
├── preferences: JSON (module-specific)
├── createdAt: DateTime
└── updatedAt: DateTime

SessionConfig (nested in UserModuleConfig)
├── sessionId: String
├── time: TimeOfDay
├── duration: int (minutes)
├── type: String
├── intensity: String?
├── daysOfWeek: List<int> (0=Monday, 6=Sunday)
├── isEnabled: bool
├── notificationEnabled: bool
└── notificationOffset: int (minutes before/after)

ModuleNotification
├── id: String
├── moduleId: String
├── userId: String
├── sessionId: String?
├── type: String (reminder/completion/insight/warning)
├── scheduledTime: DateTime
├── title: String
├── body: String
├── deepLink: String?
├── delivered: bool
├── opened: bool
└── actionTaken: bool
```

## Shared Repositories

### InterventionRepository (Cross-Module)
**Purpose**: Query intervention activities across ALL modules

**Use Cases**:
- **Habits Lab**: Display statistics and history from all modules
- **Night Review**: Show yesterday's interventions alongside sleep data
- **Analytics**: Cross-module correlation analysis
- **Reports**: Export comprehensive intervention data

**Key Methods**:
- `getActivitiesByDate(userId, date)`: All interventions for a specific day
- `getActivitiesByDateRange(userId, startDate, endDate)`: Date range query
- `getActivitiesByModule(userId, moduleId)`: Module-specific history
- `getCompletionRate(userId, moduleId, dateRange)`: Adherence percentage
- `getStreakData(userId, moduleId)`: Consecutive completion days

### Module-Specific Repositories
**Not shared**: Each module has its own repository for module-specific operations
- LightRepository, SportRepository, MeditationRepository, etc.
- Handle module-specific business logic
- Extend base patterns from shared infrastructure

## Shared Services

### ModuleNotificationService
**Handles notification scheduling across all modules:**

- Schedule recurring notifications
- Reschedule when user changes settings
- Cancel notifications when module disabled
- Track notification delivery and engagement
- Respect global notification preferences while honoring module overrides

### SleepCorrelationService
**Analyzes intervention effectiveness:**

- Calculate correlation between interventions and sleep metrics
- Identify optimal timing for each user
- Detect synergies between modules
- Generate personalized insights
- Update recommendations based on ongoing data

### BaselineCalculationService
**Computes personal averages:**

- 7-day rolling average (recent trend)
- 30-day rolling average (stable baseline)
- Best/worst percentiles
- Variability metrics
- Comparative analysis (intervention days vs non-intervention days)

## Shared UI Components

### Reusable Widgets

**TimeSliderWidget**:
- Visual 24-hour timeline
- Color-coded feedback
- Sleep window overlay
- Draggable time markers
- Used by: Mealtime, Light, Temperature, Sport

**ActivityCalendarWidget**:
- Monthly/weekly calendar view
- Color-coded completion status
- Streak visualization
- Tap to view details
- Used by: All modules

**CompletionCheckboxWidget**:
- Styled checkbox for activity tracking
- Optional time/duration input
- Notes field
- Sync to database
- Used by: All modules

**SessionCardWidget**:
- Display session configuration
- Edit/delete actions
- Enabled/disabled toggle
- Notification settings
- Used by: Advanced mode in all modules

**CorrelationChartWidget**:
- Visualize intervention vs sleep quality
- Line/bar chart options
- Time range selector
- Statistical significance indicator
- Used by: All modules in analytics view

**ProgressRingWidget**:
- Circular progress indicator
- Completion percentage
- Streak counter
- Target vs actual
- Used by: All modules in dashboard

## Shared Utilities

### DateTimeHelpers
- Calculate optimal timing based on wake/sleep times
- Parse and format times for display
- Timezone handling
- Relative time descriptions ("30 min after waking")

### ColorSchemeHelper
- Generate color gradients for time sliders
- Apply different schemes for intervention types
- Accessibility-compliant contrast
- Dark mode support

### ValidationHelpers
- Validate timing configurations
- Check for conflicts between modules
- Warn about suboptimal scheduling
- Safety constraint enforcement

## Implementation Status

**Current State**:
- Basic folder structure established
- Migration planning complete
- Data models designed

**Phase 6 (Light Module)**:
- Will implement first concrete usage of shared infrastructure
- Establish patterns for other modules to follow
- Refine shared components based on real usage

**Future Phases**:
- Each new module implementation will add to shared components
- Continuous refinement of shared patterns
- Gradual extraction of common code

## Benefits of Shared Infrastructure

**For Users**:
- Consistent, predictable interface across all modules
- Learn once, apply everywhere
- Seamless multi-module combinations
- Unified analytics and insights

**For Developers**:
- Rapid new module development
- Less code duplication
- Easier maintenance
- Consistent quality and behavior

**For the App**:
- Smaller app size (code reuse)
- Better performance (optimized shared components)
- Easier testing (test shared components once)
- Scalable architecture (add modules without complexity explosion)

## Design Principles

1. **Convention over Configuration**: Sensible defaults that work for 80% of users
2. **Progressive Enhancement**: Start simple, add complexity as needed
3. **Data-Driven Personalization**: Use user's own data to optimize recommendations
4. **Modular Independence**: Each module can function standalone
5. **Graceful Degradation**: Work without optional dependencies (e.g., wearables)
6. **Privacy First**: Sensitive data (journaling) encrypted and local-first
7. **Science-Backed**: All recommendations based on peer-reviewed research
