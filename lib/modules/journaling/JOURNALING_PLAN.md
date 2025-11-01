# Journaling Module - Implementation Plan

## Overview
Implement the Journaling Module for reflective writing, thought processing, and ML-based pattern recognition. Through regular journaling, users identify factors affecting sleep and receive personalized insights.

**Core Principle:** Self-reflection enhances self-awareness and behavioral change. Journaling helps identify patterns, process emotions, reduce bedtime rumination, and make informed decisions about sleep habits.

## Prerequisites
- ✅ **Previous modules completed:** Pattern established
- ✅ **Privacy:** Encryption library for sensitive journal data
- ✅ **ML/NLP:** Pattern recognition service (optional, can defer)
- ✅ **OCR:** Image-to-text service for handwritten journals
- 📚 **Read:** JOURNALING_README.md

## Goals
- Create journal entry storage with encryption
- Implement multiple input methods (text, voice-to-text, photo OCR, document upload)
- Build ML pattern recognition for sleep correlations
- Provide prompt library system
- Track journaling consistency
- **Expected outcome:** Journaling module with privacy-first encrypted storage

---

## Step J.1: Database Migration - Journal Entries

**File:** `lib/core/database/migrations/migration_v9.dart`

**SQL Migration:**
```sql
-- Journal entries (encrypted content)
CREATE TABLE IF NOT EXISTS journal_entries (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  entry_date TEXT NOT NULL,          -- Date of entry
  entry_time TEXT NOT NULL,          -- Time written (HH:mm)
  content_encrypted TEXT NOT NULL,   -- Encrypted journal text
  encryption_iv TEXT NOT NULL,       -- Initialization vector for decryption
  input_method TEXT NOT NULL,        -- 'text', 'voice', 'photo', 'document'
  word_count INTEGER DEFAULT 0,
  character_count INTEGER DEFAULT 0,
  duration_minutes INTEGER,          -- Time spent writing
  prompt_used TEXT,                  -- Which prompt was used, if any
  mood_rating INTEGER,               -- 1-10 scale (optional)
  energy_rating INTEGER,             -- 1-10 scale (optional)
  tags TEXT,                         -- JSON array of tags
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ML-extracted patterns (from journal analysis)
CREATE TABLE IF NOT EXISTS journal_patterns (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  pattern_type TEXT NOT NULL,        -- 'topic', 'sentiment', 'keyword', 'trigger'
  pattern_value TEXT NOT NULL,       -- The actual pattern (e.g., "work stress")
  frequency_count INTEGER DEFAULT 1, -- How many entries mention this
  first_seen_date TEXT NOT NULL,
  last_seen_date TEXT NOT NULL,
  correlation_sleep_quality REAL,    -- -1.0 to 1.0 correlation with sleep
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Journal prompts library
CREATE TABLE IF NOT EXISTS journal_prompts (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,            -- 'sleep', 'gratitude', 'goals', 'processing'
  prompt_text TEXT NOT NULL,
  description TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_date
ON journal_entries(user_id, entry_date DESC);

CREATE INDEX IF NOT EXISTS idx_journal_patterns_user
ON journal_patterns(user_id, pattern_type, frequency_count DESC);

CREATE INDEX IF NOT EXISTS idx_journal_prompts_category
ON journal_prompts(category, is_active);

-- Index for journaling activities
CREATE INDEX IF NOT EXISTS idx_intervention_activities_journaling
ON intervention_activities(user_id, module_id, activity_date)
WHERE module_id = 'journaling';
```

**Why:** Separate table for journal entries with encryption, ML patterns extraction, prompt library

---

## Step J.2: Encryption Service

**File:** `lib/modules/journaling/domain/services/journal_encryption_service.dart`

**Abstract Class: JournalEncryptionService**

**Purpose:** Encrypt/decrypt journal content for privacy

**Methods:**
```dart
abstract class JournalEncryptionService {
  /// Encrypt journal content
  /// Returns: (encryptedContent, initializationVector)
  Future<EncryptedData> encrypt(String plaintext, String userId);

  /// Decrypt journal content
  Future<String> decrypt(String encryptedContent, String iv, String userId);

  /// Generate encryption key from user ID (or stored key)
  Future<String> getEncryptionKey(String userId);
}

class EncryptedData {
  final String encryptedContent;
  final String initializationVector;

  EncryptedData({
    required this.encryptedContent,
    required this.initializationVector,
  });
}
```

**Implementation:** Uses AES-256 encryption with user-specific key derived from user ID + app secret

**Why:** Privacy-first - journal content never stored in plain text

---

## Step J.3: Journal Entry Model

**File:** `lib/modules/journaling/domain/models/journal_entry.dart`

**Class: JournalEntry**

**Fields:**
```dart
class JournalEntry {
  final String id;
  final String userId;
  final DateTime entryDate;
  final TimeOfDay entryTime;
  final String contentEncrypted;       // Encrypted text
  final String encryptionIv;           // For decryption
  final String inputMethod;            // 'text', 'voice', 'photo', 'document'
  final int wordCount;
  final int characterCount;
  final int? durationMinutes;          // Time spent writing
  final String? promptUsed;            // Prompt ID if used
  final int? moodRating;               // 1-10
  final int? energyRating;             // 1-10
  final List<String> tags;             // User-defined tags
  final DateTime createdAt;
  final DateTime updatedAt;

  // Transient field (not stored in DB)
  String? decryptedContent;            // Populated after decryption
}
```

**Methods:**
- Constructor, fromJson, toJson, fromDatabase, toDatabase
- `Future<void> decrypt(JournalEncryptionService encryptionService)` - Decrypts content, populates `decryptedContent`
- `static Future<JournalEntry> create({...required String plainContent, required JournalEncryptionService encryption})` - Encrypts content before creation

**Why:** Stores encrypted content, provides method to decrypt on-demand

---

## Step J.4: Journal Pattern Model

**File:** `lib/modules/journaling/domain/models/journal_pattern.dart`

**Class: JournalPattern**

**Fields:**
```dart
class JournalPattern {
  final String id;
  final String userId;
  final String patternType;            // 'topic', 'sentiment', 'keyword', 'trigger'
  final String patternValue;           // E.g., "work stress", "exercise", "caffeine"
  final int frequencyCount;
  final DateTime firstSeenDate;
  final DateTime lastSeenDate;
  final double? correlationSleepQuality; // -1.0 to 1.0
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Methods:**
- Constructor, fromJson, toJson, fromDatabase, toDatabase
- `String get impactDescription` - Human-readable impact ("Positive impact on sleep", "Negative impact on sleep")

**Why:** Stores ML-extracted patterns for insights

---

## Step J.5: ML Pattern Recognition Service

**File:** `lib/modules/journaling/domain/services/journal_pattern_service.dart`

**Abstract Class: JournalPatternService**

**Purpose:** Analyze journal entries to extract patterns

**Methods:**
```dart
abstract class JournalPatternService {
  /// Analyze journal entry to extract topics, keywords, sentiment
  Future<List<ExtractedPattern>> analyzeEntry(String decryptedContent);

  /// Find correlations between journal patterns and sleep quality
  Future<List<JournalPattern>> correlateWithSleep(
    String userId,
    List<JournalEntry> entries,
    List<SleepRecord> sleepRecords,
  );

  /// Generate insights from patterns
  Future<List<String>> generateInsights(String userId, List<JournalPattern> patterns);
}

class ExtractedPattern {
  final String patternType;
  final String patternValue;
  final double confidence;             // 0.0 to 1.0
}
```

**Phase 1 Implementation:** Basic keyword extraction (defer complex NLP to later)
- Simple keyword matching: "stress", "work", "exercise", "caffeine", "alcohol", etc.
- Sentiment analysis: Positive/negative word counts
- Future: Integration with cloud NLP API or on-device ML model

**Why:** Foundation for ML insights, can start simple and enhance later

---

## Step J.6: OCR Service for Handwritten Journals

**File:** `lib/modules/journaling/domain/services/journal_ocr_service.dart`

**Abstract Class: JournalOCRService**

**Purpose:** Convert handwritten journal photos to text

**Methods:**
```dart
abstract class JournalOCRService {
  /// Check if OCR is available (requires API key or device support)
  Future<bool> isAvailable();

  /// Perform OCR on image
  /// Returns: (extractedText, confidence)
  Future<OCRResult> extractTextFromImage(File imageFile);
}

class OCRResult {
  final String extractedText;
  final double confidence;             // 0.0 to 1.0
  final List<String> warnings;         // E.g., "Low confidence on page 2"

  bool get isReliable => confidence > 0.8;
}
```

**Implementation Options:**
- Google ML Kit (on-device, free)
- Cloud Vision API (more accurate, costs money)
- Phase 1: Placeholder returning "OCR not yet implemented"

**Why:** Supports handwritten journal photos, flexible implementation

---

## Step J.7: Journaling Configuration Model

**File:** `lib/modules/journaling/domain/models/journaling_config.dart`

**Class: JournalingConfig**

**Fields:**
```dart
class JournalingConfig {
  // Standard mode: Evening reflection
  final String targetTime;              // HH:mm - 30-60 min before bed
  final int targetDurationMinutes;      // Default: 10
  final bool usePrompts;                // Default: true
  final String promptCategory;          // Default: 'sleep'

  // Input preferences
  final List<String> enabledInputMethods; // ['text', 'voice', 'photo', 'document']
  final bool enableMLAnalysis;          // Default: true
  final bool showInsights;              // Default: true

  // Privacy settings
  final bool requirePinToView;          // Extra security layer
  final String? pinCode;                // 4-digit PIN (hashed)

  // Notification settings
  final bool reminderEnabled;
  final int reminderMinutesBefore;

  final String mode;
}
```

**Static Defaults:**
```dart
static JournalingConfig get standardDefault => JournalingConfig(
  targetTime: '21:00',
  targetDurationMinutes: 10,
  usePrompts: true,
  promptCategory: 'sleep',
  enabledInputMethods: ['text'],
  enableMLAnalysis: true,
  showInsights: true,
  requirePinToView: false,
  mode: 'standard',
);
```

---

## Step J.8: Journaling Activity Model

**File:** `lib/modules/journaling/domain/models/journaling_activity.dart`

**Class: JournalingActivity extends InterventionActivity**

**Module-Specific Data (JSON):**
```dart
{
  'journal_entry_id': string,
  'input_method': string,
  'word_count': int,
  'character_count': int,
  'prompt_used': string?,
  'mood_before': int?,               // 1-10
  'mood_after': int?,                // 1-10
  'patterns_detected': int,          // Number of patterns extracted
  'insights_generated': int,         // Number of new insights
}
```

**Getters:**
```dart
String get journalEntryId => moduleSpecificData?['journal_entry_id'] ?? '';
String get inputMethod => moduleSpecificData?['input_method'] ?? 'text';
int get wordCount => moduleSpecificData?['word_count'] ?? 0;
int? get moodBefore => moduleSpecificData?['mood_before'];
int? get moodAfter => moduleSpecificData?['mood_after'];

int? get moodImprovement {
  if (moodBefore != null && moodAfter != null) {
    return moodAfter! - moodBefore!;
  }
  return null;
}
```

---

## Step J.9: Journaling ViewModel with Encryption

**File:** `lib/modules/journaling/presentation/viewmodels/journaling_module_viewmodel.dart`

**Class: JournalingModuleViewModel extends ChangeNotifier**

**Fields (beyond standard):**
```dart
List<JournalEntry> _entries = [];
List<JournalPattern> _patterns = [];
List<JournalPrompt> _prompts = [];
List<String> _insights = [];

JournalEntry? _currentEntry;
bool _isDecrypted = false;
```

**Entry Management Methods:**
```dart
Future<void> createEntry(
  String userId,
  String plainContent,
  String inputMethod,
  {String? promptId, int? moodRating}
) async {
  try {
    _isLoading = true;
    notifyListeners();

    // Encrypt content
    final encrypted = await _encryptionService.encrypt(plainContent, userId);

    // Create entry
    final entry = JournalEntry(
      id: _generateUuid(),
      userId: userId,
      entryDate: DateTime.now(),
      entryTime: TimeOfDay.now(),
      contentEncrypted: encrypted.encryptedContent,
      encryptionIv: encrypted.initializationVector,
      inputMethod: inputMethod,
      wordCount: plainContent.split(' ').length,
      characterCount: plainContent.length,
      promptUsed: promptId,
      moodRating: moodRating,
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to repository
    await _repository.saveEntry(entry);

    // Extract patterns (if ML enabled)
    if (_journalingConfig?.enableMLAnalysis == true) {
      await _analyzeEntry(userId, entry, plainContent);
    }

    // Create intervention activity
    final activity = JournalingActivity(
      id: _generateUuid(),
      userId: userId,
      activityDate: DateTime.now(),
      wasCompleted: true,
      completedAt: DateTime.now(),
      durationMinutes: 10, // Estimate or track actual
      timeOfDay: _getTimeOfDay(DateTime.now()),
      journalEntryId: entry.id,
      inputMethod: inputMethod,
      wordCount: entry.wordCount,
      characterCount: entry.characterCount,
      promptUsed: promptId,
      moodBefore: moodRating,
    );

    await _repository.logActivity(activity);

    // Reload entries
    await loadEntries(userId);

  } catch (e) {
    _errorMessage = 'Failed to create journal entry: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> loadEntryDecrypted(JournalEntry entry) async {
  try {
    _isLoading = true;
    notifyListeners();

    // Decrypt content
    final decrypted = await _encryptionService.decrypt(
      entry.contentEncrypted,
      entry.encryptionIv,
      entry.userId,
    );

    entry.decryptedContent = decrypted;
    _currentEntry = entry;
    _isDecrypted = true;

  } catch (e) {
    _errorMessage = 'Failed to decrypt entry: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> _analyzeEntry(String userId, JournalEntry entry, String plainContent) async {
  // Extract patterns
  final extractedPatterns = await _patternService.analyzeEntry(plainContent);

  // Save patterns to repository
  for (final extracted in extractedPatterns) {
    await _repository.savePattern(JournalPattern(
      id: _generateUuid(),
      userId: userId,
      patternType: extracted.patternType,
      patternValue: extracted.patternValue,
      frequencyCount: 1,
      firstSeenDate: entry.entryDate,
      lastSeenDate: entry.entryDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }
}
```

**Photo OCR Method:**
```dart
Future<String> processPhotoJournal(File imageFile) async {
  try {
    _isLoading = true;
    notifyListeners();

    final ocrResult = await _ocrService.extractTextFromImage(imageFile);

    if (!ocrResult.isReliable) {
      _errorMessage = 'Low OCR confidence. Please review extracted text.';
    }

    return ocrResult.extractedText;

  } catch (e) {
    _errorMessage = 'Failed to process photo: $e';
    return '';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## Step J.10: Journaling Entry Screen

**File:** `lib/modules/journaling/presentation/screens/journal_entry_screen.dart`

**UI Components:**
```dart
// Input method selector
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'text', icon: Icon(Icons.text_fields)),
    ButtonSegment(value: 'voice', icon: Icon(Icons.mic)),
    ButtonSegment(value: 'photo', icon: Icon(Icons.camera_alt)),
  ],
  selected: {_inputMethod},
  onSelectionChanged: (value) {
    setState(() => _inputMethod = value.first);
  },
),

// Text editor (if input method = 'text')
if (_inputMethod == 'text')
  TextField(
    controller: _contentController,
    maxLines: null,
    minLines: 10,
    decoration: InputDecoration(
      hintText: 'Write your thoughts...',
      border: OutlineInputBorder(),
    ),
  ),

// Photo capture (if input method = 'photo')
if (_inputMethod == 'photo')
  Column(
    children: [
      if (_capturedImage != null)
        Image.file(_capturedImage!),
      ElevatedButton.icon(
        icon: Icon(Icons.camera),
        label: Text('Capture Journal Photo'),
        onPressed: () async {
          final image = await ImagePicker().pickImage(source: ImageSource.camera);
          if (image != null) {
            setState(() => _capturedImage = File(image.path));

            // Process OCR
            final extractedText = await viewModel.processPhotoJournal(_capturedImage!);
            _contentController.text = extractedText;
          }
        },
      ),
    ],
  ),

// Prompt selector (optional)
if (config.usePrompts)
  DropdownButton<String>(
    hint: Text('Use a prompt'),
    value: _selectedPromptId,
    items: prompts.map((prompt) {
      return DropdownMenuItem(
        value: prompt.id,
        child: Text(prompt.promptText),
      );
    }).toList(),
    onChanged: (value) {
      setState(() => _selectedPromptId = value);
    },
  ),

// Mood slider (optional)
Text('How do you feel right now?'),
Slider(
  value: _moodRating.toDouble(),
  min: 1,
  max: 10,
  divisions: 9,
  label: _moodRating.toString(),
  onChanged: (value) {
    setState(() => _moodRating = value.toInt());
  },
),

// Save button
ElevatedButton(
  onPressed: () async {
    await viewModel.createEntry(
      userId,
      _contentController.text,
      _inputMethod,
      promptId: _selectedPromptId,
      moodRating: _moodRating,
    );
    Navigator.pop(context);
  },
  child: Text('Save Entry'),
),
```

---

## Testing Checklist

### Manual Tests:
- [ ] Create text journal entry, verify encrypted in database
- [ ] View journal entry, verify decrypts correctly
- [ ] Create entry with prompt, verify prompt ID saved
- [ ] Capture photo journal, verify OCR extracts text (or shows "not implemented")
- [ ] Record mood before/after, verify saved
- [ ] View patterns, verify ML extracted keywords
- [ ] View insights, verify correlations shown
- [ ] Enable PIN protection, verify prompts for PIN on view

### Privacy Tests:
- [ ] Query database directly, verify content is encrypted (gibberish)
- [ ] Decrypt entry with wrong user ID, verify fails
- [ ] Export journal backup, verify encrypted

### ML Tests:
- [ ] Write entry mentioning "work stress", verify pattern extracted
- [ ] Write 5 entries mentioning "exercise", verify frequency count = 5
- [ ] Correlate patterns with sleep, verify correlations calculated

### Database Tests:
```sql
-- Check encrypted entries (should be unreadable)
SELECT
  id,
  entry_date,
  content_encrypted,  -- Should be gibberish
  input_method,
  word_count
FROM journal_entries
ORDER BY entry_date DESC;

-- Check extracted patterns
SELECT
  pattern_type,
  pattern_value,
  frequency_count,
  correlation_sleep_quality
FROM journal_patterns
WHERE user_id = 'test-user-id'
ORDER BY frequency_count DESC;

-- Check journaling activities
SELECT
  activity_date,
  module_specific_data->>'word_count' as words,
  module_specific_data->>'input_method' as method,
  module_specific_data->>'mood_before' as mood_before,
  module_specific_data->>'mood_after' as mood_after
FROM intervention_activities
WHERE module_id = 'journaling'
ORDER BY activity_date DESC;
```

---

## Notes

**Journaling Module Complexity:**
- Most complex module due to encryption, ML, and multiple input methods
- Privacy-first design: all content encrypted at rest
- ML pattern recognition deferred to simple implementation (can enhance later)
- OCR integration optional (placeholder for Phase 1)

**Security Implementation:**
- AES-256 encryption with user-specific key
- Initialization vector stored per entry
- Optional PIN protection for extra security layer
- Encryption key never leaves device

**ML Strategy:**
- Phase 1: Simple keyword matching ("stress", "work", "exercise")
- Phase 2: Sentiment analysis (positive/negative word counts)
- Phase 3: Cloud NLP API integration (Google Natural Language, AWS Comprehend)
- Phase 4: On-device ML model (TensorFlow Lite)

**OCR Strategy:**
- Phase 1: Placeholder (manual transcription)
- Phase 2: Google ML Kit on-device OCR
- Phase 3: Cloud Vision API for higher accuracy

**Privacy Considerations:**
- Journal content never sent to server (even if we add backend)
- ML analysis on-device or with anonymized data
- User owns all data, can export/delete anytime
- Clear privacy policy in-app

**Estimated Time:** 20-22 hours (most complex module)
- Database migration with encryption fields: 60 minutes
- Encryption service implementation: 120 minutes
- Models (Entry + Pattern + Prompt): 90 minutes
- Pattern recognition service (simple): 120 minutes
- OCR service (placeholder): 30 minutes
- Repository + Datasource: 120 minutes
- ViewModel with encryption/ML: 180 minutes
- Entry screen with multiple input methods: 180 minutes
- Pattern insights screen: 90 minutes
- Testing: 120 minutes
