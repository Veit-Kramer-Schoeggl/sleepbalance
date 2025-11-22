# Habits Lab - Verbleibende Aufgaben

## Aktueller Stand

Die MVVM-Architektur, das ViewModel, die Provider-Integration, die ModuleMetadata-Nutzung und die UI sind korrekt implementiert. Der Screen sieht gut aus und folgt der geplanten Architektur.

## Problem: "Cannot enable/disable non-existent module config"

Beim Aktivieren eines Moduls wirft das Repository einen Fehler, weil noch kein `UserModuleConfig`-Eintrag für den User existiert.

**Ursache:** Die Methode `setModuleEnabled()` im `ModuleConfigRepository` erwartet, dass bereits eine Konfiguration existiert, bevor sie aktualisiert werden kann.

**Lösung:** Das Repository muss eine "Upsert"-Logik bekommen - wenn keine Config existiert, soll eine neue erstellt werden statt einen Fehler zu werfen.

---

## Verbleibende Aufgaben

### 1. Repository Upsert-Logik fixen (Hohe Priorität)

**Wo:** `lib/modules/shared/data/repositories/module_config_repository_impl.dart`

**Was zu tun ist:** Die Methode `setModuleEnabled(userId, moduleId, isEnabled)` muss angepasst werden:

1. Zuerst prüfen ob eine Config für diesen User und dieses Modul existiert (via `getModuleConfig`)
2. Falls ja: Die bestehende Config aktualisieren (wie bisher)
3. Falls nein: Eine neue `UserModuleConfig` erstellen mit:
   - Generierte UUID als `id`
   - Die übergebene `userId` und `moduleId`
   - `isEnabled` auf den gewünschten Wert setzen
   - `enrolledAt` und `updatedAt` auf aktuelle Zeit
   - Leere `configuration` Map (Default-Werte)

**Zusammenhang:** Das `HabitsViewModel` ruft `repository.setModuleEnabled()` auf wenn der User eine Checkbox togglet. Nach dem Fix wird automatisch eine Config erstellt wenn noch keine existiert.

---

### 2. Action Center Integration (Mittlere Priorität)

**Wo:** `lib/features/action_center/presentation/viewmodels/action_viewmodel.dart`

**Was zu tun ist:** Das Action Center soll nur Module anzeigen, die im Habits Lab aktiviert sind.

**Ablauf der Integration:**

1. Das `ActionViewModel` benötigt Zugriff auf das `ModuleConfigRepository` (als Dependency im Konstruktor)

2. In der Methode die Module lädt (vermutlich `loadActions` oder ähnlich):
   - Zuerst `repository.getActiveModuleIds(userId)` aufrufen
   - Das gibt eine Liste der aktivierten Modul-IDs zurück (z.B. `['light', 'sport']`)
   - Die angezeigten Module basierend auf dieser Liste filtern

3. Nur Module anzeigen, deren ID in der aktiven Liste enthalten ist

**Zusammenhang mit Habits Lab:**
- User aktiviert "Light Therapy" im Habits Lab → `setModuleEnabled('light', true)` wird aufgerufen
- User öffnet Action Center → `getActiveModuleIds()` gibt `['light']` zurück
- Action Center zeigt nur Light Therapy an
- User deaktiviert im Habits Lab → Action Center zeigt es nicht mehr

---

### 3. Echte User ID (Niedrige Priorität)

**Wo:** `lib/features/habits_lab/presentation/screens/habits_screen.dart` (Zeile 35)

**Was zu tun ist:** Die hardcodierte `'demo-user'` ID durch die echte User ID ersetzen.

**Wie:** Sobald ein Auth-System oder User-Profil existiert, die ID von dort holen:

Über SettingsViewModel (empfohlen für UI)

final settingsViewModel = context.read<SettingsViewModel>();
final userId = settingsViewModel.currentUser?.id;

Wo: SettingsViewModel ist bereits in main.dart als Provider registriert und lädt den aktuellen User automatisch.


---

### 4. Modul Lifecycle Hooks (Zukunft)

**Kontext:** Jedes Modul kann spezielle Aktionen ausführen wenn es aktiviert/deaktiviert wird (z.B. Notifications planen oder löschen).

**Was zu tun ist:** Im `HabitsViewModel` nach dem erfolgreichen `setModuleEnabled()`:
- Bei Aktivierung: `module.onModuleActivated(userId, config)` aufrufen
- Bei Deaktivierung: `module.onModuleDeactivated(userId)` aufrufen

**Voraussetzung:** Der `ModuleRegistry` muss implementiert sein, um die Modul-Implementierung anhand der ID zu bekommen.

---

**Zuletzt aktualisiert:** 2025-11-22
