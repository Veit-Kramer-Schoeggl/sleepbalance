# Habits Lab Feature

## Struktur (Clean Architecture + MVVM) - **COMPLETED**

```
habits_lab/
├── data/                    # Data Layer (externe Daten)
│   ├── datasources/        # (leer - nutzt shared module)
│   └── repositories/       # (leer - nutzt shared module)
├── domain/                  # Business Logic Layer (unabhängig)
│   ├── models/             # Aggregierte Models (falls nötig)
│   └── repositories/       # (leer - nutzt shared module)
└── presentation/           # UI Layer
    ├── screens/            # Screens (HabitsScreen) ✅
    └── viewmodels/         # ViewModels (HabitsViewModel) ✅
```

## Implementierung

### Phase 7 (Data Layer) - **COMPLETED**
Siehe `PHASE_7.md` für:
- ✅ Shared Intervention Repository (in lib/modules/shared/)
- ✅ Onboarding Question Models
- ✅ Questionnaire Data

### UI Layer - **COMPLETED**
Siehe `HABITS_LAB_IMPLEMENTATION_PLAN.md` für:
- ✅ ViewModel (habits_viewmodel.dart)
- ✅ Screen Implementierung (habits_screen.dart)
- ⏳ Modul-Cards und Statistiken (geplant für später)

## Besonderheiten

- Nutzt **shared/module_config_repository** für Modul-Konfigurationen
- Nutzt **shared/constants/module_metadata** für zentrale Modul-Definitionen
- ViewModel-basiertes State Management mit Provider

## Offene Punkte

Siehe `REPORT.md` für verbleibende Aufgaben (Repository-Fix, Action Center Integration)