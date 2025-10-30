# Night Review Feature

## Struktur (Clean Architecture + MVVM)

```
night_review/
├── data/                    # Data Layer (externe Daten)
│   ├── datasources/        # SQLite, API Calls
│   └── repositories/       # Repository Implementierungen
├── domain/                  # Business Logic Layer (unabhängig)
│   ├── models/             # Domain Models (SleepRecord, SleepBaseline, etc.)
│   └── repositories/       # Repository Interfaces (abstrakt)
└── presentation/           # UI Layer
    ├── screens/            # Screens (StatelessWidgets)
    └── viewmodels/         # ViewModels (ChangeNotifier)
```

## Implementierung

### Phase 3 (Data Layer) - JETZT
Siehe `PHASE_3.md` für:
- Datenbank Migration (migration_v3.dart)
- Domain Models (SleepRecord, SleepBaseline, SleepComparison)
- DataSource (sleep_record_local_datasource.dart)
- Repository (sleep_record_repository_impl.dart)
- Provider Registration in main.dart

### UI Layer - SPÄTER (für Kollegen)
Siehe `NIGHT_REVIEW_IMPLEMENTATION_PLAN.md` für:
- ViewModel (night_review_viewmodel.dart)
- Screen Refactoring (night_screen.dart)
- Quality Rating Widget

## Abhängigkeiten

- Phase 1: DatabaseHelper, DatabaseConstants
- Phase 2: DatabaseDateUtils (für DateTime Konvertierung)
- Provider-Package für Dependency Injection
