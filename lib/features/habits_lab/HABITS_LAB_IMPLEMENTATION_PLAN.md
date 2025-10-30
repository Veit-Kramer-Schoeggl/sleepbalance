# Habits Lab MVVM Implementierungsplan

## Was du bauen wirst

Habits Lab ist dein **Experimentier-Labor** für Schlaf-Interventionen!

Der Benutzer kann:
- **Alle verfügbaren Interventions-Module sehen** (Licht, Sport, Entspannung, Schlafumgebung, Ernährung, etc.)
- **Module aktivieren/deaktivieren** (auswählen welche Interventionen du nutzen möchtest)
- **Seine persönliche Interventions-Strategie zusammenstellen**
- **Module hinzufügen oder entfernen** und die Konfiguration speichern
- **Später: Statistiken für aktive Module sehen** (Sekundärfunktion)

**Think of it as:** Ein Labor wo du verschiedene "Experimente" (Module) auswählst um deinen Schlaf zu verbessern!

**WICHTIG:** Es ist ein **Modul-Management Screen**. Der Fokus liegt auf der Auswahl und Konfiguration von Interventions-Modulen, die der User nutzen möchte.

## Voraussetzungen

- ✅ Phase 1-4 abgeschlossen (Datenbank, Action Center)
- ✅ Light Module bereits implementiert (kennt das Modul-Konzept)
- Du musst MVVM noch nicht kennen - wird hier komplett erklärt!

## Das Muster verstehen (Kein Code!)

### Teil 1: Was ist MVVM?

Stell dir vor, du baust ein Restaurant:

- **Model (Datenmodell)** = Die Speisekarte und Zutaten
  - In unserem Fall: `ModuleConfig` (welche Module sind verfügbar und welche sind aktiv)
  - Enthält: Modul-ID, Name, aktiv/inaktiv Status, etc.
  - Nur Daten, keine Logik!

- **View (Bildschirm)** = Der Gastraum, wo Gäste sitzen
  - In unserem Fall: `HabitsScreen` (was der Benutzer sieht)
  - Zeigt Daten an, hat Toggle-Switches und Buttons
  - Reagiert auf Benutzer-Eingaben (Module aktivieren/deaktivieren)

- **ViewModel (Vermittler)** = Der Kellner
  - In unserem Fall: `HabitsViewModel` (das "Gehirn")
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

- Du bestellst etwas: `context.read<ModuleConfigRepository>()`
- Du wartest auf Lieferungen und reagierst sofort: `context.watch<HabitsViewModel>()`
- Wenn neue Daten ankommen, aktualisiert sich die UI automatisch

**Ohne Provider:**
- Du müsstest Objekte durch 5 Ebenen von Widgets durchreichen
- Alptraum-Code mit `widget.repository.dosomething()`

**Mit Provider:**
- Jedes Widget kann sich "einklinken" und Daten holen
- Automatische Updates wenn sich Daten ändern
- Sauberer, lesbarer Code

### Teil 3: Was ist Habits Lab?

**Das Konzept:**

Habits Lab ist ein **Modul-Konfigurations-Screen**. Stell dir vor:

- Du hast verschiedene **Interventions-Module**: Licht-Therapie, Sport, Entspannung, Schlafumgebung, Ernährung, etc.
- Jedes Modul ist eine Art von Intervention, die deinen Schlaf verbessern könnte
- **NICHT alle Module sind für jeden relevant!**
  - Jemand arbeitet Nachtschicht → Licht-Modul wichtig
  - Jemand hat viel Stress → Entspannungs-Modul wichtig
  - Jemand trinkt viel Kaffee → Ernährungs-Modul wichtig

**Was macht Habits Lab?**

Habits Lab lässt dich **deine persönliche Interventions-Strategie zusammenstellen**:

1. Zeigt ALLE verfügbaren Module (Grid oder Liste)
2. Du siehst welche Module aktiv/inaktiv sind
3. Du kannst Module aktivieren (Toggle Switch)
4. Du kannst Module deaktivieren
5. Konfiguration wird in Datenbank gespeichert
6. **Action Center zeigt NUR deine aktiven Module!**

**Datenmodell:**

Wir brauchen eine Tabelle, die speichert:
- Welcher User
- Welches Modul
- Ist es aktiviert? (true/false)

Beispiel:
```
user_id: "user-123", module_id: "light_therapy", is_active: true
user_id: "user-123", module_id: "sport", is_active: true
user_id: "user-123", module_id: "relaxation", is_active: false
user_id: "user-123", module_id: "nutrition", is_active: false
```

Dieser User nutzt Licht-Therapie und Sport, aber NICHT Entspannung und Ernährung.

### Teil 4: Module-Konfiguration vs Aktivitäts-Tracking

Es ist wichtig, diese ZWEI separaten Konzepte zu verstehen:

**1. Modul-Konfiguration (Habits Lab):**
- Frage: "**Welche Interventionen will ich überhaupt probieren?**"
- Screen: Habits Lab
- Daten: user_module_config Tabelle
- Beispiel: "Ich aktiviere Licht-Therapie und Sport"

**2. Aktivitäts-Tracking (Action Center):**
- Frage: "**Habe ich meine aktiven Interventionen heute gemacht?**"
- Screen: Action Center
- Daten: intervention_activities Tabelle
- Beispiel: "Ich habe heute Licht-Therapie gemacht"

**3. Statistiken (Future Feature):**
- Frage: "**Wie konsequent war ich?**"
- Screen: Statistics View (später)
- Daten: Analysiert intervention_activities
- Beispiel: "Ich habe Licht-Therapie 15 von 30 Tagen gemacht"

**Zusammenhang:**
```
Habits Lab aktiviert Module
    ↓
Action Center zeigt NUR aktive Module
    ↓
User macht Aktivitäten
    ↓
Statistics zeigt Erfolgsrate
```

### Teil 5: Die Habits Lab Architektur

```
Benutzer öffnet Habits Lab
    ↓
HabitsScreen zeigt alle verfügbaren Module
    ↓ nutzt
HabitsViewModel
    ↓ lädt
User's active modules from ModuleConfigRepository
    ↓ liest
user_module_config Tabelle (welche Module sind aktiviert?)
    ↓ gibt zurück
List<ModuleConfig> (z.B. light_therapy: active, sport: active, relaxation: inactive)
    ↓ zeigt in UI
Grid/Liste mit Toggle Switches

Benutzer aktiviert/deaktiviert Modul:
    ↓ tap auf Toggle
HabitsViewModel.toggleModule(moduleId)
    ↓ speichert
ModuleConfigRepository.setModuleActive(userId, moduleId, isActive)
    ↓ schreibt
SQLite Datenbank (user_module_config Tabelle)
    ↓ notifyListeners()
UI aktualisiert sich!
```

**Integration mit Action Center:**

```
Benutzer öffnet Action Center
    ↓
ActionViewModel fragt: Welche Module sind aktiv?
    ↓ lädt von
ModuleConfigRepository.getActiveModules(userId)
    ↓ gibt zurück
Nur aktive Module (z.B. light_therapy, sport)
    ↓
Action Center zeigt NUR diese Module!
```

## Schritt-für-Schritt Implementierung

### Schritt 1: Datenmodell erstellen (in PHASE_7.md)

**Was brauchen wir:** Eine neue Tabelle und ein neues Datenmodell

**Tabelle: `user_module_config`**

Spalten:
- `id` (TEXT, PRIMARY KEY) - UUID
- `user_id` (TEXT, NOT NULL) - Foreign Key zu users Tabelle
- `module_id` (TEXT, NOT NULL) - z.B. 'light_therapy', 'sport', 'relaxation'
- `is_active` (INTEGER, NOT NULL) - 1 = aktiviert, 0 = deaktiviert
- `activated_at` (TEXT) - Wann wurde es aktiviert?
- `deactivated_at` (TEXT, NULLABLE) - Wann wurde es deaktiviert?
- `created_at` (TEXT, NOT NULL)
- `updated_at` (TEXT, NOT NULL)

**Index:** UNIQUE auf (user_id, module_id) - ein User kann jedes Modul nur einmal haben

**Model: `ModuleConfig`**

```
class ModuleConfig {
  final String id;
  final String userId;
  final String moduleId;  // 'light_therapy', 'sport', etc.
  final bool isActive;
  final DateTime? activatedAt;
  final DateTime? deactivatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Wichtig:** Dokumentiere dies in PHASE_7.md mit CREATE TABLE Statement!

### Schritt 2: Das ViewModel erstellen

**Was benennen wir es:** `HabitsViewModel`

**Wo kommt es hin:** `lib/features/habits_lab/presentation/viewmodels/habits_viewmodel.dart`

**Was braucht es:**

**Felder (Variablen zum Speichern):**
- `_repository`: Verbindung zum ModuleConfigRepository
- `_availableModules`: Liste ALLER verfügbaren Module (hardcodiert oder aus Config-Datei)
- `_userModuleConfigs`: Map mit moduleId → ModuleConfig (welche sind aktiv?)
- `_isLoading`: Lädt es gerade?
- `_errorMessage`: Fehlermeldung

**Methoden (Funktionen):**

1. **`loadModuleConfigs(userId)`** - Lädt User's Modul-Konfigurationen
   - Setzt `_isLoading = true`
   - Fragt Repository: "Welche Module hat dieser User aktiviert?"
   - Speichert in `_userModuleConfigs` als Map
   - Wenn User noch keine Configs hat: Erstelle Default-Configs (alle inaktiv)
   - Bei Fehler: Speichere in `_errorMessage`
   - Setzt `_isLoading = false`, ruft `notifyListeners()`

2. **`toggleModule(userId, moduleId)`** - Aktiviert/Deaktiviert ein Modul
   - Prüft: Ist Modul aktuell aktiv?
   - Wenn aktiv → deaktiviere: `repository.setModuleActive(userId, moduleId, false)`
   - Wenn inaktiv → aktiviere: `repository.setModuleActive(userId, moduleId, true)`
   - Aktualisiert `_userModuleConfigs`
   - Ruft `notifyListeners()` → UI aktualisiert sich!

3. **`isModuleActive(moduleId)`** - Prüft ob Modul aktiv ist
   - Schaut in `_userModuleConfigs[moduleId]`
   - Gibt `isActive` zurück (oder false wenn nicht gefunden)

4. **`getActiveModules()`** - Gibt Liste aktiver Module zurück
   - Filtert `_availableModules`
   - Nur Module wo `isModuleActive(moduleId) == true`
   - Wird später von Action Center genutzt!

**Getter:**
- `availableModules` → gibt alle verfügbaren Module zurück
- `isLoading` → lädt gerade?
- `errorMessage` → gibt Fehler zurück

**WICHTIG - Fehlerbehandlung (wie immer):**
- try-catch-finally in jeder async Methode
- `_isLoading` setzen vor/nach Operationen
- `_errorMessage` bei Fehlern setzen
- `notifyListeners()` im finally Block

### Schritt 3: Habits Lab Screen erstellen

**Was benennen wir es:** `HabitsScreen`

**Wo kommt es hin:** `lib/features/habits_lab/presentation/screens/habits_screen.dart`

**Struktur (wie immer zwei Widgets):**

**1. HabitsScreen (StatelessWidget)** - Erstellt Provider
```
ChangeNotifierProvider(
  create: (_) => HabitsViewModel(
    repository: context.read<ModuleConfigRepository>(),
  )..loadModuleConfigs(userId),
  child: _HabitsScreenContent(),
)
```

**2. _HabitsScreenContent (StatelessWidget)** - Zeigt UI

**Was zeigen wir:**

**Scaffold mit:**
- AppBar: "Habits Lab" oder "Meine Interventionen"
- Body: Grid/Liste mit Modul-Cards

**UI-Layout:**

**Oberer Bereich: Erklärung (Card)**
- Icon: Labor-Flasche
- Titel: "Wähle deine Interventionen"
- Text: "Aktiviere Module, die du ausprobieren möchtest. Diese erscheinen dann im Action Center."

**Modul-Grid (Hauptbereich):**

Für jedes Modul in `viewModel.availableModules`:

**Modul-Card:**
- **Visuelles:**
  - Icon (z.B. Glühbirne für Licht-Therapie)
  - Titel: "Licht-Therapie"
  - Kurzbeschreibung: "Morgendliches helles Licht gegen Wintermüdigkeit"
  - Toggle Switch (groß und deutlich!)

- **Status-Anzeige:**
  - Wenn aktiv: Card mit grünem Border oder Hintergrund
  - Wenn inaktiv: Card ausgegraut

- **Switch-Verhalten:**
  - onChanged: `viewModel.toggleModule(userId, moduleId)`
  - Animiert: Card färbt sich beim Toggle

- **Informations-Button (optional):**
  - Kleines Info-Icon
  - onTap: Zeigt Dialog mit Details zum Modul

**Grid Layout:**
- 2 Spalten auf Smartphone
- 3-4 Spalten auf Tablet
- GridView.builder mit padding

**Modul-Reihenfolge:**
1. Light Therapy (Licht-Therapie)
2. Physical Activity (Sport & Bewegung)
3. Relaxation (Entspannung & Meditation)
4. Sleep Environment (Schlafumgebung)
5. Nutrition (Ernährung & Koffein)
6. Social Rhythm (Sozialer Rhythmus)
7. (Weitere Module später...)

**Unterer Bereich: Zusammenfassung (Card)**
- Text: "X von Y Modulen aktiviert"
- Zeigt: `viewModel.getActiveModules().length` von `viewModel.availableModules.length`

**Lade-Zustand:**
Wenn `viewModel.isLoading`:
- Zeige CircularProgressIndicator in Mitte

**Fehler-Zustand:**
Wenn `viewModel.errorMessage != null`:
- Zeige Fehlertext in rot
- Button: "Nochmal versuchen" → ruft `viewModel.loadModuleConfigs()` auf

### Schritt 4: Modul-Metadaten zentral definieren

**Problem:** Jedes Modul braucht Icon, Name, Beschreibung, Farbe

**Lösung:** Eine zentrale Datei für Modul-Metadaten

**Was benennen wir es:** `ModuleMetadata` class

**Wo kommt es hin:** `lib/modules/shared/module_config.dart`

**Struktur:**

```dart
class ModuleMetadata {
  final String id;              // 'light_therapy'
  final String displayName;     // 'Licht-Therapie'
  final String description;     // 'Morgendliches helles Licht...'
  final IconData icon;          // Icons.lightbulb
  final Color primaryColor;     // Colors.amber
  final Color secondaryColor;   // Colors.amber.shade100
}

// Global verfügbare Map
final Map<String, ModuleMetadata> moduleMetadata = {
  'light_therapy': ModuleMetadata(
    id: 'light_therapy',
    displayName: 'Licht-Therapie',
    description: 'Morgendliches helles Licht gegen Wintermüdigkeit und zur Unterstützung des zirkadianen Rhythmus',
    icon: Icons.lightbulb,
    primaryColor: Colors.amber,
    secondaryColor: Colors.amber.shade100,
  ),

  'physical_activity': ModuleMetadata(
    id: 'physical_activity',
    displayName: 'Sport & Bewegung',
    description: 'Regelmäßige körperliche Aktivität für besseren Schlaf',
    icon: Icons.directions_run,
    primaryColor: Colors.green,
    secondaryColor: Colors.green.shade100,
  ),

  'relaxation': ModuleMetadata(
    id: 'relaxation',
    displayName: 'Entspannung',
    description: 'Meditation, Progressive Muskelentspannung und Atemübungen',
    icon: Icons.spa,
    primaryColor: Colors.purple,
    secondaryColor: Colors.purple.shade100,
  ),

  'sleep_environment': ModuleMetadata(
    id: 'sleep_environment',
    displayName: 'Schlafumgebung',
    description: 'Optimierung von Temperatur, Licht, Lärm und Luftqualität',
    icon: Icons.bed,
    primaryColor: Colors.blue,
    secondaryColor: Colors.blue.shade100,
  ),

  'nutrition': ModuleMetadata(
    id: 'nutrition',
    displayName: 'Ernährung',
    description: 'Koffein-Timing, Alkohol-Konsum und Essens-Zeitpunkt',
    icon: Icons.restaurant,
    primaryColor: Colors.orange,
    secondaryColor: Colors.orange.shade100,
  ),

  'social_rhythm': ModuleMetadata(
    id: 'social_rhythm',
    displayName: 'Sozialer Rhythmus',
    description: 'Regelmäßige Zeiten für Mahlzeiten und soziale Aktivitäten',
    icon: Icons.people,
    primaryColor: Colors.teal,
    secondaryColor: Colors.teal.shade100,
  ),
};

// Helper Funktion
ModuleMetadata getModuleMetadata(String moduleId) {
  return moduleMetadata[moduleId] ??
    ModuleMetadata(
      id: moduleId,
      displayName: 'Unbekanntes Modul',
      description: '',
      icon: Icons.help_outline,
      primaryColor: Colors.grey,
      secondaryColor: Colors.grey.shade100,
    );
}
```

**Wie nutzen:**
```dart
final metadata = getModuleMetadata('light_therapy');
Icon(metadata.icon, color: metadata.primaryColor)
Text(metadata.displayName)
Text(metadata.description)
```

**Warum ist das gut?**
- Ein Ort für alle Modul-Infos
- Einfach neue Module hinzufügen
- Konsistent in ganzer App (Habits Lab, Action Center, Statistics)
- Keine Magic Strings überall
- Type-safe

### Schritt 5: Repository erstellen

**Was benennen wir es:** `ModuleConfigRepository`

**Wo kommt es hin:** `lib/modules/shared/domain/repositories/module_config_repository.dart`

**Was ist es:** Eine **abstrakte Schnittstelle** (wie alle Repositories)

**Methoden:**

1. **`getModuleConfig(userId, moduleId)`**
   - Gibt: ModuleConfig für spezifisches Modul dieses Users
   - Query: `SELECT * FROM user_module_config WHERE user_id = ? AND module_id = ?`

2. **`getAllModuleConfigs(userId)`**
   - Gibt: Liste ALLER ModuleConfigs für diesen User
   - Query: `SELECT * FROM user_module_config WHERE user_id = ?`

3. **`getActiveModules(userId)`**
   - Gibt: Liste der Modul-IDs, die aktiv sind
   - Query: `SELECT module_id FROM user_module_config WHERE user_id = ? AND is_active = 1`

4. **`setModuleActive(userId, moduleId, isActive)`**
   - Aktiviert/Deaktiviert ein Modul
   - Prüft: Existiert Config schon?
   - Wenn ja: UPDATE `is_active`, setze `activated_at` oder `deactivated_at`
   - Wenn nein: INSERT neue Config

5. **`createDefaultConfigs(userId, moduleIds)`**
   - Erstellt Configs für alle Module (alle inaktiv)
   - Wird beim ersten Öffnen von Habits Lab aufgerufen
   - INSERT für jedes Modul mit `is_active = 0`

**DataSource:**

**Was benennen wir es:** `ModuleConfigLocalDataSource`

**Wo kommt es hin:** `lib/modules/shared/data/datasources/module_config_local_datasource.dart`

**Was macht es:**
- Führt SQL-Queries aus (wie immer)
- Nutzt `DatabaseConstants` für Tabellen-/Spaltennamen
- Konvertiert mit `fromDatabase()` (nicht fromJson!)
- Nutzt `DatabaseDateUtils` für DateTime-Konvertierung

**Repository Implementation:**

**Was benennen wir es:** `ModuleConfigRepositoryImpl`

**Wo kommt es hin:** `lib/modules/shared/data/repositories/module_config_repository_impl.dart`

**Was macht es:**
- Implementiert `ModuleConfigRepository`
- Delegiert alle Methoden an `ModuleConfigLocalDataSource`
- Keine Logik, nur Weiterleitung (wie immer!)

**In main.dart registrieren:**
```dart
Provider<ModuleConfigLocalDataSource>(
  create: (context) => ModuleConfigLocalDataSource(
    databaseHelper: context.read<DatabaseHelper>(),
  ),
),
Provider<ModuleConfigRepository>(
  create: (context) => ModuleConfigRepositoryImpl(
    dataSource: context.read<ModuleConfigLocalDataSource>(),
  ),
),
```

**Wichtig:** DataSource VOR Repository!

### Schritt 6: Integration mit Action Center

**Aktuell:** Action Center zeigt ALLE Module

**Neu:** Action Center zeigt NUR AKTIVE Module

**Änderungen in ActionViewModel:**

1. Beim Laden von verfügbaren Modulen:
```dart
// Alt (hardcodiert):
final availableModules = ['light_therapy', 'sport', 'relaxation'];

// Neu (dynamisch):
final activeModules = await moduleConfigRepository.getActiveModules(userId);
```

2. Action Center filtert basierend auf `activeModules`

**Verhalten:**
- User aktiviert Licht-Modul in Habits Lab
- User öffnet Action Center
- Action Center zeigt Licht-Modul
- User deaktiviert Licht-Modul in Habits Lab
- User öffnet Action Center erneut
- Action Center zeigt Licht-Modul NICHT mehr

### Schritt 7: Statistiken (Optional - Später)

**Erst NACH Basis-Habits Lab funktioniert!**

**Was zeigen:**
- Für jedes aktive Modul: "15 von 30 Tagen gemacht = 50%"
- Kalender-View mit Markierungen
- Längste Streak: "7 Tage in Folge!"
- Durchschnitt: "2.5 mal pro Woche"

**Wie:**
- Nutze `InterventionRepository` (schon aus Action Center/Night Review vorhanden)
- Zähle Aktivitäten pro Modul
- Zeige unter jedem Modul in Habits Lab oder in separatem Tab

**Priorisierung:** NIEDRIG - Fokus liegt auf Modul-Konfiguration!

## API Endpoints (TODO - Später ausfüllen)

Aktuell: Nur lokale SQLite Datenbank

Später mit Backend:

- [ ] Endpoint für Modul-Konfigurationen laden: _________________
- [ ] Endpoint für Modul aktivieren/deaktivieren: _________________
- [ ] Endpoint für empfohlene Module basierend auf User-Profil: _________________

## Deine Implementierung testen

### Manuelle Tests (Schritt für Schritt):

1. **Habits Lab öffnen (erstes Mal)**
   - ✅ Sollte alle verfügbaren Module zeigen (6 Module)
   - ✅ Alle Module sollten INAKTIV sein (Switches aus)
   - ✅ Kein Crash

2. **Modul aktivieren**
   - Aktiviere "Licht-Therapie" (Toggle Switch)
   - ✅ Switch sollte an sein
   - ✅ Card sollte sich visuell ändern (grüner Border)
   - ✅ Zusammenfassung: "1 von 6 Modulen aktiviert"

3. **Mehrere Module aktivieren**
   - Aktiviere "Sport" und "Entspannung"
   - ✅ Alle drei Switches sollten an sein
   - ✅ Zusammenfassung: "3 von 6 Modulen aktiviert"

4. **Datenbank prüfen**
   - Öffne SQLite Viewer
   - Query: `SELECT * FROM user_module_config WHERE user_id = 'deine-id'`
   - ✅ Sollte 3 Einträge haben mit `is_active = 1`
   - ✅ Andere Module sollten `is_active = 0` haben oder nicht existieren

5. **App neu starten**
   - Schließe App komplett
   - Öffne wieder, gehe zu Habits Lab
   - ✅ Alle 3 Module sollten noch aktiviert sein
   - ✅ Switches sollten an sein

6. **Modul deaktivieren**
   - Deaktiviere "Sport" (Toggle Switch)
   - ✅ Switch sollte aus sein
   - ✅ Card sollte ausgegraut sein
   - ✅ Zusammenfassung: "2 von 6 Modulen aktiviert"

7. **Action Center Integration**
   - Aktiviere nur "Licht-Therapie" in Habits Lab
   - Öffne Action Center
   - ✅ Sollte NUR Licht-Therapie zeigen
   - ✅ Sport und Entspannung sollten NICHT sichtbar sein

8. **Action Center Test 2**
   - Deaktiviere alle Module in Habits Lab
   - Öffne Action Center
   - ✅ Sollte leeren Zustand zeigen: "Keine aktiven Module"
   - ✅ Button: "Module aktivieren" → navigiert zu Habits Lab

9. **Info-Dialog testen (falls implementiert)**
   - Tippe Info-Icon bei einem Modul
   - ✅ Dialog öffnet sich mit Beschreibung
   - ✅ Dialog schließt beim Tap außerhalb

10. **Performance testen**
    - Toggle mehrere Module schnell hintereinander
    - ✅ UI sollte flüssig bleiben
    - ✅ Keine Verzögerung beim Switch
    - ✅ Datenbank-Writes sollten schnell sein

### Häufige Fehler vermeiden

**❌ Fehler 1: Module erscheinen nicht im Action Center**
- Symptom: Modul in Habits Lab aktiviert, aber nicht in Action Center
- Prüfe: Wird `moduleConfigRepository.getActiveModules()` im ActionViewModel aufgerufen?
- Prüfe: Haben beide die gleiche User-ID?
- Prüfe: SQL Query korrekt? `WHERE is_active = 1` nicht vergessen!

**❌ Fehler 2: Toggle Switch aktualisiert sich nicht**
- Symptom: Tap auf Switch, aber visuell keine Änderung
- Lösung: `notifyListeners()` im ViewModel nach Toggle aufrufen!
- Prüfe: Ist Widget mit `context.watch<HabitsViewModel>()` verbunden?

**❌ Fehler 3: Doppelte Einträge in Datenbank**
- Symptom: Mehrere Configs für das gleiche Modul
- Lösung: UNIQUE Index auf (user_id, module_id) in CREATE TABLE
- Lösung: Im Repository prüfen ob Config existiert vor INSERT

**❌ Fehler 4: Alle Module sind aktiv nach App-Neustart**
- Symptom: Deaktivierte Module sind plötzlich wieder aktiv
- Prüfe: Wird `is_active` korrekt gespeichert? (1 oder 0, nicht true/false String)
- Prüfe: fromDatabase konvertiert INTEGER zu bool korrekt?

**❌ Fehler 5: Modul-Icon oder Name fehlt**
- Symptom: "Unknown module" oder graues Icon
- Lösung: Prüfe `moduleMetadata` Map - enthält alle Module-IDs?
- Lösung: Nutze `getModuleMetadata()` mit Fallback für unbekannte IDs

**❌ Fehler 6: Provider nicht registriert**
- Symptom: "Could not find ModuleConfigRepository"
- Lösung: main.dart vergessen? DataSource UND Repository registrieren!
- Reihenfolge: DataSource → Repository

## Benötigst du Hilfe?

- **Vergleiche mit Action Center:** Ähnliche Struktur (ViewModel, Repository, Screen)
- **Vergleiche mit Settings:** Ähnliche Toggle-Logik (Switch-Widgets)
- **SQL UNIQUE Index:** Verhindert Duplikate automatisch
- **Provider Pattern:** Gleich wie überall, nur andere Daten

## Was haben wir erreicht?

Nach dieser Implementierung hast du:

✅ Modul-Auswahl Screen (Habits Lab)
✅ Aktivieren/Deaktivieren von Interventions-Modulen
✅ Persistente Speicherung der Modul-Konfiguration
✅ Zentrale Modul-Metadaten (Icons, Namen, Beschreibungen)
✅ Integration mit Action Center (zeigt nur aktive Module)
✅ Personalisierte Interventions-Strategie pro User
✅ Grundlage für modulares Interventions-System
✅ Gleiche MVVM-Architektur wie überall
✅ Vollständiges Verständnis von MVVM und Provider!

**Du kannst jetzt dein persönliches Schlaf-Interventions-Programm zusammenstellen!**

## Nächste Schritte

Nach Habits Lab:

**Weitere Module implementieren:**
- Sport-Modul (Aktivität tracken)
- Entspannung-Modul (Meditation, Atemübungen)
- Ernährungs-Modul (Koffein-Tracking)
- Schlafumgebungs-Modul (Temperatur, Licht, Lärm)

**Statistiken hinzufügen:**
- Erfolgsrate pro Modul anzeigen
- Kalender-View mit Aktivitäten
- Streak-Tracking ("10 Tage in Folge!")
- Korrelations-Analyse: "An Sport-Tagen schläfst du 15% besser"

**Erweiterte Features:**
- Modul-Empfehlungen basierend auf User-Profil
- Onboarding: "Welche Module passen zu dir?"
- Benachrichtigungen: "Du hast heute noch keine Licht-Therapie gemacht"
- Gamification: Badges für konsequente Nutzung

**Du hast jetzt ein professionelles Modul-Management-System!**
