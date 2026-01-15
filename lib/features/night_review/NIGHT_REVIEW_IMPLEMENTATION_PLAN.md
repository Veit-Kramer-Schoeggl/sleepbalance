# Night Review MVVM Implementierungsplan

## ⚠️ WICHTIG: Daten-Layer ist bereits fertig! **COMPLETED**

**Phase 3 ist abgeschlossen** - Die komplette Daten-Schicht (Data Layer) ist bereits implementiert:

✅ **Fertig implementiert (in Phase 3):**
- Database Migration V3 (`migration_v3.dart`)
- Domain Models:
  - `SleepRecord` - Mit allen Schlafmetriken inkl. `avgHeartRateVariability`
  - `SleepBaseline` - Für persönliche Durchschnittswerte
  - `SleepComparison` - Zum Vergleichen mit Durchschnitt
- Repository Pattern:
  - `SleepRecordRepository` (Interface)
  - `SleepRecordLocalDataSource` (SQLite Operationen)
  - `SleepRecordRepositoryImpl` (Implementierung)
- Provider Registrierung in `main.dart`

📋 **Was du implementierst (UI Layer):**
- `NightReviewViewModel` - Verwaltet UI-Zustand und Logik
- `NightScreen` Refactoring - Von StatefulWidget zu StatelessWidget
- `QualityRatingWidget` - 3-Stufen Bewertung
- UI-Verbindungen zu den fertigen Repositories

**Du musst KEINE Datenbank-Operationen oder Models erstellen!** Die Daten-Schicht existiert bereits und ist getestet.

## Was du bauen wirst

Die Night Review Funktion zeigt dem Benutzer seine Schlafdaten für eine bestimmte Nacht an. Der Benutzer kann:
- Durch verschiedene Nächte navigieren (vor/zurück)
- Einen Kalender öffnen um ein spezifisches Datum auszuwählen
- Seine Schlafdaten sehen (Tiefschlaf, REM-Schlaf, Herzfrequenz, etc.)
- Seine Daten mit seinem persönlichen Durchschnitt vergleichen (nutzt fertige `SleepComparison`)
- Eine subjektive Bewertung abgeben ("schlecht", "durchschnitt", "gut")

**Wichtig:** Diese Implementierung folgt EXAKT dem gleichen Muster wie Action Center (Phase 2). Du kannst Action Center jederzeit als Referenz verwenden!

## Voraussetzungen

- ✅ **Phase 3 (Night Review Data Layer) abgeschlossen** - Repository und Models sind fertig!
- ✅ Phase 2 (Action Center) abgeschlossen - wir folgen dem gleichen Muster!
- ✅ Du verstehst das Action Center Beispiel (wenn nicht, schau es dir zuerst an!)
- ✅ Du weißt, dass die Repositories bereits in `main.dart` registriert sind

## Das Muster verstehen (Kein Code!) **COMPLETED** (Documentation)

### Teil 1: Was ist MVVM? **COMPLETED** (Documentation)

Stell dir vor, du baust ein Restaurant:

- **Model (Datenmodell)** = Die Speisekarte und Zutaten
  - In unserem Fall: `SleepRecord` (eine Nacht voller Schlafdaten)
  - Enthält: Einschlafzeit, Aufwachzeit, Tiefschlaf-Dauer, Herzfrequenz, etc.
  - Nur Daten, keine Logik!

- **View (Bildschirm)** = Der Gastraum, wo Gäste sitzen
  - In unserem Fall: `NightScreen` (was der Benutzer sieht)
  - Zeigt Daten an, hat Buttons und Widgets
  - Reagiert auf Benutzer-Eingaben (Tap, Swipe, etc.)

- **ViewModel (Vermittler)** = Der Kellner
  - In unserem Fall: `NightReviewViewModel` (das "Gehirn")
  - Holt Daten aus dem Repository (Küche)
  - Verarbeitet Daten für die View
  - Sagt der View: "Hey, ich habe neue Daten, aktualisiere dich!"

**Warum ist das gut?**
- Der Bildschirm (View) muss nicht wissen, woher die Daten kommen
- Die Daten (Model) müssen nicht wissen, wie sie angezeigt werden
- Das ViewModel verbindet beide und hält sie getrennt
- Einfacher zu testen und zu warten!

### Teil 2: Was ist Provider? **COMPLETED** (Documentation)

Provider ist wie ein **Lieferservice** in Flutter:

- Du bestellst etwas: `context.read<SleepRecordRepository>()`
- Du wartest auf Lieferungen und reagierst sofort: `context.watch<NightReviewViewModel>()`
- Wenn neue Daten ankommen, aktualisiert sich die UI automatisch

**Ohne Provider:**
- Du müsstest Objekte durch 5 Ebenen von Widgets durchreichen
- Alptraum-Code mit `widget.repository.dosomething()`

**Mit Provider:**
- Jedes Widget kann sich "einklinken" und Daten holen
- Automatische Updates wenn sich Daten ändern
- Sauberer, lesbarer Code

### Teil 3: Die Night Review Architektur **COMPLETED** (Documentation)

```
Benutzer tippt "Vorheriger Tag" Button
         ↓
    NightScreen (View)
         ↓ ruft Methode auf
    NightReviewViewModel
         ↓ fragt nach Daten
    SleepRecordRepository (Schnittstelle)
         ↓ implementiert von
    SleepRecordRepositoryImpl
         ↓ delegiert zu
    SleepRecordLocalDataSource
         ↓ liest aus
    SQLite Datenbank (über DatabaseHelper)
         ↓ gibt zurück
    SleepRecord (Rohdaten aus DB)
         ↓ verarbeitet von
    NightReviewViewModel (berechnet Vergleiche)
         ↓ notifyListeners()
    NightScreen aktualisiert sich automatisch!
```

**Vergleich mit Action Center:**
- Action Center: Tägliche Aktionen anzeigen/abhaken
- Night Review: Nächtliche Schlafdaten anzeigen/bewerten
- **Identisches Muster, unterschiedliche Daten!**

## Schritt-für-Schritt Implementierung

### Schritt 1: Das ViewModel erstellen ❌ NOT IMPLEMENTED

**Was macht ein ViewModel?**

Ein ViewModel ist wie ein **Manager**, der:
1. Den aktuellen Zustand speichert (welches Datum, welche Daten, lädt es gerade?)
2. Daten vom Repository holt
3. Der View sagt, wenn sich etwas ändert

**Was benennen wir es:** `NightReviewViewModel`

**Wo kommt es hin:** `lib/features/night_review/presentation/viewmodels/night_review_viewmodel.dart`

**Was braucht es:**

**Felder (Variablen zum Speichern):**
- `_repository`: Verbindung zum Repository (um Daten zu holen) - Typ: `SleepRecordRepository`
- `_currentDate`: Welches Datum gerade angezeigt wird - Typ: `DateTime`
- `_sleepRecord`: Die Schlafdaten für diese Nacht (kann null sein!) - Typ: `SleepRecord?` (bereits in Phase 3 erstellt!)
- `_comparison`: Vergleich mit dem persönlichen Durchschnitt - Typ: `SleepComparison?` (bereits in Phase 3 erstellt!)
- `_isLoading`: Lädt es gerade? (für Lade-Spinner) - Typ: `bool`
- `_isCalendarExpanded`: Ist der Kalender ausgeklappt? - Typ: `bool`
- `_errorMessage`: Fehlermeldung, falls etwas schiefgeht - Typ: `String?`

**✅ Wichtig:** `SleepRecord`, `SleepBaseline` und `SleepComparison` sind bereits fertige Modelle aus Phase 3! Du musst sie nur importieren:
```dart
import '../../domain/models/sleep_record.dart';
import '../../domain/models/sleep_baseline.dart';
import '../../domain/models/sleep_comparison.dart';
import '../../domain/repositories/sleep_record_repository.dart';
```

**Methoden (Funktionen):**

1. **`loadSleepData(userId)`** - Lädt Schlafdaten für das aktuelle Datum
   - Setzt `_isLoading = true`
   - Fragt Repository: "Gib mir Schlafdaten für dieses Datum"
   - Verwendet: `_repository.getRecordForDate(userId, _currentDate)`
   - Wenn Daten da sind: Lade auch Baseline-Daten und berechne Vergleich
     - Verwendet: `_repository.getBaselines(userId, '7_day')` für Baselines
     - Verwendet: `SleepComparison.calculate(record, baselines)` zum Vergleichen (fertige Methode!)
   - Wenn Fehler: Speichere Fehlermeldung
   - Setzt `_isLoading = false`
   - Ruft `notifyListeners()` - sagt allen: "Ich habe neue Daten!"

   **✅ Tipp:** Das Repository ist schon fertig, du musst nur die Methoden aufrufen!

2. **`changeDate(newDate)`** - Wechselt zu einem anderen Datum
   - Speichert neues Datum in `_currentDate`
   - Ruft `loadSleepData()` auf, um Daten für neues Datum zu laden

3. **`goToPreviousDay()`** - Geht einen Tag zurück
   - Subtrahiert 1 Tag von `_currentDate`
   - Ruft `changeDate()` auf

4. **`goToNextDay()`** - Geht einen Tag vor
   - Addiert 1 Tag zu `_currentDate`
   - Ruft `changeDate()` auf

5. **`toggleCalendarExpansion()`** - Klappt Kalender ein/aus
   - Dreht `_isCalendarExpanded` um (true → false, false → true)
   - Ruft `notifyListeners()` auf

6. **`saveQualityRating(rating, notes)`** - Speichert Benutzer-Bewertung
   - Prüft: Gibt es überhaupt Schlafdaten? (sonst Fehler)
   - Ruft Repository auf: "Speichere diese Bewertung"
   - Verwendet: `_repository.updateQualityRating(recordId, rating, notes)` (fertige Methode!)
   - Lädt Daten neu, um Änderungen zu zeigen

   **✅ Hinweis:** Die Methode `updateQualityRating` existiert bereits im Repository (Phase 3)!

**WICHTIG - Fehlerbehandlung:**
Jede Methode, die Daten lädt, muss folgendes Muster haben:
1. Setze `_isLoading = true` und `_errorMessage = null`
2. Rufe `notifyListeners()` (zeigt Lade-Spinner)
3. Versuche Daten zu laden (in einem `try` Block)
4. Wenn Fehler: Speichere in `_errorMessage` (in einem `catch` Block)
5. Am Ende IMMER: Setze `_isLoading = false` (in einem `finally` Block)
6. Rufe `notifyListeners()` im `finally` Block

**Referenz:** Schau dir `ActionViewModel` an - es ist identisch, nur mit anderen Daten!

### Schritt 2: ViewModel mit Screen verbinden ❌ NOT IMPLEMENTED

**Was passiert hier?**

Wir verwenden **Provider**, um das ViewModel an den Screen zu "liefern".

**In `night_screen.dart`:**

1. Der Hauptscreen (`NightScreen`) wird zu einem `StatelessWidget` (kein State mehr!)
2. Im `build()`-Method wrappen wir alles in einen `ChangeNotifierProvider`
3. Der Provider **erstellt** das ViewModel und ruft sofort `loadSleepData()` auf
4. Ein inneres Widget (`_NightScreenContent`) hat Zugriff auf das ViewModel

**Warum zwei Widgets (NightScreen + _NightScreenContent)?**
- `NightScreen`: Erstellt den Provider (nur einmal)
- `_NightScreenContent`: Nutzt den Provider (kann sich oft neu bauen)
- Verhindert unnötiges Neu-Erstellen des ViewModels

**Referenz:** Action Center macht es genauso!

### Schritt 3: StatefulWidget zu StatelessWidget umwandeln ❌ NOT IMPLEMENTED

**Was entfernen wir aus NightScreen:**

❌ **Weg damit:**
- Die `_NightScreenState` Klasse (alle ~80 Zeilen!)
- `_currentDate` Variable (jetzt im ViewModel)
- `_isCalendarExpanded` Variable (jetzt im ViewModel)
- Alle `setState()` Aufrufe (Provider macht das jetzt)
- `initState()` und `dispose()` Methoden

✅ **Das bleibt:**
- Das UI-Layout (Scaffold, AppBar, Body)
- Die Widget-Struktur (DateNavigationHeader, Calendar, etc.)
- Die Styling-Informationen (Farben, Abstände, etc.)

**Warum ist das besser?**
- Weniger Code!
- Keine State-Management-Probleme
- Logik ist im ViewModel (testbar!)
- Screen ist nur noch "dumme" Anzeige

### Schritt 4: ViewModel in der UI nutzen ❌ NOT IMPLEMENTED

**Wie greifst du auf Daten zu?**

Im `_NightScreenContent` Widget:

```
# Am Anfang der build() Methode:
final viewModel = context.watch<NightReviewViewModel>();

# Jetzt kannst du alle Daten nutzen:
- viewModel.currentDate → aktuelles Datum
- viewModel.sleepRecord → Schlafdaten (oder null)
- viewModel.isLoading → zeigt Lade-Spinner?
- viewModel.errorMessage → gibt's einen Fehler?
- viewModel.hasData → gibt es Daten zu zeigen?
```

**Beispiele:**

- **Lade-Spinner anzeigen:**
  - Wenn `viewModel.isLoading` true ist → zeige CircularProgressIndicator

- **Fehler anzeigen:**
  - Wenn `viewModel.errorMessage` nicht null ist → zeige Fehlertext in rot

- **Datum anzeigen:**
  - Nutze `viewModel.currentDate` im DateNavigationHeader

- **Buttons verbinden:**
  - "Vorheriger Tag" Button: `onPressed: viewModel.goToPreviousDay`
  - "Nächster Tag" Button: `onPressed: viewModel.goToNextDay`
  - Kalender Button: `onPressed: viewModel.toggleCalendarExpansion`

- **Schlafdaten anzeigen:**
  - Prüfe erst: `if (viewModel.hasData)`
  - Dann greife zu: `viewModel.sleepRecord.totalSleepTime`
  - Oder zeige: "Keine Daten für diese Nacht"

- **Vergleich mit Durchschnitt anzeigen (aus Phase 3!):**
  - Nutze `viewModel.comparison` (Typ: `SleepComparison?`)
  - Prüfe ob besser als Durchschnitt: `comparison.isAboveAverage('avg_deep_sleep')`
  - Zeige Differenz: `comparison.getDifferenceText('avg_deep_sleep', unit: 'min')`
  - Zeige Prozent: `comparison.getPercentageDifference('avg_deep_sleep')`
  - **Alle Helper-Methoden sind bereits in SleepComparison implementiert!**

**Magisch:** Immer wenn das ViewModel `notifyListeners()` ruft, baut sich `_NightScreenContent` automatisch neu! Keine `setState()` Aufrufe nötig!

### Schritt 5: Quality Rating Widget hinzufügen ⚠️ PARTIAL (UI exists, not connected to DB)

**Was ist das?**

Ein kleines Widget mit 3 Buttons: 😢 Schlecht | 😐 Durchschnitt | 😊 Gut

**Wo kommt es hin:**
`lib/features/night_review/presentation/widgets/quality_rating_widget.dart`

**Was braucht es:**

**Parameter:**
- `currentRating`: Welcher Button ist gerade ausgewählt? (kann null sein)
- `onRatingSelected`: Callback-Funktion, die aufgerufen wird, wenn Benutzer tippt

**Was macht es:**
- Zeigt 3 Buttons horizontal nebeneinander
- Der ausgewählte Button ist hervorgehoben (farbig)
- Wenn Benutzer tippt → ruft `onRatingSelected('good')` auf
- Dann speichert ViewModel das in der Datenbank

**Farben:**
- Rot für "schlecht"
- Gelb für "durchschnitt"
- Grün für "gut"

**Wo nutzen wir es:**
Im `_NightScreenContent`, unterhalb der Schlafdaten, mit:
```
onRatingSelected: (rating) {
  viewModel.saveQualityRating(rating, null);
}
```

### Schritt 6: Kalender-Funktionalität ⚠️ PARTIAL (UI exists, not connected to ViewModel)

**Was haben wir:**
- DateNavigationHeader (Pfeile links/rechts + Datum in der Mitte)
- ExpandableCalendar (klappt aus wenn Benutzer auf Datum tippt)

**Was verändert sich:**

**Vorher (StatefulWidget):**
- State speichert `_currentDate`
- State speichert `_isCalendarExpanded`
- `setState()` bei jeder Änderung

**Nachher (StatelessWidget + ViewModel):**
- ViewModel speichert `_currentDate`
- ViewModel speichert `_isCalendarExpanded`
- `notifyListeners()` bei jeder Änderung
- UI aktualisiert sich automatisch

**DateNavigationHeader verbinden:**
- `currentDate`: von `viewModel.currentDate`
- `onPreviousDay`: ruft `viewModel.goToPreviousDay()` auf
- `onNextDay`: ruft `viewModel.goToNextDay()` auf
- `onDateTap`: ruft `viewModel.toggleCalendarExpansion()` auf

**ExpandableCalendar verbinden:**
- `selectedDate`: von `viewModel.currentDate`
- `isExpanded`: von `viewModel.isCalendarExpanded`
- `onDateSelected`: ruft `viewModel.changeDate(selectedDate)` auf

**Verhalten:**
1. Benutzer tippt auf Datum → Kalender klappt aus
2. Benutzer wählt neues Datum → Kalender klappt zu, Daten werden geladen
3. Pfeile → Ändern Datum, Kalender bleibt wie er ist

## API Endpoints (TODO - Später ausfüllen)

Aktuell nutzen wir nur lokale SQLite Datenbank. Wenn wir später einen Backend-Server haben:

- [ ] Endpoint zum Abrufen von Schlafdaten: _________________
- [ ] Endpoint zum Speichern der Bewertung: _________________
- [ ] Endpoint zum Abrufen von Baselines: _________________

Diese Endpoints werden dann im Repository hinzugefügt, aber das UI und ViewModel ändern sich NICHT!

## Deine Implementierung testen

### Manuelle Tests (Schritt für Schritt):

1. **App starten und zu Night Review navigieren**
   - ✅ Sollte "Keine Daten" anzeigen (Datenbank ist leer)
   - ✅ Kein Absturz, kein Fehler

2. **Test-Daten in Datenbank einfügen**
   - Benutze SQL aus PHASE_3.md (siehe Database Validation Abschnitt)
   - Füge einen Testdatensatz für heute ein

3. **App neu starten**
   - ✅ Daten sollten jetzt angezeigt werden
   - ✅ Tiefschlaf, REM-Schlaf, Herzfrequenz sichtbar

4. **Datum-Navigation testen**
   - Tippe linken Pfeil → ✅ Datum geht einen Tag zurück
   - Tippe rechten Pfeil → ✅ Datum geht einen Tag vor
   - ✅ Daten aktualisieren sich automatisch

5. **Kalender testen**
   - Tippe auf Datum in der Mitte → ✅ Kalender klappt aus
   - Wähle ein anderes Datum → ✅ Kalender klappt zu, neue Daten laden
   - Tippe nochmal auf Datum → ✅ Kalender klappt wieder ein

6. **Quality Rating testen**
   - Tippe auf "Gut" Button → ✅ Button wird grün
   - Prüfe Datenbank → ✅ `quality_rating` Feld sollte 'good' sein
   - App neu starten → ✅ Rating sollte gespeichert bleiben

7. **Leerer Zustand testen**
   - Navigiere zu einem Datum ohne Daten
   - ✅ Sollte "Keine Schlafdaten für diese Nacht" anzeigen
   - ✅ Kein Absturz

8. **Lade-Zustand testen**
   - Füge `await Future.delayed(Duration(seconds: 2))` im ViewModel ein (temporär!)
   - ✅ Lade-Spinner sollte für 2 Sekunden erscheinen
   - Entferne es danach wieder

### Häufige Fehler vermeiden

**✅ Gut zu wissen: Provider bereits registriert!**
- `SleepRecordLocalDataSource` und `SleepRecordRepository` sind bereits in `main.dart` registriert (Phase 3)
- Falls "Could not find correct Provider" Fehler: Prüfe, ob du das ViewModel richtig registrierst
- **Reihenfolge:** DataSource → Repository → ViewModel

**❌ Fehler 1: Provider nicht registriert (falls du den ViewModel Provider hinzufügst)**
- Symptom: "Could not find NightReviewViewModel" Fehler
- Lösung: ViewModel wird normalerweise NICHT in main.dart registriert, sondern direkt im Screen mit `ChangeNotifierProvider`
- **Wichtig:** Repository ist schon da, nur ViewModel muss im Screen erstellt werden!

**❌ Fehler 2: context.watch in build() vergessen**
- Symptom: UI aktualisiert sich nicht
- Lösung: Nutze `context.watch<NightReviewViewModel>()`, NICHT `context.read()`
- `watch` = Updates automatisch, `read` = nur einmal holen

**❌ Fehler 3: notifyListeners() vergessen**
- Symptom: UI aktualisiert sich nicht nach Datenänderung
- Lösung: Rufe IMMER `notifyListeners()` am Ende jeder Methode im ViewModel auf

**❌ Fehler 4: Null-Werte nicht behandelt**
- Symptom: "Null check operator used on null value" Fehler
- Lösung: Prüfe IMMER `if (viewModel.sleepRecord != null)` bevor du darauf zugreifst
- Oder nutze `viewModel.hasData`

**❌ Fehler 5: fromDatabase vs fromJson verwechselt**
- Symptom: DateTime Parsing Fehler
- Lösung: Im DataSource IMMER `fromDatabase()` nutzen, NIEMALS `fromJson()`
- SQLite speichert Dates als Strings, müssen mit `DatabaseDateUtils` konvertiert werden

**❌ Fehler 6: DatabaseHelper nicht initialisiert**
- Symptom: "database is null" Fehler
- Lösung: Stelle sicher, dass `DatabaseHelper.instance.database` in main.dart aufgerufen wird
- Sollte schon von Phase 2 funktionieren

## Benötigst du Hilfe?

- **Vergleiche mit Action Center:** Gleiche Struktur, nur andere Daten!
- **Prüfe PHASE_3.md:** Technische Details und Datenbank-Schema
- **DatabaseDateUtils:** Beispiele in `action_local_datasource.dart`
- **Provider Pattern:** Beispiele in `action_screen.dart` und `main.dart`

## Was haben wir erreicht?

Nach dieser Implementierung hast du:

✅ Ein ViewModel, das alle Logik verwaltet
✅ Einen StatelessWidget Screen, der nur anzeigt
✅ Automatische UI-Updates durch Provider
✅ Saubere Trennung von Anzeige und Logik
✅ Testbaren Code (ViewModel kann ohne UI getestet werden)
✅ Datum-Navigation mit Kalender
✅ Subjektive Bewertungs-Funktion
✅ Vergleich mit persönlichem Durchschnitt
✅ Fehlerbehandlung und Lade-Zustände

**Das gleiche Muster kannst du jetzt für JEDE andere Funktion verwenden!**

## Zusammenfassung: Was ist schon fertig vs. was musst du machen?

### ✅ Bereits in Phase 3 implementiert (FERTIG!): **COMPLETED**

**Datenbank & Migration:**
- ✅ Migration V3 mit sleep_records und user_sleep_baselines Tabellen
- ✅ Database version auf 3 aktualisiert
- ✅ Alle DatabaseConstants für Sleep Records definiert

**Domain Models (komplett fertig):**
- ✅ `SleepRecord` - Mit allen Feldern inkl. `avgHeartRateVariability`
  - ✅ fromDatabase/toDatabase Methoden
  - ✅ Berechnete Properties: `sleepEfficiency`, `timeInBed`
- ✅ `SleepBaseline` - Für persönliche Durchschnitte
  - ✅ fromDatabase/toDatabase Methoden
- ✅ `SleepComparison` - DTO mit Helper-Methoden
  - ✅ `isAboveAverage(metricName)`
  - ✅ `getDifferenceText(metricName, unit)`
  - ✅ `getPercentageDifference(metricName)`
  - ✅ `calculate()` Factory-Methode

**Repository Pattern (komplett fertig):**
- ✅ `SleepRecordRepository` Interface mit allen Methoden
- ✅ `SleepRecordLocalDataSource` - SQLite Operationen
- ✅ `SleepRecordRepositoryImpl` - Implementierung
- ✅ Provider in main.dart registriert (DataSource + Repository)

**Fertige Repository-Methoden die du nutzen kannst:**
- ✅ `getRecordForDate(userId, date)`
- ✅ `getRecordsBetween(userId, start, end)`
- ✅ `getRecentRecords(userId, days)`
- ✅ `saveRecord(record)`
- ✅ `updateQualityRating(recordId, rating, notes)`
- ✅ `getBaselines(userId, baselineType)`
- ✅ `getBaselineValue(userId, baselineType, metricName)`

### 📋 Was DU noch implementieren musst (UI Layer): ❌ NOT IMPLEMENTED

**Presentation Layer:**
- ❌ `NightReviewViewModel` erstellen
  - State-Management
  - Logik für Datum-Navigation
  - Daten laden via Repository
  - Quality Rating speichern
- ❌ `NightScreen` refactoren
  - Von StatefulWidget zu StatelessWidget
  - Provider-Integration
  - ViewModel anbinden
- ❌ `QualityRatingWidget` erstellen
  - 3-Button UI (schlecht/durchschnitt/gut)
  - Callback für Rating-Auswahl

**UI-Verbindungen:**
- ❌ DateNavigationHeader mit ViewModel verbinden
- ❌ ExpandableCalendar mit ViewModel verbinden
- ❌ Schlafdaten-Anzeige mit viewModel.sleepRecord
- ❌ Vergleichs-Anzeige mit viewModel.comparison

**Wichtig:** Du musst KEINE Datenbank-Queries schreiben! Nutze einfach die fertigen Repository-Methoden.

## Nächste Schritte

Nach Night Review UI:
- **Phase 4:** Settings & User Profile Data Layer (gleiches Muster wie Phase 3!)
- Dann: Settings UI mit MVVM-Muster
- Ersetze `'hardcoded-user-id'` mit echtem User aus Settings
- Verknüpfe alles miteinander

**Du bist auf dem besten Weg, ein Flutter MVVM Profi zu werden! 🚀**