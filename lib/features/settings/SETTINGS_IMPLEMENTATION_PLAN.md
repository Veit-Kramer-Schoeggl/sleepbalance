# Settings & User Profile MVVM Implementierungsplan

## ⚠️ WICHTIG: Daten-Layer UND ViewModel sind bereits fertig!

**Phase 4 & Phase 5 sind abgeschlossen** - Die komplette Daten-Schicht (Data Layer) UND das ViewModel sind bereits implementiert:

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

✅ **Fertig implementiert (in Phase 5):**
- `SettingsViewModel` - Verwaltet User-Zustand und Einstellungen (BEREITS FERTIG!)
  - Methoden: `loadCurrentUser()`, `updateUserProfile()`, `updateLanguage()`, `updateUnitSystem()`, `logout()`
  - Provider-Registrierung in `main.dart`
  - Wird bereits von SplashScreen und ActionScreen genutzt

📋 **Was du implementierst (UI Layer ONLY):**
- `SettingsScreen` - Übersicht mit User-Info und Einstellungen
- `UserProfileScreen` - Vollständiger Editor für alle User-Felder
- UI-Verbindungen zum fertigen SettingsViewModel

**Du musst KEINE Datenbank-Operationen, Models oder ViewModels erstellen!** Die komplette Infrastruktur existiert bereits und ist getestet.

## Was du bauen wirst

Die Settings-Funktion zeigt dem Benutzer sein Profil und Einstellungen. Der Benutzer kann:
- **Sein Profil sehen** (Name, Email, Profilbild-Initial)
- **Seine Einstellungen ändern** (Sprache, Einheiten, Schlafziel)
- **Sein vollständiges Profil bearbeiten** (Navigation zu Editor-Screen)
- **Ausloggen** (später: zu Login navigieren)

**Wichtig:** Diese Implementierung folgt EXAKT dem gleichen Muster wie Action Center und Night Review. Du kannst beide als Referenz verwenden!

## Voraussetzungen

- ✅ **Phase 4 (Settings Data Layer) abgeschlossen** - Repository und Models sind fertig!
- ✅ **Phase 5 (SettingsViewModel) abgeschlossen** - ViewModel ist fertig und registriert!
- ✅ Phase 2 & 3 (Action Center, Night Review) abgeschlossen - wir folgen dem gleichen Muster!
- ✅ Du verstehst das MVVM-Muster aus den vorherigen Features
- ✅ Du weißt, dass Repositories UND ViewModel bereits in `main.dart` registriert sind

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
    SettingsScreen (View) ← DU IMPLEMENTIERST DIES
         ↓ nutzt
    Consumer<SettingsViewModel>
         ↓ fragt
    SettingsViewModel ✅ FERTIG (Phase 5)
         ↓ lädt User-ID von
    UserRepository.getCurrentUserId() ✅ FERTIG (Phase 4)
         ↓ liest aus
    SharedPreferences ('current_user_id') ✅ FERTIG (Phase 4)
         ↓ dann
    UserRepository.getUserById(userId) ✅ FERTIG (Phase 4)
         ↓ liest aus
    SQLite Datenbank (users Tabelle) ✅ FERTIG (Phase 4)
         ↓ gibt zurück
    User Objekt ✅ FERTIG (Phase 4)
         ↓ angezeigt in
    SettingsScreen ← DU IMPLEMENTIERST DIES

Benutzer bearbeitet Profil:
    UserProfileScreen ← DU IMPLEMENTIERST DIES
         ↓ sendet Änderungen
    SettingsViewModel.updateUserProfile(updatedUser) ✅ FERTIG (Phase 5)
         ↓ speichert in
    UserRepository.updateUser(user) ✅ FERTIG (Phase 4)
         ↓ schreibt in
    SQLite Datenbank ✅ FERTIG (Phase 4)
         ↓ notifyListeners()
    Settings Screen aktualisiert sich automatisch!
```

## Schritt-für-Schritt Implementierung

### ✅ Schritt 1 & 2: ViewModel bereits fertig! (Phase 5)

**Das SettingsViewModel ist bereits vollständig implementiert:**

**Datei:** `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart`

**Bereits vorhanden:**
- ✅ Alle Felder: `_repository`, `_currentUser`, `_isLoading`, `_errorMessage`
- ✅ Alle Methoden:
  - `loadCurrentUser()` - Lädt aktuellen User
  - `updateUserProfile(updatedUser)` - Speichert User-Änderungen
  - `updateLanguage(language)` - Ändert nur Sprache
  - `updateUnitSystem(unitSystem)` - Ändert nur Einheiten
  - `updateSleepTargets()` - Ändert Schlafziele
  - `logout()` - Loggt User aus
  - `clearError()` - Löscht Fehlermeldung
- ✅ Alle Getter: `currentUser`, `isLoading`, `errorMessage`, `isLoggedIn`
- ✅ Komplette Fehlerbehandlung mit try-catch-finally
- ✅ Provider bereits in `main.dart` registriert

**Du musst nichts am ViewModel ändern!** Es ist fertig und wird bereits von SplashScreen und ActionScreen genutzt.

**Wenn du verstehen willst, wie es funktioniert:**
- Öffne die Datei: `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart`
- Vergleiche mit `ActionViewModel` - sehr ähnliche Struktur!
- Siehe auch: Action Center Screen als Referenz für Consumer-Usage

### Schritt 3: Settings Screen erstellen (DU MACHST DIES!)

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

  // OPTIONAL: User erneut laden
  // Normalerweise ist der User bereits von SplashScreen geladen!
  // Nur nötig, wenn User sich ausgeloggt hat
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final viewModel = context.read<SettingsViewModel>();
    if (viewModel.currentUser == null) {
      viewModel.loadCurrentUser();
    }
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

### Schritt 4: User Profile Screen erstellen (DU MACHST DIES!)

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

### Schritt 5: Hardcoded User-IDs ersetzen (Optional - später)

**✅ Bereits erledigt in Phase 5:**
- SplashScreen lädt User beim App-Start
- ActionScreen nutzt `SettingsViewModel.currentUser?.id`
- User ist app-weit verfügbar

**Für Night Review und Habits Lab (wenn du sie implementierst):**

```dart
// Nutze die echte User-ID:
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

**✅ Gut zu wissen: Repository UND ViewModel bereits fertig!**
- UserRepository ist bereits in main.dart registriert (Phase 4)
- SettingsViewModel ist bereits in main.dart registriert (Phase 5)
- Du musst KEINE Provider mehr registrieren!
- Alle Repository-Methoden existieren schon!
- Alle ViewModel-Methoden existieren schon!

**❌ Fehler 1: ViewModel nicht gefunden (sollte nicht passieren)**
- Symptom: "Could not find SettingsViewModel"
- Lösung: Prüfe ob Phase 5 korrekt abgeschlossen wurde
- SettingsViewModel sollte bereits in main.dart registriert sein!

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

- **Vergleiche mit Action Center:** Identisches Consumer-Pattern für ViewModel-Nutzung!
- **Prüfe SettingsViewModel:** `settings_viewmodel.dart` zeigt alle verfügbaren Methoden
- **Prüfe PHASE_4.md:** Technische Details zur Daten-Schicht
- **Prüfe PHASE_5.md:** Details zum SettingsViewModel und App-Integration
- **Prüfe User Model:** `user.dart` zeigt alle verfügbaren Felder (fullName, age, etc.)
- **Form-Validierung:** Standard Flutter Pattern

## Was haben wir erreicht?

Nach dieser Implementierung hast du:

✅ Settings Screen mit User-Übersicht (NEU!)
✅ User Profile Screen mit vollständigem Editor (NEU!)
✅ Vollständiges Verständnis von MVVM und Provider!
✅ Praktische Erfahrung mit Consumer und ViewModel-Nutzung!

**Kombiniert mit Phase 4 & 5 (bereits fertig):**

✅ User-Management mit Datenbank + SharedPreferences
✅ SettingsViewModel mit User-State-Management
✅ Session-Management (eingeloggt bleiben)
✅ Default User beim ersten Start
✅ App-weite User-Verfügbarkeit (SplashScreen, ActionScreen)
✅ Grundlage für späteres Login/Registrierung

**Jetzt haben alle Features Zugriff auf den ECHTEN User UND eine UI zum Bearbeiten!**

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

### ✅ Bereits in Phase 5 implementiert (FERTIG!):

**ViewModel & App Integration:**
- ✅ `SettingsViewModel` komplett fertig
  - ✅ State-Management (currentUser, isLoading, errorMessage)
  - ✅ User laden via Repository (`loadCurrentUser()`)
  - ✅ User aktualisieren (`updateUserProfile()`)
  - ✅ Convenience-Methoden (`updateLanguage()`, `updateUnitSystem()`, `updateSleepTargets()`)
  - ✅ Logout (`logout()`)
  - ✅ Fehlerbehandlung komplett
- ✅ ChangeNotifierProvider in main.dart registriert
- ✅ SplashScreen lädt User beim App-Start
- ✅ ActionScreen nutzt currentUser?.id

### 📋 Was DU noch implementieren musst (UI Layer ONLY):

**Presentation Layer - Screens:**
- ❌ `SettingsScreen` erstellen
  - User-Info Anzeige (Name, Email, Avatar)
  - Einstellungen-Liste (Schlafziel, Sprache, Einheiten)
  - Logout-Button
  - Consumer<SettingsViewModel> für UI-Updates
- ❌ `UserProfileScreen` erstellen
  - Formular mit allen User-Feldern
  - TextFields, DatePicker, Slider, Switches
  - Validierung
  - Speichern via SettingsViewModel.updateUserProfile()

**UI-Verbindungen:**
- ❌ Consumer/watch für automatische Updates
- ❌ Navigation zwischen Settings und Profile
- ❌ Sprach- und Einheiten-Dialoge

**Wichtig:**
- ✅ ViewModel ist FERTIG - du rufst nur dessen Methoden auf!
- ✅ Repository ist FERTIG - ViewModel kümmert sich darum!
- ❌ Du baust NUR die UI-Screens!

## Nächste Schritte

Nach Settings UI:
- **Siehe PHASE_5.md:** App-weite User-Verdrahtung
- Ersetze hardcoded User-IDs in Action Center und Night Review
- Implementiere Habits Lab mit echtem User
- Füge echtes Login hinzu (später)

**Du hast jetzt das Fundament für eine professionelle App! 🚀**
