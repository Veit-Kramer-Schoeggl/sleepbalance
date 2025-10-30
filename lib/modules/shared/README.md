# Shared Modules Infrastructure

## Struktur

```
shared/
├── data/                    # Shared Data Layer
│   ├── datasources/        # Intervention DataSource (modul-übergreifend)
│   └── repositories/       # Intervention Repository Implementation
└── domain/                  # Shared Business Logic
    └── repositories/       # Intervention Repository Interface
```

## Zweck

Dieses Verzeichnis enthält **modul-übergreifende** Infrastruktur, die von mehreren Features genutzt wird:

### InterventionRepository
- Liest `intervention_activities` Tabelle
- Queries über ALLE Module hinweg (Light, Sport, Relaxation, etc.)
- Wird genutzt von:
  - **Habits Lab**: Für Statistiken und Historie
  - **Analytics**: Für Korrelationsanalysen (später)
  - **Reports**: Für Export-Funktionen (später)

## Implementierung

Siehe `PHASE_7.md` Step 7.2 für:
- InterventionRepository Interface
- InterventionLocalDataSource
- InterventionRepositoryImpl

## Abgrenzung

**Nicht shared:**
- Modul-spezifische Repositories (z.B. LightRepository)
- Modul-spezifische Models (z.B. LightSession)

**Shared:**
- Allgemeine Aktivitäts-Queries
- Aggregationen über Module hinweg
- Statistik-Berechnungen
