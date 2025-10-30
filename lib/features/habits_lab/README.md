# Habits Lab Feature

## Struktur (Clean Architecture + MVVM)

```
habits_lab/
├── data/                    # Data Layer (externe Daten)
│   ├── datasources/        # (leer - nutzt shared module)
│   └── repositories/       # (leer - nutzt shared module)
├── domain/                  # Business Logic Layer (unabhängig)
│   ├── models/             # Aggregierte Models (falls nötig)
│   └── repositories/       # (leer - nutzt shared module)
└── presentation/           # UI Layer
    ├── screens/            # Screens (HabitsScreen)
    └── viewmodels/         # ViewModels (HabitsViewModel)
```

## Implementierung

### Phase 7 (Data Layer) - JETZT
Siehe `PHASE_7.md` für:
- Shared Intervention Repository (in lib/modules/shared/)
- Onboarding Question Models
- Questionnaire Data

### UI Layer - SPÄTER (für Kollegen)
Siehe `HABITS_LAB_IMPLEMENTATION_PLAN.md` für:
- ViewModel (habits_viewmodel.dart)
- Screen Implementierung (habits_screen.dart)
- Modul-Cards und Statistiken

## Besonderheiten

- Nutzt **shared/intervention_repository** für modul-übergreifende Queries
- Zeigt Aktivitäten aus ALLEN Modulen (Light, Sport, etc.)
- Reine Lese-Operationen (keine Creates/Updates)
- Fokus auf Aggregation und Statistiken
