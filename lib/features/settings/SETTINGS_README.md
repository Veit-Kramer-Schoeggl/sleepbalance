# Settings & User Profile Feature

## Struktur (Clean Architecture + MVVM)

```
settings/
├── data/                    # Data Layer (externe Daten)
│   ├── datasources/        # SQLite, SharedPreferences
│   │   └── user_local_datasource.dart ✅ FERTIG
│   └── repositories/       # Repository Implementierungen
│       └── user_repository_impl.dart ✅ FERTIG
├── domain/                  # Business Logic Layer (unabhängig)
│   ├── models/             # Domain Models (User)
│   │   ├── user.dart ✅ FERTIG
│   │   └── user.g.dart ✅ FERTIG (auto-generated)
│   └── repositories/       # Repository Interfaces (abstrakt)
│       └── user_repository.dart ✅ FERTIG
└── presentation/           # UI Layer
    ├── screens/            # Screens (SettingsScreen, UserProfileScreen)
    └── viewmodels/         # ViewModels (SettingsViewModel)
```

## Status

### ✅ Phase 4 abgeschlossen (Data Layer)

**Implementierte Dateien:**
- `lib/core/database/migrations/migration_v4.dart` - Users Tabelle
- `domain/models/user.dart` - User Model mit allen Feldern
- `domain/repositories/user_repository.dart` - Repository Interface
- `data/datasources/user_local_datasource.dart` - SQLite Operationen
- `data/repositories/user_repository_impl.dart` - Implementierung mit SharedPreferences

**Datenbank:**
- Migration V4 erstellt users Tabelle
- Default User automatisch beim ersten Start angelegt
- User-ID in SharedPreferences unter 'current_user_id'

**Provider Registration:**
- SharedPreferences Provider in main.dart
- UserLocalDataSource Provider in main.dart
- UserRepository Provider in main.dart

### ⏳ UI Layer - Noch zu implementieren

Siehe `SETTINGS_IMPLEMENTATION_PLAN.md` für:
- SettingsViewModel (State Management)
- SettingsScreen (User-Info + Einstellungen)
- UserProfileScreen (Vollständiger Editor)

## User Model

**17 Felder:**
- `id`, `email`, `passwordHash` (optional)
- `firstName`, `lastName`, `birthDate`
- `timezone`, `targetSleepDuration`, `targetBedTime`, `targetWakeTime`
- `hasSleepDisorder`, `sleepDisorderType`, `takesSleepMedication`
- `preferredUnitSystem`, `language`
- `createdAt`, `updatedAt`

**Methoden:**
- `fromDatabase()` / `toDatabase()` - SQLite Konvertierung
- `fromJson()` / `toJson()` - API Konvertierung (zukünftig)
- `copyWith()` - Immutable Updates
- Getter: `fullName`, `age`

**Wichtig:**
- DateTime wird als ISO 8601 String in DB gespeichert
- Boolean wird als INTEGER (0/1) in DB gespeichert
- Nutzt DatabaseDateUtils für Konvertierung
- Nutzt DatabaseConstants für alle Spaltennamen

## Repository Methoden (verfügbar)

**User-Verwaltung:**
```dart
Future<User?> getUserById(String userId)
Future<User?> getUserByEmail(String email)
Future<void> saveUser(User user)           // Upsert (insert oder update)
Future<void> updateUser(User user)
Future<void> deleteUser(String userId)     // Soft delete
Future<List<User>> getAllUsers()
```

**Session-Management (SharedPreferences):**
```dart
Future<String?> getCurrentUserId()         // Liest 'current_user_id'
Future<void> setCurrentUserId(String userId)
```

**Beispiel-Nutzung:**
```dart
// Repository holen
final repo = context.read<UserRepository>();

// Aktuellen User laden
final userId = await repo.getCurrentUserId();
if (userId != null) {
  final user = await repo.getUserById(userId);
}

// User aktualisieren
final updatedUser = user.copyWith(
  firstName: 'Max',
  updatedAt: DateTime.now(),
);
await repo.updateUser(updatedUser);
```

## Default User

**Automatisch angelegt beim ersten Start:**
- Email: "default@sleepbalance.app"
- Name: "Sleep User"
- Geburtsdatum: 1990-01-01
- Schlafziel: 480 Minuten (8 Stunden)
- Timezone: UTC
- Sprache: Englisch (en)
- Einheiten: Metrisch

**Zweck:**
- App funktioniert sofort ohne Login
- Action Center und Night Review haben User-ID
- Wird später durch echtes Login ersetzt

## Besonderheiten

### Zwei Datenspeicher

**SQLite Datenbank** (user_local_datasource.dart):
- Speichert alle User-Daten (Profil, Einstellungen)
- Dauerhaft gespeichert
- Komplexe Queries möglich
- Soft-Delete Support

**SharedPreferences** (user_repository_impl.dart):
- Speichert nur aktuelle User-ID
- Sehr schneller Zugriff
- Session-Management
- Key: 'current_user_id'

### Integration mit anderen Features

**Action Center:**
```dart
// Alt: Hardcoded
viewModel.loadActions('user123', date);

// Neu: Dynamisch (nach Settings UI)
final userId = context.read<SettingsViewModel>().currentUser?.id;
if (userId != null) {
  viewModel.loadActions(userId, date);
}
```

**Night Review:**
```dart
// Gleiche Pattern
final userId = context.read<SettingsViewModel>().currentUser?.id;
if (userId != null) {
  viewModel.loadSleepRecord(userId, date);
}
```

## Nächste Schritte

**1. UI Layer implementieren (siehe SETTINGS_IMPLEMENTATION_PLAN.md):**
- [ ] SettingsViewModel erstellen
- [ ] SettingsViewModel in main.dart registrieren
- [ ] SettingsScreen mit User-Info erstellen
- [ ] UserProfileScreen mit Formular erstellen
- [ ] Hardcoded User-IDs in anderen Features ersetzen

**2. Später erweitern:**
- [ ] Login/Registrierung implementieren
- [ ] Passwort-Reset Funktion
- [ ] Multi-User Support (mehrere User auf einem Gerät)
- [ ] Backend-Sync (Remote API)

## Dokumentation

- **PHASE_4.md** - Technische Details zur Daten-Schicht
- **SETTINGS_IMPLEMENTATION_PLAN.md** - Schritt-für-Schritt Anleitung für UI
- **PHASE_5.md** - App-weite User-Verdrahtung

## Wichtige Dateien außerhalb dieses Features

**Database:**
- `lib/core/database/migrations/migration_v4.dart`
- `lib/core/database/database_helper.dart` (_createDefaultUser Methode)

**Constants:**
- `lib/shared/constants/database_constants.dart` (User table/column names)

**Utils:**
- `lib/core/utils/database_date_utils.dart` (DateTime Konvertierung)
- `lib/core/utils/uuid_generator.dart` (User-ID Generierung)
