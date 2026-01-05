# Night Review Feature

## Struktur (Clean Architecture + MVVM) **COMPLETED**

```
night_review/
├── data/                    # Data Layer (externe Daten)
│   ├── datasources/        # SQLite, API Calls
│   │   └── sleep_record_local_datasource.dart ✅ FERTIG
│   └── repositories/       # Repository Implementierungen
│       └── sleep_record_repository_impl.dart ✅ FERTIG
├── domain/                  # Business Logic Layer (unabhängig)
│   ├── models/             # Domain Models
│   │   ├── sleep_record.dart ✅ FERTIG
│   │   ├── sleep_record.g.dart ✅ FERTIG (auto-generated)
│   │   ├── sleep_baseline.dart ✅ FERTIG
│   │   ├── sleep_baseline.g.dart ✅ FERTIG (auto-generated)
│   │   └── sleep_comparison.dart ✅ FERTIG
│   └── repositories/       # Repository Interfaces (abstrakt)
│       └── sleep_record_repository.dart ✅ FERTIG
└── presentation/           # UI Layer
    ├── screens/            # Screens (NightScreen)
    ├── viewmodels/         # ViewModels (NightReviewViewModel)
    └── widgets/            # Quality Rating Widget
```

## Status

### ✅ Phase 3 abgeschlossen (Data Layer) **COMPLETED**

**Implementierte Dateien:**
- `lib/core/database/migrations/migration_v3.dart` - Sleep Records + Baselines Tabellen
- `domain/models/sleep_record.dart` - Schlafdaten Model
- `domain/models/sleep_baseline.dart` - Baseline/Durchschnittswerte Model
- `domain/models/sleep_comparison.dart` - DTO für Vergleiche
- `domain/repositories/sleep_record_repository.dart` - Repository Interface
- `data/datasources/sleep_record_local_datasource.dart` - SQLite Operationen
- `data/repositories/sleep_record_repository_impl.dart` - Implementierung

**Datenbank:**
- Migration V3 erstellt sleep_records Tabelle
- Migration V3 erstellt user_sleep_baselines Tabelle
- Indizes für effiziente Queries (date, userId)

**Provider Registration:**
- SleepRecordLocalDataSource Provider in main.dart
- SleepRecordRepository Provider in main.dart

### ⏳ UI Layer - Noch zu implementieren

Siehe `NIGHT_REVIEW_IMPLEMENTATION_PLAN.md` für:
- NightReviewViewModel (State Management)
- NightScreen Refactoring (von StatefulWidget zu StatelessWidget)
- QualityRatingWidget (3-Stufen Bewertung)

## Domain Models **COMPLETED**

### SleepRecord **COMPLETED**

**Schlafmetriken (16 Felder):**
- `id`, `userId`, `date`
- `bedTime`, `wakeTime` - Zeitpunkte
- `totalSleepTime`, `timeInBed` - Dauer
- `sleepEfficiency` - Berechnete Metrik
- `timeToFallAsleep`, `numberOfAwakenings`, `timeAwakeDuringNight`
- `deepSleepDuration`, `lightSleepDuration`, `remSleepDuration`
- `avgHeartRate`, `avgHeartRateVariability`
- `qualityRating`, `notes`
- `createdAt`, `updatedAt`, `syncedAt`

**Methoden:**
- `fromDatabase()` / `toDatabase()` - SQLite Konvertierung
- `fromJson()` / `toJson()` - API Konvertierung (zukünftig)
- `copyWith()` - Immutable Updates
- Getter: `sleepEfficiency` (berechnet: totalSleepTime / timeInBed)

**Wichtig:**
- DateTime wird als ISO 8601 String in DB gespeichert
- Alle Dauern in Minuten gespeichert
- sleepEfficiency als Prozentsatz (0-100)
- Nutzt DatabaseDateUtils für Konvertierung

### SleepBaseline **COMPLETED**

**Durchschnittswerte (11 Felder):**
- `id`, `userId`, `baselineType` ('7_day', '30_day', 'all_time')
- Durchschnittswerte für alle Schlafmetriken:
  - `avgTotalSleepTime`, `avgTimeInBed`, `avgSleepEfficiency`
  - `avgTimeToFallAsleep`, `avgNumberOfAwakenings`
  - `avgDeepSleepDuration`, `avgLightSleepDuration`, `avgRemSleepDuration`
  - `avgHeartRate`, `avgHeartRateVariability`
- `calculatedAt`, `recordCount`

**Methoden:**
- `fromDatabase()` / `toDatabase()` - SQLite Konvertierung
- `fromJson()` / `toJson()` - API Konvertierung
- `copyWith()` - Immutable Updates

**Baseline Types:**
- `7_day` - 7-Tage Durchschnitt
- `30_day` - 30-Tage Durchschnitt
- `all_time` - Gesamter Durchschnitt

### SleepComparison **COMPLETED**

**DTO für Vergleiche (kein DB-Model!):**
- `record` - Aktueller SleepRecord
- `baseline` - Zugehörige Baseline

**Helper-Methoden:**
```dart
bool isAboveAverage(String metricName)
String getDifferenceText(String metricName, {String unit = 'min'})
double getPercentageDifference(String metricName)
```

**Factory:**
```dart
SleepComparison.calculate(SleepRecord record, SleepBaseline baseline)
```

**Verwendung:**
```dart
final comparison = SleepComparison.calculate(record, baseline);
if (comparison.isAboveAverage('avg_deep_sleep')) {
  print('Heute mehr Tiefschlaf als üblich!');
}
```

## Repository Methoden (verfügbar) **COMPLETED**

**Sleep Records:**
```dart
Future<SleepRecord?> getRecordForDate(String userId, DateTime date)
Future<List<SleepRecord>> getRecordsBetween(String userId, DateTime start, DateTime end)
Future<List<SleepRecord>> getRecentRecords(String userId, int days)
Future<void> saveRecord(SleepRecord record)
Future<void> updateQualityRating(String recordId, String rating, String? notes)
```

**Baselines:**
```dart
Future<SleepBaseline?> getBaselines(String userId, String baselineType)
Future<double?> getBaselineValue(String userId, String baselineType, String metricName)
```

**Beispiel-Nutzung:**
```dart
// Repository holen
final repo = context.read<SleepRecordRepository>();

// Schlafdaten für bestimmtes Datum laden
final record = await repo.getRecordForDate(userId, DateTime.now());

// Baseline laden
final baseline = await repo.getBaselines(userId, '7_day');

// Vergleich berechnen
if (record != null && baseline != null) {
  final comparison = SleepComparison.calculate(record, baseline);
  if (comparison.isAboveAverage('avg_deep_sleep')) {
    print('Besser als dein 7-Tage Durchschnitt!');
  }
}

// Quality Rating speichern
await repo.updateQualityRating(record.id, 'good', 'Gut geschlafen!');
```

## Besonderheiten **COMPLETED**

### Berechnete Metriken **COMPLETED**

**Sleep Efficiency (Schlafeffizienz):**
- Formel: `(totalSleepTime / timeInBed) * 100`
- Wird automatisch berechnet im SleepRecord Getter
- Nicht in Datenbank gespeichert
- Typ: double (0-100%)

**Time In Bed (Zeit im Bett):**
- Formel: `wakeTime - bedTime` in Minuten
- Wird automatisch berechnet im SleepRecord Getter
- Nicht in Datenbank gespeichert
- Typ: int (Minuten)

### Baseline Calculation **COMPLETED**

**Automatische Berechnung:**
- Baselines werden periodisch neu berechnet
- Nutzt Aggregate-Queries (AVG) über SleepRecords
- Speichert recordCount (wie viele Records eingeflossen sind)
- calculatedAt Timestamp zeigt wann zuletzt berechnet

**Verwendung in UI:**
- Zeige Vergleich: "25 min mehr Tiefschlaf als üblich"
- Farbcodierung: Grün wenn besser, Rot wenn schlechter
- Prozent-Differenz: "+15% Schlafeffizienz"

### Quality Rating **COMPLETED** (Model only, UI not connected)

**3-Stufen System:**
- `'poor'` - Schlecht geschlafen
- `'average'` - Durchschnittlich geschlafen
- `'good'` - Gut geschlafen

**Subjektive vs. Objektive Daten:**
- Objektiv: Herzfrequenz, Schlafphasen (von Wearable)
- Subjektiv: Quality Rating (vom Benutzer)
- Zusammen: Ganzheitliches Bild

## Integration mit anderen Features

**Action Center:**
- Zeigt "Wie hast du geschlafen?" Karte
- Verlinkt zu Night Review für Details
- Quality Rating kann dort schnell eingetragen werden

**Habits Lab / Interventionen:**
- Korrelations-Analyse: "An Sport-Tagen 15% besserer Schlaf"
- Später: Empfehlungen basierend auf Schlafmustern

**Statistics:**
- Trends über Zeit (7 Tage, 30 Tage, 3 Monate)
- Vergleich mit persönlichen Zielen
- Export für Ärzte/Therapeuten

## Nächste Schritte

**1. UI Layer implementieren (siehe NIGHT_REVIEW_IMPLEMENTATION_PLAN.md):**
- [ ] NightReviewViewModel erstellen
- [ ] NightScreen refactoren (StatefulWidget → StatelessWidget)
- [x] QualityRatingWidget erstellen (UI exists as `_RatingSection`, needs DB connection)
- [x] Kalender-Navigation implementieren (UI exists, needs ViewModel connection)
- [ ] Vergleich mit Baseline in UI anzeigen

**2. Später erweitern:**
- [ ] Wearable Integration (Health Connect, Apple HealthKit)
- [ ] Automatische Baseline-Berechnung (Background Job)
- [ ] Schlafziel-Tracking (Progress zu targetSleepDuration)
- [ ] Export-Funktion (PDF, CSV)
- [ ] Backend-Sync (Remote API)

## Dokumentation

- **PHASE_3.md** - Technische Details zur Daten-Schicht
- **NIGHT_REVIEW_IMPLEMENTATION_PLAN.md** - Schritt-für-Schritt Anleitung für UI

## Wichtige Dateien außerhalb dieses Features

**Database:**
- `lib/core/database/migrations/migration_v3.dart`
- `lib/core/database/database_helper.dart` (_onUpgrade Methode)

**Constants:**
- `lib/shared/constants/database_constants.dart` (Sleep Records table/column names)

**Utils:**
- `lib/core/utils/database_date_utils.dart` (DateTime Konvertierung)

## Beispiel-Datenfluss

**Szenario: Benutzer öffnet Night Review für heute**

1. User tippt auf Night Review Tab
2. NightScreen wird angezeigt (UI Layer)
3. NightReviewViewModel lädt Daten (Presentation Layer):
   ```dart
   await viewModel.loadSleepData(userId)
   ```
4. ViewModel ruft Repository auf (Domain Layer):
   ```dart
   final record = await _repository.getRecordForDate(userId, _currentDate)
   final baseline = await _repository.getBaselines(userId, '7_day')
   ```
5. Repository delegiert zu DataSource (Data Layer):
   ```dart
   final results = await database.query(TABLE_SLEEP_RECORDS, ...)
   return SleepRecord.fromDatabase(results.first)
   ```
6. Daten fließen zurück zu ViewModel
7. ViewModel berechnet Vergleich:
   ```dart
   _comparison = SleepComparison.calculate(record, baseline)
   ```
8. ViewModel ruft `notifyListeners()`
9. UI baut sich neu mit Daten (Consumer)
10. Benutzer sieht: Schlafdaten + Vergleich mit Durchschnitt

**Clean, testbar, wartbar! 🚀**
