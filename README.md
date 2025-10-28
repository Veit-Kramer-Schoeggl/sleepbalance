# SleepBalance

Flutter app for sleep optimization using wearable data.

## What We Built Today

### Project Structure
- Feature-based architecture (`lib/features/`)
- Separate screens for dashboard and questionnaire
- Clean separation of concerns

### Core Features
- **Dashboard**: Displays sleep metrics from wearables
- **Questionnaire**: Initial setup screen
- **First-time routing**: Questionnaire on first launch, dashboard afterwards

### Data Model
- `SleepData` model with sleep phases, heart rate, breathing rate, fragmentation
- JSON serialization for API integration
- Comprehensive test coverage

### Technical Setup
- Material 3 design
- Shared preferences for persistence
- Debug flag for development testing (`FORCE_ONBOARDING`)
- Proper test structure matching feature organization

## Development

```bash
flutter run  # Run the app
flutter test # Run tests
```

**Debug flag**: Set `FORCE_ONBOARDING = true` in `preferences_service.dart` to always show questionnaire.