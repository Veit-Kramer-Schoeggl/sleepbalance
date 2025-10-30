# Settings & User Profile MVVM Implementierungsplan

## Was du bauen wirst

Die Settings-Funktion ermöglicht dem Benutzer:
- **Sein Benutzerprofil zu sehen und zu bearbeiten** (Name, Geburtsdatum, Schlafziele)
- **App-Einstellungen zu ändern** (Sprache, Einheiten, Theme)
- **Sein Schlafziel festzulegen** (z.B. 8 Stunden pro Nacht)
- **Gesundheitsinformationen anzugeben** (Schlafstörungen, Medikamente)
- **Zwischen verschiedenen Screens zu navigieren** (Settings → Profil-Editor)

**Wichtig:** Diese Funktion ist das **Fundament für alle anderen Features**, weil sie den User verwaltet. Ohne User keine persönlichen Daten!

**Besonderheit:** Wir nutzen **SharedPreferences** zusätzlich zur Datenbank, um den aktuell eingeloggten User zu speichern.

## Voraussetzungen

- ✅ Phase 1, 2, 3 abgeschlossen (Datenbank, Action Center)
- ✅ Datenbank-Tabelle `users` bereits erstellt (in PHASE_4.md)
- Du musst MVVM noch nicht kennen - wird hier komplett erklärt!

## Das Muster verstehen (Kein Code!)

### Teil 1: Was ist MVVM?

Stell dir vor, du baust ein Restaurant:

- **Model (Datenmodell)** = Die Speisekarte und Zutaten
  - In unserem Fall: `User` (Benutzerdaten)
  - Enthält: Name, Email, Geburtsdatum, Schlafziele, etc.
  - Nur Daten, keine Logik!

- **View (Bildschirm)** = Der Gastraum, wo Gäste sitzen
  - In unserem Fall: `SettingsScreen` und `UserProfileScreen` (was der Benutzer sieht)
  - Zeigt Daten an, hat Buttons und Widgets
  - Reagiert auf Benutzer-Eingaben (Tap, Textfeld-Änderungen, etc.)

- **ViewModel (Vermittler)** = Der Kellner
  - In unserem Fall: `SettingsViewModel` (das "Gehirn")
  - Holt Daten aus dem Repository (Küche)
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

### Teil 3: Was ist SharedPreferences?

Stell dir SharedPreferences wie ein **Notizbuch** vor:

- **Datenbank** = Großes Archiv mit vielen Schränken und Ordnern
  - Speichert: Alle Schlafdaten, Aktionen, Baselines, etc.
  - Dauerhaft gespeichert
  - Komplexe Abfragen möglich

- **SharedPreferences** = Kleines Notizbuch mit wichtigen Zetteln
  - Speichert: "Welcher User ist gerade eingeloggt?"
  - Sehr schnell zugänglich
  - Nur einfache Key-Value Paare (z.B. `current_user_id` = `"abc-123"`)

**Warum nicht alles in der Datenbank?**
- SharedPreferences ist **VIEL schneller** für kleine Daten
- Perfekt für Session-Daten (wer ist eingeloggt?)
- Datenbank ist für große, strukturierte Daten

### Teil 4: Settings vs User Profile Screen

Wir bauen **zwei Screens**, die zusammenarbeiten:

**1. Settings Screen (Übersicht)**
- Zeigt User-Info (Name, Email, Profilbild-Initial)
- Listet alle Einstellungen auf
- Navigation zu User Profile Editor
- Logout-Button

**2. User Profile Screen (Editor)**
- Formular mit allen User-Feldern
- TextFields für Name, Email
- DatePicker für Geburtsdatum
- Dropdowns für Sprache, Timezone, etc.
- Speichern-Button

**Warum zwei Screens?**
- **Settings** = Schnelle Übersicht, ein Tap für häufige Aktionen
- **User Profile** = Detaillierte Bearbeitung, alle Felder auf einmal

### Teil 5: Die Settings Architektur

```
Benutzer öffnet Settings
         ↓
    SettingsScreen
         ↓ nutzt
    Consumer<SettingsViewModel>
         ↓ fragt
    SettingsViewModel
         ↓ holt User-ID von
    UserRepository.getCurrentUserId()
         ↓ liest aus
    SharedPreferences ("current_user_id")
         ↓ dann
    UserRepository.getUserById(userId)
         ↓ liest aus
    SQLite Datenbank (users Tabelle)
         ↓ gibt zurück
    User Objekt
         ↓ angezeigt in
    SettingsScreen

Benutzer bearbeitet Profil:
    UserProfileScreen
         ↓ sendet Änderungen an
    SettingsViewModel.updateUserProfile(updatedUser)
         ↓ speichert in
    UserRepository.updateUser(user)
         ↓ schreibt in
    SQLite Datenbank
         ↓ notifyListeners()
    Settings Screen aktualisiert sich automatisch!
```

## Schritt-für-Schritt Implementierung

### Schritt 1: Das ViewModel erstellen

**Was benennen wir es:** `SettingsViewModel`

**Wo kommt es hin:** `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart`

**Was braucht es:**

**Felder (Variablen zum Speichern):**
- `_repository`: Verbindung zum UserRepository
- `_currentUser`: Der aktuell eingeloggte User (kann null sein!)
- `_isLoading`: Lädt es gerade?
- `_errorMessage`: Fehlermeldung

**Methoden (Funktionen):**

1. **`loadCurrentUser()`** - Lädt den aktuellen User
   - Setzt `_isLoading = true`
   - Fragt Repository: "Welcher User ist eingeloggt?" → gibt User-ID zurück
   - Wenn User-ID existiert: Lade User-Objekt aus Datenbank
   - Speichert in `_currentUser`
   - Bei Fehler: Speichere in `_errorMessage`
   - Setzt `_isLoading = false`, ruft `notifyListeners()`

2. **`updateUserProfile(updatedUser)`** - Aktualisiert User-Daten
   - Sendet neuen User an Repository zum Speichern
   - Setzt `_currentUser` auf den neuen User
   - Ruft `notifyListeners()` → UI aktualisiert sich!

3. **`updateLanguage(language)`** - Ändert Sprache
   - Erstellt aktualisierte Version von `_currentUser` mit neuer Sprache
   - Ruft `updateUserProfile()` auf
   - Später: Triggert App-weiten Sprachwechsel

4. **`updateUnitSystem(unitSystem)`** - Ändert Einheiten (metrisch/imperial)
   - Wie `updateLanguage()`, nur für Einheiten

5. **`logout()`** - Loggt User aus
   - Löscht User-ID aus SharedPreferences
   - Setzt `_currentUser = null`
   - Ruft `notifyListeners()`
   - Später: Navigiert zu Login-Screen

**Getter:**
- `currentUser` → gibt aktuellen User zurück
- `isLoading` → lädt gerade?
- `errorMessage` → gibt Fehler zurück
- `isLoggedIn` → gibt true wenn User existiert

**WICHTIG - Fehlerbehandlung (wie immer):**
- try-catch-finally in jeder async Methode
- `_isLoading` setzen vor/nach Operationen
- `_errorMessage` bei Fehlern setzen
- `notifyListeners()` im finally Block

**Referenz:** Gleiche Struktur wie `ActionViewModel` und `NightReviewViewModel`!

### Schritt 2: Settings Screen mit Provider verbinden

**In `settings_screen.dart`:**

**Aktuell:** Vermutlich ein einfaches StatelessWidget mit Placeholder-Text

**Neu:**
1. Wrappen in `Consumer<SettingsViewModel>`
2. `Consumer` bekommt Zugriff auf ViewModel über `builder`
3. Innerhalb des Builders: UI mit User-Daten aufbauen

**Warum Consumer statt watch?**
- `Consumer` ist gezielter - nur dieser Teil baut sich neu
- `watch` würde das ganze Widget neu bauen
- Beide funktionieren, Consumer ist etwas performanter

**Was zeigt der Settings Screen:**

**Oberer Bereich: User-Info Kachel**
- CircleAvatar mit erstem Buchstaben des Namens
- Name: `viewModel.currentUser?.fullName ?? 'Gast'`
- Email: `viewModel.currentUser?.email ?? 'Nicht eingeloggt'`
- Trailing: Edit Icon
- onTap: Navigiert zu `UserProfileScreen`

**Mittlerer Bereich: Einstellungen-Liste**
- **Schlafziel**
  - Zeigt: `${viewModel.currentUser?.targetSleepDuration ?? 480} Minuten`
  - Trailing: Mond-Icon
  - onTap: Öffnet Dialog zum Ändern

- **Sprache**
  - Zeigt: `viewModel.currentUser?.language?.toUpperCase() ?? 'DE'`
  - Trailing: Sprach-Icon
  - onTap: Zeigt Sprach-Auswahl Dialog

- **Einheiten**
  - Switch zwischen Metrisch/Imperial
  - onChanged: `viewModel.updateUnitSystem(newValue)`

- **Dark Mode** (TODO für später)
  - Switch für Theme
  - Noch nicht implementiert

**Unterer Bereich: Logout**
- Roter ListTile
- onTap: `viewModel.logout()`
- Später: Navigiert zu Onboarding

### Schritt 3: User Profile Screen erstellen

**Was benennen wir es:** `UserProfileScreen`

**Wo kommt es hin:** `lib/features/settings/presentation/screens/user_profile_screen.dart`

**Was ist es:** Ein **Formular zum Bearbeiten** aller User-Daten

**Struktur:**

**Scaffold mit:**
- AppBar: "Profil bearbeiten"
- Body: ScrollView mit Form
- FloatingActionButton: Speichern

**Form-Felder:**

1. **Vorname** - TextFormField
   - Initial: `viewModel.currentUser?.firstName`
   - Validator: Darf nicht leer sein

2. **Nachname** - TextFormField
   - Initial: `viewModel.currentUser?.lastName`
   - Validator: Darf nicht leer sein

3. **Email** - TextFormField
   - Initial: `viewModel.currentUser?.email`
   - Validator: Muss gültige Email sein

4. **Geburtsdatum** - DatePicker (tap öffnet Kalender)
   - Initial: `viewModel.currentUser?.birthDate`
   - Zeigt: formatiertes Datum (z.B. "15.03.1990")

5. **Timezone** - Dropdown
   - Options: Europa/Berlin, Amerika/New_York, etc.
   - Initial: `viewModel.currentUser?.timezone`

6. **Schlafziel** - Slider (6-10 Stunden)
   - Initial: `viewModel.currentUser?.targetSleepDuration`
   - Zeigt: "8.0 Stunden" während Drag

7. **Ziel-Schlafenszeit** - TimePicker
   - Initial: `viewModel.currentUser?.targetBedTime`
   - Zeigt: "22:30"

8. **Ziel-Aufwachzeit** - TimePicker
   - Initial: `viewModel.currentUser?.targetWakeTime`
   - Zeigt: "06:30"

9. **Hast du eine Schlafstörung?** - Switch
   - Initial: `viewModel.currentUser?.hasSleepDisorder`
   - Wenn true: Zeige Dropdown für Typ

10. **Typ der Schlafstörung** - Dropdown (nur wenn Switch an)
    - Options: Insomnie, Schlafapnoe, Restless Legs, etc.

11. **Nimmst du Schlafmedikamente?** - Switch
    - Initial: `viewModel.currentUser?.takesSleepMedication`

12. **Bevorzugte Einheiten** - Dropdown
    - Options: Metrisch, Imperial

13. **Sprache** - Dropdown
    - Options: Deutsch, English

**Speichern-Button Logik:**
1. Validiere Form
2. Wenn gültig: Erstelle aktualisiertes User-Objekt mit `copyWith()`
3. Rufe `viewModel.updateUserProfile(updatedUser)` auf
4. Zeige SnackBar: "Profil gespeichert!"
5. Navigiere zurück zu Settings

**Wenn User null ist:**
- Zeige Lade-Spinner oder Fehler
- Verhindere Formular-Anzeige

### Schritt 4: Repository mit SharedPreferences

**Was ist besonders hier?**

Das `UserRepository` nutzt **ZWEI Datenspeicher**:

1. **SQLite Datenbank** - für User-Daten (Name, Email, Geburtsdatum, etc.)
2. **SharedPreferences** - für Session-Daten (welcher User ist gerade eingeloggt?)

**UserRepositoryImpl Struktur:**

**Konstruktor braucht:**
- `UserLocalDataSource` - für Datenbank-Zugriff
- `SharedPreferences` - für Session-Management

**Zwei Arten von Methoden:**

**Datenbank-Methoden (delegieren an DataSource):**
- `getUserById(userId)` → DataSource fragt Datenbank
- `getUserByEmail(email)` → DataSource fragt Datenbank
- `updateUser(user)` → DataSource schreibt in Datenbank
- `saveUser(user)` → DataSource schreibt in Datenbank
- `getAllUsers()` → DataSource fragt Datenbank

**Session-Methoden (nutzen SharedPreferences direkt):**
- `getCurrentUserId()` → liest `_prefs.getString('current_user_id')`
- `setCurrentUserId(userId)` → schreibt `_prefs.setString('current_user_id', userId)`

**Warum diese Trennung?**
- Session-Daten sind klein und müssen SEHR schnell sein
- User-Daten sind groß und komplex
- SharedPreferences ist synchron und einfach
- Datenbank ist async und strukturiert

### Schritt 5: Standard-User beim App-Start erstellen

**Problem:** Beim ersten App-Start gibt es keine User!

**Lösung:** In `database_helper.dart` einen Default-User anlegen

**Wo:** In der `_onCreate` Methode, nachdem alle Tabellen erstellt wurden

**Was machen wir:**
1. Erstelle einen Standard-User (Map mit allen Feldern)
   - ID: Generiere UUID
   - Email: "default@sleepbalance.app"
   - Name: "Sleep User"
   - Geburtsdatum: "1990-01-01"
   - Schlafziel: 480 Minuten (8 Stunden)
   - Sprache: "de"
   - Einheiten: "metric"

2. Füge User in Datenbank ein: `await db.insert('users', defaultUser)`

3. Speichere User-ID in SharedPreferences:
   ```
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('current_user_id', defaultUser['id']);
   ```

**Wichtig:**
- Nutze `DatabaseDateUtils` für Datum-Konvertierung
- Nutze `UuidGenerator` für ID-Generierung
- Boolean-Werte als INTEGER (0 = false, 1 = true)

**Warum ist das wichtig?**
- App funktioniert sofort nach Installation
- Action Center und Night Review können User-ID nutzen
- Später: Ersetzen durch echtes Login-System

### Schritt 6: Hardcoded User-ID durch echte ersetzen

**Aktuell in Action Center und Night Review:**
```
..loadData('hardcoded-user-id')
```

**Nach Settings-Implementierung:**
```
..loadData(context.read<SettingsViewModel>().currentUser?.id ?? 'fallback-id')
```

**Oder besser:** SettingsViewModel beim App-Start laden, dann:
```
final userId = context.read<SettingsViewModel>().currentUser?.id;
if (userId != null) {
  ..loadData(userId)
}
```

**WICHTIG:** Mache das erst NACH Settings-Implementation, nicht jetzt!

## API Endpoints (TODO - Später ausfüllen)

Aktuell: Nur lokale SQLite Datenbank + SharedPreferences

Später mit Backend-Server:

- [ ] Endpoint für User-Login: _________________
- [ ] Endpoint für User-Registrierung: _________________
- [ ] Endpoint für Profil-Update: _________________
- [ ] Endpoint für Passwort-Reset: _________________

## Deine Implementierung testen

### Manuelle Tests (Schritt für Schritt):

1. **App komplett neu installieren (wichtig!)**
   - Deinstalliere App
   - Installiere neu
   - ✅ Default User sollte automatisch angelegt werden

2. **Settings Screen öffnen**
   - ✅ Sollte User-Info anzeigen (Name: "Sleep User")
   - ✅ Email: "default@sleepbalance.app"
   - ✅ Kein Crash

3. **User Profile Screen öffnen**
   - Tippe auf User-Info Kachel
   - ✅ Formular öffnet sich
   - ✅ Felder sind vorausgefüllt mit Default-Werten

4. **Profil bearbeiten**
   - Ändere Vorname zu "Max"
   - Ändere Nachname zu "Mustermann"
   - Tippe Speichern
   - ✅ SnackBar erscheint: "Profil gespeichert"
   - Gehe zurück zu Settings
   - ✅ Name sollte jetzt "Max Mustermann" sein

5. **Datenbank prüfen**
   - Nutze SQLite Viewer
   - ✅ users Tabelle sollte einen Eintrag haben
   - ✅ first_name sollte "Max" sein

6. **SharedPreferences prüfen**
   - Nutze Device File Explorer
   - ✅ `current_user_id` sollte gesetzt sein

7. **Sprache ändern**
   - Tippe auf Sprache in Settings
   - Wähle "English"
   - ✅ Wird gespeichert (vorerst nur in DB, UI bleibt deutsch)
   - Später: Triggert App-weiten Sprachwechsel

8. **Schlafziel ändern**
   - Verschiebe Slider auf 7.5 Stunden (450 Minuten)
   - Speichere
   - ✅ Settings zeigt neuen Wert an

9. **App neu starten**
   - Schließe App komplett
   - Öffne wieder
   - ✅ User sollte noch eingeloggt sein
   - ✅ Alle Änderungen sollten erhalten bleiben

10. **Logout testen**
    - Tippe Logout
    - ✅ currentUser sollte null werden
    - ✅ UI sollte "Nicht eingeloggt" zeigen
    - Später: Navigiert zu Login/Onboarding

### Häufige Fehler vermeiden

**❌ Fehler 1: SharedPreferences nicht initialisiert**
- Symptom: "Instance of SharedPreferences" Fehler oder null
- Lösung: In main.dart VOR runApp() initialisieren:
  ```
  final prefs = await SharedPreferences.getInstance();
  ```
- Dann an Provider übergeben

**❌ Fehler 2: Provider-Reihenfolge falsch**
- Symptom: "Could not find correct Provider" Fehler
- Lösung: UserLocalDataSource VOR UserRepository registrieren
- SharedPreferences muss VOR UserRepository verfügbar sein

**❌ Fehler 3: Null-Check vergessen**
- Symptom: "Null check operator used on null value"
- Lösung: IMMER prüfen: `viewModel.currentUser?.firstName ?? 'Fallback'`
- User kann null sein (vor Login, nach Logout)

**❌ Fehler 4: Form nicht validiert**
- Symptom: Leere Felder werden gespeichert
- Lösung: `if (_formKey.currentState!.validate())` vor Speichern

**❌ Fehler 5: DateTime/Boolean Konvertierung vergessen**
- Symptom: "type 'String' is not a subtype of type 'DateTime'"
- Lösung: fromDatabase/toDatabase MÜSSEN DatabaseDateUtils nutzen
- Boolean MÜSSEN als INTEGER (0/1) gespeichert werden

**❌ Fehler 6: Default User wird mehrfach angelegt**
- Symptom: Mehrere "Sleep User" in Datenbank
- Lösung: _onCreate wird nur beim ersten Start aufgerufen
- Wenn Fehler: Deinstalliere App komplett und teste neu

## Benötigst du Hilfe?

- **Vergleiche mit Action Center:** Grundstruktur ist gleich!
- **Prüfe PHASE_4.md:** Technische Details und Datenbank-Schema
- **SharedPreferences Beispiel:** In Flutter Docs gut erklärt
- **Form-Validierung:** Standard Flutter Patterns nutzen

## Was haben wir erreicht?

Nach dieser Implementierung hast du:

✅ User-Management mit Datenbank + SharedPreferences
✅ Settings Screen mit User-Übersicht
✅ User Profile Screen mit vollständigem Editor
✅ Session-Management (eingeloggt bleiben)
✅ Default User beim ersten Start
✅ Grundlage für späteren Login/Registrierung
✅ Basis um hardcoded User-IDs zu ersetzen
✅ Vorbereitung für mehrere User (später)
✅ Vollständiges Verständnis von MVVM und Provider!

**Jetzt können alle anderen Features den ECHTEN User nutzen!**

## Nächste Schritte

Nach Settings:
- **Ersetze hardcoded User-IDs** in Action Center und Night Review
- **Implementiere Habits Lab** (PHASE_7.md) mit echtem User
- **Füge echtes Login hinzu** (später)
- **Multi-User Support** (viel später)

**Du hast jetzt das Fundament für eine professionelle App!**
