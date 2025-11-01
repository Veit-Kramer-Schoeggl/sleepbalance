# Settings & User Profile MVVM Implementierungsplan

## ⚠️ WICHTIG: Daten-Layer ist bereits fertig!

**Phase 4 ist abgeschlossen** - Die komplette Daten-Schicht (Data Layer) ist bereits implementiert:

✅ **Fertig implementiert (in Phase 4):**
- Database Migration V4 (`migration_v4.dart`)
- Domain Model: `User` - Mit allen 17 Feldern (id, email, firstName, lastName, birthDate, timezone, targetSleepDuration, etc.)
- Repository Pattern:
  - `UserRepository` (Interface)
  - `UserLocalDataSource` (SQLite Operationen)
  - `UserRepositoryImpl` (Implementierung mit SharedPreferences)
- Default User Creation in `database_helper.dart`
- Provider Registrierung in `main.dart`
- Current User ID Setup in SharedPreferences

📋 **Was du implementierst (UI Layer):**
- `SettingsViewModel` - Verwaltet User-Zustand und Einstellungen
- `SettingsScreen` - Übersicht mit User-Info und Einstellungen
- `UserProfileScreen` - Vollständiger Editor für alle User-Felder
- UI-Verbindungen zu den fertigen Repositories

**Du musst KEINE Datenbank-Operationen oder Models erstellen!** Die Daten-Schicht existiert bereits und ist getestet.

## Was du bauen wirst

Die Settings-Funktion zeigt dem Benutzer sein Profil und Einstellungen. Der Benutzer kann:
- **Sein Profil sehen** (Name, Email, Profilbild-Initial)
- **Seine Einstellungen ändern** (Sprache, Einheiten, Schlafziel)
- **Sein vollständiges Profil bearbeiten** (Navigation zu Editor-Screen)
- **Ausloggen** (später: zu Login navigieren)

**Wichtig:** Diese Implementierung folgt EXAKT dem gleichen Muster wie Action Center und Night Review. Du kannst beide als Referenz verwenden!

## Voraussetzungen

- ✅ **Phase 4 (Settings Data Layer) abgeschlossen** - Repository und Models sind fertig!
- ✅ Phase 2 & 3 (Action Center, Night Review) abgeschlossen - wir folgen dem gleichen Muster!
- ✅ Du verstehst das MVVM-Muster aus den vorherigen Features
- ✅ Du weißt, dass die Repositories bereits in `main.dart` registriert sind

## Das Muster verstehen (Kein Code!)

### Teil 1: Was ist MVVM?

Stell dir vor, du baust ein Restaurant:

- **Model (Datenmodell)** = Die Speisekarte und Zutaten
  - In unserem Fall: `User` (Benutzerdaten) ✅ **BEREITS FERTIG!**
  - Enthält: Name, Email, Geburtsdatum, Schlafziele, etc.
  - Nur Daten, keine Logik!

- **View (Bildschirm)** = Der Gastraum, wo Gäste sitzen
  - In unserem Fall: `SettingsScreen` und `UserProfileScreen` (was der Benutzer sieht)
  - Zeigt Daten an, hat Buttons und Widgets
  - Reagiert auf Benutzer-Eingaben (Tap, Textfeld-Änderungen)

- **ViewModel (Vermittler)** = Der Kellner
  - In unserem Fall: `SettingsViewModel` (das "Gehirn")
  - Holt Daten aus dem Repository (Küche) ✅ **Repository bereits fertig!**
  - Verarbeitet Daten für die View
  - Sagt der View: "Hey, ich habe neue Daten, aktualisiere dich!"

**Warum ist das gut?**
- Der Bildschirm (View) muss nicht wissen, woher die Daten kommen
- Die Daten (Model) müssen nicht wissen, wie sie angezeigt werden
- Das ViewModel verbindet beide und hält sie getrennt
- Einfacher zu testen und zu warten!

### Teil 2: Was ist Provider?

Provider ist wie ein **Lieferservice** in Flutter:

- Du bestellst etwas: `context.read<UserRepository>()`
- Du wartest auf Lieferungen und reagierst sofort: `context.watch<SettingsViewModel>()`
- Wenn neue Daten ankommen, aktualisiert sich die UI automatisch

**Ohne Provider:**
- Du müsstest Objekte durch 5 Ebenen von Widgets durchreichen
- Alptraum-Code mit `widget.repository.dosomething()`

**Mit Provider:**
- Jedes Widget kann sich "einklinken" und Daten holen
- Automatische Updates wenn sich Daten ändern
- Sauberer, lesbarer Code

### Teil 3: Settings vs User Profile Screen

**Zwei Screens, die zusammenarbeiten:**

**1. Settings Screen (Übersicht):**
- User-Info Kachel (Avatar, Name, Email)
- Liste wichtiger Einstellungen (Schlafziel, Sprache, Einheiten)
- Logout-Button
- Tap auf User-Info → Öffnet Profile Editor

**2. User Profile Screen (Editor):**
- Vollständiges Formular mit ALLEN User-Feldern
- TextFields, DatePicker, Dropdowns, Slider
- Validierung (Email gültig? Name nicht leer?)
- Speichern-Button

**Warum zwei Screens?**
- Settings = Schneller Überblick, häufige Aktionen
- Profile = Detaillierte Bearbeitung, selten gebraucht
- Trennung vermeidet überfüllte UI

### Teil 4: Die Settings Architektur

```
Benutzer öffnet Settings
         ↓
    SettingsScreen (View)
         ↓ nutzt
    Consumer<SettingsViewModel>
         ↓ fragt
    SettingsViewModel
         ↓ lädt User-ID von
    UserRepository.getCurrentUserId() ✅ FERTIG
         ↓ liest aus
    SharedPreferences ('current_user_id') ✅ FERTIG
         ↓ dann
    UserRepository.getUserById(userId) ✅ FERTIG
         ↓ liest aus
    SQLite Datenbank (users Tabelle) ✅ FERTIG
         ↓ gibt zurück
    User Objekt ✅ FERTIG
         ↓ angezeigt in
    SettingsScreen

Benutzer bearbeitet Profil:
    UserProfileScreen
         ↓ sendet Änderungen
    SettingsViewModel.updateUserProfile(updatedUser)
         ↓ speichert in
    UserRepository.updateUser(user) ✅ FERTIG
         ↓ schreibt in
    SQLite Datenbank ✅ FERTIG
         ↓ notifyListeners()
    Settings Screen aktualisiert sich automatisch!
```

## Schritt-für-Schritt Implementierung

### Schritt 1: Das ViewModel erstellen

**Was macht ein ViewModel?**

Ein ViewModel ist wie ein **Manager**, der:
1. Den aktuellen Zustand speichert (welcher User, lädt es gerade?)
2. Daten vom Repository holt
3. Der View sagt, wenn sich etwas ändert

**Was benennen wir es:** `SettingsViewModel`

**Wo kommt es hin:** `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart`

**Was braucht es:**

**Felder (Variablen zum Speichern):**
- `_repository`: Verbindung zum Repository - Typ: `UserRepository` ✅ **Existiert bereits!**
- `_currentUser`: Der aktuell eingeloggte User (kann null sein!) - Typ: `User?` ✅ **Model bereits fertig!**
- `_isLoading`: Lädt es gerade? - Typ: `bool`
- `_errorMessage`: Fehlermeldung - Typ: `String?`

**✅ Wichtig:** `User` ist ein fertiges Model aus Phase 4! Du musst es nur importieren:
```dart
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
```

**Methoden (Funktionen):**

1. **`loadCurrentUser()`** - Lädt den aktuell eingeloggten User
   - Setzt `_isLoading = true`
   - Fragt Repository: "Welcher User ist eingeloggt?"
   - Verwendet: `_repository.getCurrentUserId()` ✅ **Fertige Methode!**
   - Wenn User-ID da: Lade User mit `_repository.getUserById(userId)` ✅ **Fertige Methode!**
   - Speichert in `_currentUser`
   - Wenn Fehler: Speichere in `_errorMessage`
   - Setzt `_isLoading = false`, ruft `notifyListeners()`

   **✅ Tipp:** Das Repository ist schon fertig, du musst nur die Methoden aufrufen!

2. **`updateUserProfile(updatedUser)`** - Speichert geänderten User
   - Setzt `_isLoading = true`
   - Ruft Repository: `_repository.updateUser(updatedUser)` ✅ **Fertige Methode!**
   - Aktualisiert `_currentUser = updatedUser`
   - Setzt `_isLoading = false`, ruft `notifyListeners()`

3. **`updateLanguage(language)`** - Schnellmethode: Nur Sprache ändern
   - Erstellt neuen User mit `_currentUser.copyWith(language: language, updatedAt: DateTime.now())` ✅ **copyWith bereits fertig!**
   - Ruft `updateUserProfile()` auf

4. **`updateUnitSystem(unitSystem)`** - Schnellmethode: Nur Einheiten ändern
   - Wie `updateLanguage()`, nur für `preferredUnitSystem` Feld

5. **`logout()`** - Loggt User aus
   - Ruft `_repository.setCurrentUserId('')` (löscht User-ID) ✅ **Fertige Methode!**
   - Setzt `_currentUser = null`
   - Ruft `notifyListeners()`

**Getter:**
- `currentUser` → gibt `_currentUser` zurück
- `isLoading` → gibt `_isLoading` zurück
- `errorMessage` → gibt `_errorMessage` zurück
- `isLoggedIn` → gibt `true` wenn `_currentUser != null`

**WICHTIG - Fehlerbehandlung (wie immer):**
- try-catch-finally in jeder async Methode
- `_isLoading` setzen vor/nach Operationen
- `_errorMessage` bei Fehlern setzen
- `notifyListeners()` im finally Block

**Referenz:** Schau dir `ActionViewModel` oder `NightReviewViewModel` an - identische Struktur!

### Schritt 2: SettingsViewModel in main.dart registrieren

**Wo:** `lib/main.dart` im providers Array (NACH UserRepository)

**Import hinzufügen:**
```dart
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';
```

**Provider hinzufügen:**
```dart
// ============================================================================
// ViewModels
// ============================================================================

// Settings ViewModel
ChangeNotifierProvider<SettingsViewModel>(
  create: (context) => SettingsViewModel(
    repository: context.read<UserRepository>(),
  ),
),
```

**Warum ChangeNotifierProvider?**
- Speziell für ChangeNotifier (ViewModel)
- Automatische Disposal
- Hört auf `notifyListeners()` Aufrufe

**Warum NACH UserRepository?**
- SettingsViewModel braucht UserRepository
- Provider-Reihenfolge ist wichtig!

### Schritt 3: Settings Screen erstellen

**Was benennen wir es:** `SettingsScreen`

**Wo kommt es hin:** `lib/features/settings/presentation/screens/settings_screen.dart`

**Struktur:**

**SettingsScreen (StatefulWidget):**
- Hat `initState()` um User zu laden
- Nutzt `Consumer<SettingsViewModel>` im build

**initState:**
```dart
@override
void initState() {
  super.initState();

  // Lade User beim ersten Öffnen
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<SettingsViewModel>().loadCurrentUser();
  });
}
```

**build Methode:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Einstellungen')),
    body: Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        // Drei Zustände behandeln:

        // 1. Lade-Zustand
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // 2. Fehler-Zustand
        if (viewModel.errorMessage != null) {
          return Center(child: Text('Fehler: ${viewModel.errorMessage}'));
        }

        // 3. Normal-Zustand: Zeige UI
        final user = viewModel.currentUser;

        return ListView(
          children: [
            // User-Info Kachel
            // Einstellungen-Liste
            // Logout-Button
          ],
        );
      },
    ),
  );
}
```

**UI-Inhalt:**

**Oberer Bereich: User-Info Kachel**
- ListTile mit CircleAvatar (zeigt ersten Buchstaben)
- title: `user?.fullName ?? 'Gast'` ✅ **fullName Getter bereits fertig!**
- subtitle: `user?.email ?? 'Nicht eingeloggt'`
- trailing: Edit Icon
- onTap: Navigation zu UserProfileScreen

**Mittlerer Bereich: Einstellungen**
- **Schlafziel ListTile:**
  - Icon: Icons.bedtime
  - subtitle: `'${user?.targetSleepDuration ?? 480} Minuten (${(user?.targetSleepDuration ?? 480) / 60} Stunden)'`

- **Sprache ListTile:**
  - Icon: Icons.language
  - subtitle: `user?.language.toUpperCase() ?? 'EN'`
  - onTap: Öffnet Dialog → ruft `viewModel.updateLanguage('de')` auf

- **Einheiten ListTile:**
  - Icon: Icons.straighten
  - Switch Widget im trailing
  - value: `user?.preferredUnitSystem == 'metric'`
  - onChanged: `viewModel.updateUnitSystem(isMetric ? 'metric' : 'imperial')`

**Unterer Bereich: Logout**
- ListTile in rot
- Icon: Icons.logout
- title: 'Abmelden'
- onTap: `viewModel.logout()`

**Wichtig - Null-Safety:**
- IMMER `user?.feldName` nutzen (mit ?)
- IMMER `??` für Fallback-Werte
- User kann theoretisch null sein!

### Schritt 4: User Profile Screen erstellen

**Was benennen wir es:** `UserProfileScreen`

**Wo kommt es hin:** `lib/features/settings/presentation/screens/user_profile_screen.dart`

**Zweck:** Vollständiges Formular zum Bearbeiten ALLER User-Felder

**Struktur (StatefulWidget):**

**State braucht:**
- `_formKey = GlobalKey<FormState>()` - Für Form-Validierung
- TextEditingController für jedes Textfeld:
  - `_firstNameController`
  - `_lastNameController`
  - `_emailController`
- State-Variablen für andere Felder:
  - `_selectedBirthDate` (DateTime?)
  - `_targetSleepMinutes` (int?)
  - `_hasSleepDisorder` (bool)
  - `_takesSleepMedication` (bool)

**initState:**
```dart
@override
void initState() {
  super.initState();

  final user = context.read<SettingsViewModel>().currentUser;
  if (user != null) {
    // Initialisiere alle Controller mit User-Daten
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _selectedBirthDate = user.birthDate;
    _targetSleepMinutes = user.targetSleepDuration;
    _hasSleepDisorder = user.hasSleepDisorder;
    _takesSleepMedication = user.takesSleepMedication;
  }
}
```

**dispose:**
```dart
@override
void dispose() {
  _firstNameController.dispose();
  _lastNameController.dispose();
  _emailController.dispose();
  super.dispose();
}
```

**build Methode:**

```dart
Scaffold(
  appBar: AppBar(title: Text('Profil bearbeiten')),
  body: Consumer<SettingsViewModel>(
    builder: (context, viewModel, _) {
      if (viewModel.currentUser == null) {
        return Center(child: Text('Kein User geladen'));
      }

      return Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Formular-Felder
            ],
          ),
        ),
      );
    },
  ),
  floatingActionButton: FloatingActionButton(
    child: Icon(Icons.save),
    onPressed: _saveProfile,
  ),
)
```

**Formular-Felder (Beispiele):**

1. **Vorname TextFormField:**
   - controller: `_firstNameController`
   - decoration: InputDecoration mit Icon und Label
   - validator: `(value) => value?.isEmpty ?? true ? 'Darf nicht leer sein' : null`

2. **Nachname TextFormField:**
   - Analog zu Vorname

3. **Email TextFormField:**
   - keyboardType: TextInputType.emailAddress
   - validator: Prüft auf @ und .

4. **Geburtsdatum DatePicker:**
   - InkWell mit InputDecorator
   - Zeigt formatiertes Datum
   - onTap: Öffnet DatePicker, speichert in `_selectedBirthDate`

5. **Schlafziel Slider:**
   - min: 360 (6h), max: 600 (10h), divisions: 24
   - value: `_targetSleepMinutes`
   - onChanged: `setState(() => _targetSleepMinutes = value.round())`

6. **Hat Schlafstörung Switch:**
   - SwitchListTile
   - value: `_hasSleepDisorder`
   - onChanged: `setState(() => _hasSleepDisorder = value)`

**Speichern-Methode:**
```dart
void _saveProfile() {
  if (!_formKey.currentState!.validate()) return;

  final viewModel = context.read<SettingsViewModel>();
  final currentUser = viewModel.currentUser;
  if (currentUser == null) return;

  // Erstelle aktualisierten User mit copyWith
  final updatedUser = currentUser.copyWith(
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    email: _emailController.text,
    birthDate: _selectedBirthDate,
    targetSleepDuration: _targetSleepMinutes,
    hasSleepDisorder: _hasSleepDisorder,
    takesSleepMedication: _takesSleepMedication,
    updatedAt: DateTime.now(), // WICHTIG!
  );

  // Speichere via ViewModel
  viewModel.updateUserProfile(updatedUser);

  // Zeige Bestätigung
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Profil gespeichert!')),
  );

  // Gehe zurück
  Navigator.pop(context);
}
```

**Wichtig:**
- Form MUSS validiert werden vor Speichern
- IMMER `updatedAt: DateTime.now()` setzen!
- copyWith erstellt neue Instanz (User ist immutable)
- Controller MÜSSEN disposed werden

### Schritt 5: Hardcoded User-IDs ersetzen (Optional)

**Nach Settings-Implementierung:**

In Action Center und Night Review kannst du jetzt die echte User-ID nutzen:

```dart
// Alt:
viewModel.loadData('user123');

// Neu:
final userId = context.read<SettingsViewModel>().currentUser?.id;
if (userId != null) {
  viewModel.loadData(userId);
}
```

**Wichtig:** Siehe PHASE_5.md für Details zur app-weiten User-Verdrahtung!

## API Endpoints (TODO - Später ausfüllen)

Aktuell nutzen wir nur lokale SQLite Datenbank + SharedPreferences.

Später mit Backend:
- [ ] Endpoint für User-Login: _________________
- [ ] Endpoint für User-Registrierung: _________________
- [ ] Endpoint für Profil-Update: _________________

## Deine Implementierung testen

### Manuelle Tests (Schritt für Schritt):

1. **Settings Screen öffnen**
   - ✅ Sollte User-Info anzeigen (Name: "Sleep User")
   - ✅ Email: "default@sleepbalance.app"
   - ✅ Kein Crash

2. **User Profile Screen öffnen**
   - Tippe auf User-Info Kachel
   - ✅ Formular öffnet sich
   - ✅ Felder sind vorausgefüllt mit Default-Werten

3. **Profil bearbeiten**
   - Ändere Vorname zu "Max"
   - Ändere Nachname zu "Mustermann"
   - Tippe Speichern
   - ✅ SnackBar: "Profil gespeichert"
   - Gehe zurück zu Settings
   - ✅ Name sollte jetzt "Max Mustermann" sein

4. **App neu starten**
   - Schließe App komplett
   - Öffne wieder
   - ✅ Alle Änderungen sollten erhalten bleiben

5. **Sprache ändern**
   - Tippe auf Sprache in Settings
   - Wähle "Deutsch"
   - ✅ Wird gespeichert (UI-Texte ändern sich noch nicht)

6. **Logout testen**
   - Tippe Logout
   - ✅ currentUser wird null
   - ✅ UI zeigt "Gast" statt Name

7. **Profil-Validierung testen**
   - Öffne User Profile Screen
   - Lösche Vorname
   - Tippe Speichern
   - ✅ Validierungs-Fehler: "Darf nicht leer sein"

### Häufige Fehler vermeiden

**✅ Gut zu wissen: Repository bereits fertig!**
- UserRepository ist bereits in main.dart registriert (Phase 4)
- Du musst nur das ViewModel registrieren
- Alle Repository-Methoden existieren schon!

**❌ Fehler 1: Provider nicht gefunden**
- Symptom: "Could not find SettingsViewModel"
- Lösung: ChangeNotifierProvider in main.dart registrieren
- Wichtig: NACH UserRepository!

**❌ Fehler 2: Null-Check vergessen**
- Symptom: "Null check operator used on null value"
- Lösung: IMMER `user?.firstName` (mit ?) nutzen
- Fallback: `user?.fullName ?? 'Gast'`

**❌ Fehler 3: Form nicht validiert**
- Symptom: Leere Felder werden gespeichert
- Lösung: `if (!_formKey.currentState!.validate()) return;`

**❌ Fehler 4: updatedAt nicht gesetzt**
- Symptom: updatedAt ändert sich nicht
- Lösung: IMMER `updatedAt: DateTime.now()` in copyWith

**❌ Fehler 5: Controller nicht disposed**
- Symptom: Flutter Warning in Console
- Lösung: In dispose(): Jeden Controller disposen!

## Benötigst du Hilfe?

- **Vergleiche mit Action Center:** Gleiche ViewModel-Struktur!
- **Prüfe PHASE_4.md:** Technische Details zur Daten-Schicht
- **Prüfe User Model:** `user.dart` zeigt alle verfügbaren Felder
- **Form-Validierung:** Standard Flutter Pattern

## Was haben wir erreicht?

Nach dieser Implementierung hast du:

✅ SettingsViewModel mit User-State-Management
✅ Settings Screen mit User-Übersicht
✅ User Profile Screen mit vollständigem Editor
✅ Basis für hardcoded User-IDs Ersetzung
✅ Vollständiges Verständnis von MVVM und Provider!

**Kombiniert mit Phase 4:**

✅ User-Management mit Datenbank + SharedPreferences
✅ Session-Management (eingeloggt bleiben)
✅ Default User beim ersten Start
✅ Grundlage für späteres Login/Registrierung

**Jetzt können alle anderen Features den ECHTEN User nutzen!**

## Zusammenfassung: Was ist schon fertig vs. was musst du machen?

### ✅ Bereits in Phase 4 implementiert (FERTIG!):

**Datenbank & Migration:**
- ✅ Migration V4 mit users Tabelle
- ✅ Database version auf 4 aktualisiert
- ✅ Alle DatabaseConstants für User definiert

**Domain Model (komplett fertig):**
- ✅ `User` - Mit allen 17 Feldern
  - ✅ fromDatabase/toDatabase Methoden
  - ✅ fromJson/toJson für API
  - ✅ Getter: `fullName`, `age`
  - ✅ `copyWith()` für Updates

**Repository Pattern (komplett fertig):**
- ✅ `UserRepository` Interface
- ✅ `UserLocalDataSource` - SQLite Operationen
- ✅ `UserRepositoryImpl` - Implementierung mit SharedPreferences
- ✅ Provider in main.dart registriert

**Default User Setup:**
- ✅ Default User wird automatisch angelegt
- ✅ User-ID in SharedPreferences gesetzt

**Fertige Repository-Methoden die du nutzen kannst:**
- ✅ `getCurrentUserId()`
- ✅ `setCurrentUserId(userId)`
- ✅ `getUserById(userId)`
- ✅ `getUserByEmail(email)`
- ✅ `saveUser(user)`
- ✅ `updateUser(user)`
- ✅ `deleteUser(userId)`
- ✅ `getAllUsers()`

### 📋 Was DU noch implementieren musst (UI Layer):

**Presentation Layer:**
- ❌ `SettingsViewModel` erstellen
  - State-Management
  - User laden via Repository
  - User aktualisieren
  - Logout
- ❌ `SettingsScreen` erstellen
  - User-Info Anzeige
  - Einstellungen-Liste
  - Provider-Integration
- ❌ `UserProfileScreen` erstellen
  - Formular mit allen Feldern
  - Validierung
  - Speichern via ViewModel

**UI-Verbindungen:**
- ❌ Consumer/watch für automatische Updates
- ❌ Navigation zwischen Settings und Profile
- ❌ Sprach- und Einheiten-Dialoge

**Wichtig:** Du musst KEINE Datenbank-Queries schreiben! Nutze einfach die fertigen Repository-Methoden.

## Nächste Schritte

Nach Settings UI:
- **Siehe PHASE_5.md:** App-weite User-Verdrahtung
- Ersetze hardcoded User-IDs in Action Center und Night Review
- Implementiere Habits Lab mit echtem User
- Füge echtes Login hinzu (später)

**Du hast jetzt das Fundament für eine professionelle App! 🚀**
