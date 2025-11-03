# Meditation & Relaxation Module - Implementation Plan

## Overview
Implement the Meditation Module to guide users in establishing calming pre-sleep routines through meditation, breathwork, and relaxation techniques. Regular practice reduces sleep onset time and improves sleep quality.

**Core Principle:** Mental relaxation prepares the body for sleep. Evening meditation activates the parasympathetic nervous system, reduces cortisol, and creates ideal conditions for restful sleep.

## Prerequisites
- ✅ **Previous modules completed:** Pattern established
- ✅ **Audio system:** Flutter audio player package integrated
- 📚 **Read:** MEDITATION_README.md

## Goals
- Create meditation content library system
- Implement audio playback with session tracking
- Build meditation picker UI with filters (duration, technique, teacher)
- Track session completion and duration
- Support offline playback (downloaded sessions)
- **Expected outcome:** Meditation module with audio library fully functional

---

## Step M.1: Database Migration - Meditation Content Library

**File:** `lib/core/database/migrations/migration_v8.dart`

**SQL Migration:**
```sql
-- Meditation content library
CREATE TABLE IF NOT EXISTS meditation_sessions (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  teacher_name TEXT,
  duration_minutes INTEGER NOT NULL,
  technique_type TEXT NOT NULL,  -- 'guided', 'body_scan', 'breathing', 'visualization', etc.
  difficulty_level TEXT,          -- 'beginner', 'intermediate', 'advanced'
  audio_url TEXT NOT NULL,        -- Remote URL or local path
  is_downloaded INTEGER DEFAULT 0,-- Boolean: is audio file cached locally
  background_sound TEXT,          -- 'none', 'rain', 'ocean', 'forest', etc.
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- User favorites
CREATE TABLE IF NOT EXISTS meditation_favorites (
  user_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  favorited_at TEXT NOT NULL,
  PRIMARY KEY (user_id, session_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (session_id) REFERENCES meditation_sessions(id)
);

-- Play history
CREATE TABLE IF NOT EXISTS meditation_play_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  played_at TEXT NOT NULL,
  completed INTEGER DEFAULT 0,     -- Boolean: did user finish session
  duration_listened_minutes INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (session_id) REFERENCES meditation_sessions(id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_meditation_technique ON meditation_sessions(technique_type, duration_minutes);
CREATE INDEX IF NOT EXISTS idx_meditation_favorites ON meditation_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_meditation_history ON meditation_play_history(user_id, played_at);

-- Index for meditation activities
CREATE INDEX IF NOT EXISTS idx_intervention_activities_meditation
ON intervention_activities(user_id, module_id, activity_date)
WHERE module_id = 'meditation';
```

**Why:** Separate table for meditation content library, supports filtering and favorites

---

## Step M.2: Meditation Session Content Model

**File:** `lib/modules/meditation/domain/models/meditation_session_content.dart`

**Class: MeditationSessionContent**

**Fields:**
```dart
class MeditationSessionContent {
  final String id;
  final String title;
  final String? description;
  final String? teacherName;
  final int durationMinutes;
  final String techniqueType;        // 'guided', 'body_scan', 'breathing', 'visualization', 'loving_kindness', 'yoga_nidra'
  final String? difficultyLevel;     // 'beginner', 'intermediate', 'advanced'
  final String audioUrl;             // Remote or local path
  final bool isDownloaded;
  final String? backgroundSound;     // 'none', 'rain', 'ocean', 'forest', 'white_noise'
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Methods:**
- Constructor, fromJson, toJson, fromDatabase, toDatabase
- `bool get isLocal => audioUrl.startsWith('file://') || audioUrl.startsWith('/');`
- `String get displayDuration => '$durationMinutes min';`

---

## Step M.3: Meditation Configuration Model

**File:** `lib/modules/meditation/domain/models/meditation_config.dart`

**Class: MeditationConfig**

**Fields:**
```dart
class MeditationConfig {
  // Standard mode: Single evening session
  final String targetTime;              // HH:mm - 30-60 min before bed
  final int preferredDurationMinutes;   // Default: 10
  final String preferredTechnique;      // User's favorite technique

  // Advanced mode: Multiple sessions
  final List<MeditationScheduledSession> sessions;

  // Playback preferences
  final double playbackSpeed;           // 0.8x - 1.2x
  final bool showTranscripts;           // For hearing impaired
  final String preferredBackgroundSound;// Default background sound

  // Notification settings
  final bool sessionReminderEnabled;
  final int reminderMinutesBefore;

  final String mode;
}

class MeditationScheduledSession {
  final String id;
  final String sessionTime;
  final String techniquePreference;     // Filter library by this
  final int targetDurationMinutes;
  final bool isEnabled;
}
```

**Static Defaults:**
```dart
static MeditationConfig get standardDefault => MeditationConfig(
  targetTime: '21:30',  // 30 min before typical 22:00 bed time
  preferredDurationMinutes: 10,
  preferredTechnique: 'guided',
  playbackSpeed: 1.0,
  showTranscripts: false,
  preferredBackgroundSound: 'none',
  mode: 'standard',
);
```

---

## Step M.4: Meditation Activity Model

**File:** `lib/modules/meditation/domain/models/meditation_activity.dart`

**Class: MeditationActivity extends InterventionActivity**

**Module-Specific Data (JSON):**
```dart
{
  'session_content_id': string?,      // ID of MeditationSessionContent used
  'session_title': string,
  'technique_type': string,
  'teacher_name': string?,
  'playback_speed': double,
  'background_sound': string?,
  'duration_listened_minutes': int,   // Actual vs planned
  'completed_full_session': bool,     // Did they finish?
  'stress_before': int?,              // 1-10 scale
  'stress_after': int?,               // 1-10 scale
}
```

**Getters:**
```dart
String? get sessionContentId => moduleSpecificData?['session_content_id'];
String get sessionTitle => moduleSpecificData?['session_title'] ?? 'Unknown';
String get techniqueType => moduleSpecificData?['technique_type'] ?? 'unknown';
int? get durationListened => moduleSpecificData?['duration_listened_minutes'];
bool get completedFullSession => moduleSpecificData?['completed_full_session'] ?? false;
int? get stressBefore => moduleSpecificData?['stress_before'];
int? get stressAfter => moduleSpecificData?['stress_after'];

// Calculate stress reduction
int? get stressReduction {
  if (stressBefore != null && stressAfter != null) {
    return stressBefore! - stressAfter!;
  }
  return null;
}
```

---

## Step M.5: Meditation Repository Interface

**File:** `lib/modules/meditation/domain/repositories/meditation_repository.dart`

**Import & Interface:**
```dart
import '../../../shared/domain/repositories/intervention_repository.dart';
import '../models/meditation_activity.dart';
import '../models/meditation_session_content.dart';

/// Meditation repository interface
/// Extends InterventionRepository with content library and favorites management
abstract class MeditationRepository extends InterventionRepository {
  // Content library - getAllSessions, getSessionsByTechnique, getSessionsByDuration, getFavorites, getRecentlyPlayed
  Future<List<MeditationSessionContent>> getAllSessions();
  Future<List<MeditationSessionContent>> getSessionsByTechnique(String technique);
  Future<List<MeditationSessionContent>> getSessionsByDuration(int minMinutes, int maxMinutes);
  Future<List<MeditationSessionContent>> getUserFavorites(String userId);
  Future<void> addFavorite(String userId, String sessionId);
  Future<void> removeFavorite(String userId, String sessionId);
  Future<List<MeditationSessionContent>> getRecentlyPlayed(String userId, int limit);
}
```

**Inherited from base:** `getUserConfig`, `saveConfig`, `getActivitiesForDate`, `getActivitiesBetween`, `logActivity`, `updateActivity`, `deleteActivity`, `getCompletionCount`, `getCompletionRate`

---

## Step M.6: Audio Player Service

**File:** `lib/modules/meditation/domain/services/meditation_audio_service.dart`

**Abstract Class: MeditationAudioService**

**Purpose:** Abstraction over audio player (just_audio package)

**Methods:**
```dart
abstract class MeditationAudioService {
  /// Initialize audio player
  Future<void> initialize();

  /// Load meditation session audio
  Future<void> loadSession(MeditationSessionContent session);

  /// Play/pause/stop controls
  Future<void> play();
  Future<void> pause();
  Future<void> stop();

  /// Seek to position
  Future<void> seek(Duration position);

  /// Set playback speed (0.8x - 1.2x)
  Future<void> setSpeed(double speed);

  /// Listen to player state
  Stream<PlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  /// Clean up resources
  Future<void> dispose();
}

enum PlayerState {
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}
```

**Implementation:** Uses `just_audio` package (or similar)

---

## Step M.7: Meditation ViewModel with Playback State

**File:** `lib/modules/meditation/presentation/viewmodels/meditation_module_viewmodel.dart`

**Class: MeditationModuleViewModel extends ChangeNotifier**

**Fields (beyond standard):**
```dart
// Content library
List<MeditationSessionContent> _allSessions = [];
List<MeditationSessionContent> _filteredSessions = [];
List<MeditationSessionContent> _favorites = [];
List<MeditationSessionContent> _recentlyPlayed = [];

// Current playback
MeditationSessionContent? _currentSession;
PlayerState _playerState = PlayerState.ready;
Duration _currentPosition = Duration.zero;
Duration? _totalDuration;
double _playbackSpeed = 1.0;

// Filters
String? _techniqueFilter;
int? _maxDurationFilter;
String? _teacherFilter;
```

**Playback Methods:**
```dart
Future<void> playSession(String userId, MeditationSessionContent session) async {
  try {
    _isLoading = true;
    notifyListeners();

    _currentSession = session;
    await _audioService.loadSession(session);
    await _audioService.setSpeed(_playbackSpeed);
    await _audioService.play();

    // Record start in play history
    _playStartTime = DateTime.now();

  } catch (e) {
    _errorMessage = 'Failed to play session: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> pauseSession() async {
  await _audioService.pause();
  notifyListeners();
}

Future<void> stopSession(String userId, {bool completed = false}) async {
  if (_currentSession == null) return;

  // Calculate actual duration listened
  final durationListened = _currentPosition.inMinutes;

  // Record in play history
  await _contentRepository.recordPlaySession(
    userId,
    _currentSession!.id,
    durationListened,
    completed,
  );

  // Create intervention activity if completed or >5 min
  if (completed || durationListened >= 5) {
    final activity = MeditationActivity(
      id: _generateUuid(),
      userId: userId,
      activityDate: DateTime.now(),
      wasCompleted: completed,
      completedAt: DateTime.now(),
      durationMinutes: durationListened,
      timeOfDay: _getTimeOfDay(DateTime.now()),
      sessionContentId: _currentSession!.id,
      sessionTitle: _currentSession!.title,
      techniqueType: _currentSession!.techniqueType,
      teacherName: _currentSession!.teacherName,
      playbackSpeed: _playbackSpeed,
      durationListened: durationListened,
      completedFullSession: completed,
    );

    await _repository.logActivity(activity);
  }

  await _audioService.stop();
  _currentSession = null;
  _currentPosition = Duration.zero;
  notifyListeners();
}

void _listenToPlayerState() {
  _audioService.playerStateStream.listen((state) {
    _playerState = state;
    notifyListeners();

    // Auto-complete when session finishes
    if (state == PlayerState.completed && _currentSession != null) {
      stopSession(_currentUserId, completed: true);
    }
  });

  _audioService.positionStream.listen((position) {
    _currentPosition = position;
    notifyListeners();
  });

  _audioService.durationStream.listen((duration) {
    _totalDuration = duration;
    notifyListeners();
  });
}
```

**Library Methods:**
```dart
Future<void> loadLibrary(String userId) async {
  try {
    _isLoading = true;
    notifyListeners();

    _allSessions = await _contentRepository.getAllSessions();
    _favorites = await _contentRepository.getUserFavorites(userId);
    _recentlyPlayed = await _contentRepository.getRecentlyPlayed(userId, 10);

    _applyFilters();

  } catch (e) {
    _errorMessage = 'Failed to load library: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

void applyFilter({String? technique, int? maxDuration, String? teacher}) {
  _techniqueFilter = technique;
  _maxDurationFilter = maxDuration;
  _teacherFilter = teacher;
  _applyFilters();
  notifyListeners();
}

void _applyFilters() {
  _filteredSessions = _allSessions.where((session) {
    if (_techniqueFilter != null && session.techniqueType != _techniqueFilter) {
      return false;
    }
    if (_maxDurationFilter != null && session.durationMinutes > _maxDurationFilter!) {
      return false;
    }
    if (_teacherFilter != null && session.teacherName != _teacherFilter) {
      return false;
    }
    return true;
  }).toList();
}
```

---

## Step M.8: Meditation Player Screen

**File:** `lib/modules/meditation/presentation/screens/meditation_player_screen.dart`

**Purpose:** Audio player UI with controls

**UI Components:**
```dart
// Session info
Text(currentSession.title, style: Theme.of(context).textTheme.headlineSmall),
Text('by ${currentSession.teacherName}'),

// Progress bar
Slider(
  value: currentPosition.inSeconds.toDouble(),
  max: totalDuration?.inSeconds.toDouble() ?? 1.0,
  onChanged: (value) {
    viewModel.seek(Duration(seconds: value.toInt()));
  },
),

// Time display
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(_formatDuration(currentPosition)),
    Text(_formatDuration(totalDuration)),
  ],
),

// Playback controls
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // Skip back 15s
    IconButton(
      icon: Icon(Icons.replay_15),
      onPressed: () {
        final newPos = currentPosition - Duration(seconds: 15);
        viewModel.seek(newPos > Duration.zero ? newPos : Duration.zero);
      },
    ),

    // Play/Pause
    IconButton(
      iconSize: 64,
      icon: Icon(
        playerState == PlayerState.playing ? Icons.pause_circle : Icons.play_circle,
      ),
      onPressed: () {
        if (playerState == PlayerState.playing) {
          viewModel.pauseSession();
        } else {
          viewModel.resumeSession();
        }
      },
    ),

    // Skip forward 15s
    IconButton(
      icon: Icon(Icons.forward_15),
      onPressed: () {
        final newPos = currentPosition + Duration(seconds: 15);
        if (totalDuration != null && newPos < totalDuration!) {
          viewModel.seek(newPos);
        }
      },
    ),
  ],
),

// Playback speed control
DropdownButton<double>(
  value: playbackSpeed,
  items: [0.8, 0.9, 1.0, 1.1, 1.2].map((speed) {
    return DropdownMenuItem(value: speed, child: Text('${speed}x'));
  }).toList(),
  onChanged: (speed) {
    viewModel.setPlaybackSpeed(speed!);
  },
),

// Stop button
TextButton(
  onPressed: () {
    viewModel.stopSession(userId, completed: false);
    Navigator.pop(context);
  },
  child: Text('Stop Session'),
),
```

---

## Step M.9: Meditation Library Screen

**File:** `lib/modules/meditation/presentation/screens/meditation_library_screen.dart`

**Purpose:** Browse and filter meditation content

**UI Components:**
```dart
// Filter chips
Wrap(
  spacing: 8,
  children: [
    FilterChip(
      label: Text('Guided'),
      selected: techniqueFilter == 'guided',
      onSelected: (selected) {
        viewModel.applyFilter(technique: selected ? 'guided' : null);
      },
    ),
    FilterChip(
      label: Text('Body Scan'),
      selected: techniqueFilter == 'body_scan',
      onSelected: (selected) {
        viewModel.applyFilter(technique: selected ? 'body_scan' : null);
      },
    ),
    // ... more technique filters
  ],
),

// Duration filter
DropdownButton<int?>(
  hint: Text('Max Duration'),
  value: maxDurationFilter,
  items: [
    DropdownMenuItem(value: null, child: Text('Any')),
    DropdownMenuItem(value: 5, child: Text('5 min or less')),
    DropdownMenuItem(value: 10, child: Text('10 min or less')),
    DropdownMenuItem(value: 20, child: Text('20 min or less')),
  ],
  onChanged: (value) {
    viewModel.applyFilter(maxDuration: value);
  },
),

// Session list
ListView.builder(
  itemCount: filteredSessions.length,
  itemBuilder: (context, index) {
    final session = filteredSessions[index];
    return SessionCard(
      session: session,
      isFavorite: viewModel.isFavorite(session.id),
      onPlay: () {
        viewModel.playSession(userId, session);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: viewModel,
              child: MeditationPlayerScreen(),
            ),
          ),
        );
      },
      onFavorite: () {
        viewModel.toggleFavorite(userId, session.id);
      },
    );
  },
),
```

---

## Testing Checklist

### Manual Tests:
- [ ] Load meditation library, verify sessions appear
- [ ] Filter by technique, verify correct sessions shown
- [ ] Filter by duration, verify max duration respected
- [ ] Add session to favorites, verify persists after app restart
- [ ] Play session, verify audio starts
- [ ] Pause/resume session, verify position maintained
- [ ] Skip forward/backward 15s, verify correct position
- [ ] Change playback speed, verify audio speed changes
- [ ] Complete full session, verify activity logged
- [ ] Stop session midway (>5 min), verify partial activity logged
- [ ] View recently played, verify history shown

### Integration Tests:
- [ ] Play session → complete → check database for activity
- [ ] Play session → stop midway → check duration_listened accurate
- [ ] Favorite session → close app → reopen → verify still favorited

### Database Tests:
```sql
-- Check meditation activities
SELECT
  activity_date,
  module_specific_data->>'session_title' as title,
  module_specific_data->>'technique_type' as technique,
  duration_minutes,
  module_specific_data->>'completed_full_session' as completed
FROM intervention_activities
WHERE module_id = 'meditation'
ORDER BY activity_date DESC;

-- Check stress reduction
SELECT
  activity_date,
  module_specific_data->>'stress_before' as before,
  module_specific_data->>'stress_after' as after,
  CAST(module_specific_data->>'stress_before' AS INTEGER) - CAST(module_specific_data->>'stress_after' AS INTEGER) as reduction
FROM intervention_activities
WHERE module_id = 'meditation'
  AND module_specific_data->>'stress_before' IS NOT NULL
  AND module_specific_data->>'stress_after' IS NOT NULL;
```

---

## Notes

**Meditation Module Uniqueness:**
- First module with content library (separate table for meditation sessions)
- Audio playback integration (requires audio player package)
- Favorites and play history tracking
- Offline support (downloaded sessions)
- Stress tracking (before/after ratings)

**Audio Player Integration:**
- Use `just_audio` package (recommended for Flutter)
- Supports playback speed control
- Stream-based position/duration updates
- Background playback support (future enhancement)

**Content Library Strategy:**
- Phase 1: Hardcoded/seeded meditation sessions in migration
- Phase 2: Load from backend API (future)
- Phase 3: User-generated/uploaded content (future)

**Estimated Time:** 16-18 hours
- Database migration with content library: 60 minutes
- Models (Content + Config + Activity): 90 minutes
- Content repository: 90 minutes
- Audio service integration: 180 minutes
- Repository + Datasource: 90 minutes
- ViewModel with playback state: 180 minutes
- Player screen: 120 minutes
- Library screen: 90 minutes
- Testing: 90 minutes
