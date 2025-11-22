# Habits Lab Implementierungs-Review

Liebe Tabita,

vielen Dank für deine Arbeit an der Habits Lab Implementierung! Die UI sieht visuell sehr ansprechend aus (genauso hab ich es mir vorgestellt) und die grundlegende Funktionalität mit den Checkboxen ist schon vorhanden. Da das Light-Modul erst kürzlich hinzugefügt wurde, ist es völlig nachvollziehbar, dass die vollständige Integration mit dem Provider-Pattern und der bestehenden Architektur noch aussteht.

## Was du bereits sehr gut umgesetzt hast:

### UI/UX Aspekte
- **Schönes, modernes Design**: Die Card-basierte Liste mit Emojis, Titeln und Settings-Button sieht professionell aus und ist benutzerfreundlich
- **Scrollbare Liste**: Deine Implementierung mit `Scrollbar` und `ListView.separated` funktioniert einwandfrei
- **Checkbox-Interaktion**: Der State-Management für die Checkboxen funktioniert korrekt mit `setState()`
- **Visuelles Feedback**: Die Settings-Dialog-Integration zeigt, dass du an die User Experience gedacht hast
- **Konsistentes Styling**: Die Verwendung von `BackgroundWrapper` und das einheitliche Farbschema passen gut zur App

### Code-Qualität
- **Saubere Widget-Struktur**: Die Trennung in `HabitsScreen`, `_SimpleModulesList` und `_GearButton` ist gut organisiert
- **Lokales State Management**: Der Einsatz von `StatefulWidget` für die Liste ist hier sinnvoll
- **Dokumentation**: Die Kommentare machen den Code gut verständlich

## Was noch zu tun ist - Schrittweise Anleitung

Um die Implementierung mit der vorhandenen Architektur zu vervollständigen, sind folgende Schritte notwendig: (bitte auchdie ensprechenden *.md files im lib/features/habits_lab folder durchlesen)

### 1. ViewModel erstellen (Höchste Priorität)

**Erstelle eine neue Datei:**
`lib/features/habits_lab/presentation/viewmodels/habits_viewmodel.dart`

**Das ViewModel sollte:**
- Von `ChangeNotifier` erben (wie `ActionViewModel` und `LightModuleViewModel`)
- Das `ModuleConfigRepository` injiziert bekommen
- Folgende State-Variablen enthalten:
  - `List<ModuleMetadata> _availableModules` - Alle verfügbaren Module aus `module_metadata.dart`
  - `List<UserModuleConfig> _userConfigs` - Die aktiven Konfigurationen des Users
  - `bool _isLoading` - Ladezustand
  - `String? _errorMessage` - Fehlermeldungen

**Wichtige Methoden:**
```dart
Future<void> loadModules(String userId)  // Load all modules and user configs
Future<void> toggleModule(String userId, String moduleId)  // Activate/deactivate modules
bool isModuleActive(String moduleId)  // Check if module is active
```

**Referenz:** Schau dir `lib/features/action_center/presentation/viewmodels/action_viewmodel.dart` an - die Struktur ist sehr ähnlich!

### 2. Module-Metadaten verwenden

**Aktuell:** Die Module-Liste ist hardcodiert im Widget
**Ziel:** Nutze die zentrale `module_metadata.dart`

**Änderungen in `habits_screen.dart`:**
```dart
import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';

// Statt der hardcodierten _Module Liste:
final modules = viewModel.availableModules; // Kommt aus dem ViewModel

// Für jedes Modul die Metadaten nutzen:
final metadata = getModuleMetadata(module.id);
Text(metadata.displayName)  // Statt hardcodiertem Title
Icon(metadata.icon)  // Statt Emoji
Container(color: metadata.primaryColor)  // Für visuelles Feedback
```

**Vorteil:** Alle Module-Informationen (Namen, Icons, Farben) sind zentral definiert und werden automatisch konsistent in der ganzen App verwendet!

### 3. Provider-Integration

**Das Widget muss in zwei Teile aufgeteilt werden:**

**Teil 1: `HabitsScreen` (StatelessWidget)**
```dart
class HabitsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitsViewModel(
        repository: context.read<ModuleConfigRepository>(),
      )..loadModules(userId),
      child: _HabitsScreenContent(),
    );
  }
}
```

**Teil 2: `_HabitsScreenContent` (StatelessWidget)**
- Nutzt `context.watch<HabitsViewModel>()` um auf State-Änderungen zu reagieren
- Ersetzt den lokalen `_active` State durch `viewModel.isModuleActive(moduleId)`
- Ruft `viewModel.toggleModule(userId, moduleId)` beim Checkbox-Tap auf

**Referenz:** Das gleiche Pattern findest du bei `ActionViewModel` - dort wird es genauso gemacht!

### 4. Datenbank-Persistierung

**Aktuell:** Die Checkbox-States werden nur im Speicher gehalten (gehen bei App-Neustart verloren)
**Ziel:** Speichern in der `user_module_configurations` Tabelle

**Das ViewModel übernimmt:**
- Beim `toggleModule()`: Aufruf von `repository.setModuleEnabled(userId, moduleId, isActive)`
- Beim `loadModules()`: Laden der gespeicherten Configs aus der Datenbank
- Die UI aktualisiert sich automatisch durch `notifyListeners()`

**Wichtig:** Das `ModuleConfigRepository` existiert bereits! Du musst es nur noch nutzen.

### 5. Error Handling & Loading States

**Füge hinzu:**
```dart
// Im Widget:
if (viewModel.isLoading) {
  return Center(child: CircularProgressIndicator());
}

if (viewModel.errorMessage != null) {
  return Center(
    child: Column(
      children: [
        Text(viewModel.errorMessage!),
        ElevatedButton(
          onPressed: () => viewModel.loadModules(userId),
          child: Text('Erneut versuchen'),
        ),
      ],
    ),
  );
}
```

**Pattern:** Siehe `LightModuleViewModel` - dort ist das Error Handling vorbildlich implementiert!

### 6. Integration mit Action Center (Optional, aber wichtig!)

Sobald die Module-Konfiguration funktioniert, sollte das Action Center nur noch die **aktiven** Module anzeigen:

**In `ActionViewModel`:**
- Beim Laden der verfügbaren Module: `await moduleConfigRepository.getActiveModuleIds(userId)`
- Filter die angezeigten Module basierend auf dieser Liste

**Effekt:** User aktiviert Modul in Habits Lab → erscheint sofort im Action Center!

### 7. Settings-Integration (Niedrige Priorität)

Der Settings-Button bei jedem Modul ist schon da - super!

**Später kann dieser:**
- Den modul-spezifischen Konfigurations-Screen öffnen (z.B. `LightConfigStandardScreen`)
- Über `ModuleRegistry.getModule(moduleId).getConfigurationScreen()` aufgerufen werden

**Hinweis:** Das ist ein fortgeschrittenes Feature - erstmal auf die Basis-Funktionalität konzentrieren!

## Empfohlene Implementierungs-Reihenfolge

1. **ViewModel erstellen** (1-2 Stunden)
   - Datei anlegen, Struktur von `ActionViewModel` kopieren
   - State-Variablen definieren
   - `loadModules()` und `toggleModule()` implementieren

2. **Provider-Integration** (30 Minuten)
   - Widget in zwei Teile aufteilen
   - `ChangeNotifierProvider` einbauen
   - `context.watch()` statt lokalem State

3. **Module-Metadaten nutzen** (30 Minuten)
   - Hardcodierte Liste entfernen
   - `getAvailableModules()` verwenden
   - Icons und Farben aus Metadaten

4. **Testen** (30 Minuten)
   - Module aktivieren/deaktivieren
   - App neu starten → State sollte erhalten bleiben
   - Fehlerbehandlung testen

5. **Action Center Integration** (Optional, 15 Minuten)
   - Filter-Logik im `ActionViewModel` einbauen

## Hilfreiche Dateien zum Nachschauen

- **ViewModel-Beispiel:** `lib/features/action_center/presentation/viewmodels/action_viewmodel.dart`
- **Light Module ViewModel:** `lib/modules/light/presentation/viewmodels/light_module_viewmodel.dart`
- **Module-Metadaten:** `lib/modules/shared/constants/module_metadata.dart`
- **Repository-Interface:** `lib/modules/shared/domain/repositories/module_config_repository.dart`
- **Implementierungsplan:** `lib/features/habits_lab/HABITS_LAB_IMPLEMENTATION_PLAN.md`

## Wichtiger Hinweis zu Code-Kommentaren

**Bitte beachte:** Alle Code-Kommentare sollten auf **Englisch** verfasst werden, um die Konsistenz mit dem Rest der Codebase zu wahren. Deutsche Kommentare sind nur in Markdown-Dokumentationen (wie dieser hier) oder bei schnellen Notizen während der Entwicklung okay. Grundsätzlich gilt: Code ist immer Englisch zu halten.

## Fazit

Du hast eine solide UI-Grundlage geschaffen, die sich sehr gut anfühlt und aussieht! Der nächste Schritt ist die Integration mit der bestehenden Architektur durch das ViewModel-Pattern. Das mag auf den ersten Blick etwas komplex erscheinen, aber die gute Nachricht ist: Es gibt bereits mehrere funktionierende Beispiele im Codebase (`ActionViewModel`, `LightModuleViewModel`), die als Vorlage dienen können.

Die Hauptaufgabe besteht darin, den lokalen State (`_active` Set) durch das ViewModel zu ersetzen und die Datenbank-Persistierung über das `ModuleConfigRepository` einzubinden. Sobald das steht, ist die Habits Lab Funktion vollständig und bereit für die Integration mit allen zukünftigen Modulen!

**Geschätzter Aufwand:** 3-4 Stunden für die vollständige Integration

**Schwierigkeitsgrad:** Mittel (mit den vorhandenen Beispielen als Referenz gut machbar!)

Bei Fragen oder Unklarheiten kannst du dich jederzeit melden. Viel Erfolg bei der Implementierung!

---

**Erstellt am:** 2025-11-16
**Review von:** Veit