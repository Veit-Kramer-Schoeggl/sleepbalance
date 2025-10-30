# Settings & User Profile Feature

## Struktur (Clean Architecture + MVVM)

```
settings/
├── data/                    # Data Layer (externe Daten)
│   ├── datasources/        # SQLite, SharedPreferences
│   └── repositories/       # Repository Implementierungen
├── domain/                  # Business Logic Layer (unabhängig)
│   ├── models/             # Domain Models (User)
│   └── repositories/       # Repository Interfaces (abstrakt)
└── presentation/           # UI Layer
    ├── screens/            # Screens (SettingsScreen, UserProfileScreen)
    └── viewmodels/         # ViewModels (SettingsViewModel)
```

## Implementierung

### Phase 4 (Data Layer) - JETZT
Siehe `PHASE_4.md` für:
- Datenbank Migration (migration_v4.dart - users table)
- User Model (user.dart)
- DataSource (user_local_datasource.dart)
- Repository mit SharedPreferences (user_repository_impl.dart)
- Default User Setup
- Provider Registration in main.dart

### UI Layer - SPÄTER (für Kollegen)
Siehe `SETTINGS_IMPLEMENTATION_PLAN.md` für:
- ViewModel (settings_viewmodel.dart)
- Settings Screen Refactoring
- User Profile Editor Screen

## Besonderheiten

- Nutzt **SQLite** für User-Daten (Name, Geburtsdatum, etc.)
- Nutzt **SharedPreferences** für Session (current_user_id)
- Ist Grundlage für alle anderen Features (User-ID)
