/// Light Therapy Module Configuration
///
/// Supports two modes:
/// - Standard Mode: Single morning session with simple configuration
/// - Advanced Mode: Multiple sessions with time slider and advanced settings
///
/// Stored as JSON in `user_module_configurations.configuration` field.
class LightConfig {
  /// Configuration mode: 'standard' or 'advanced'
  final String mode;

  // =========================================================================
  // Standard Mode Fields
  // =========================================================================

  /// Target time for light therapy (HH:mm format)
  final String? targetTime;

  /// Duration of light session in minutes (15-60 for standard, 5-120 for advanced)
  final int? targetDurationMinutes;

  /// Type of light: 'natural_sunlight', 'light_box', 'blue_light', 'red_light'
  final String? lightType;

  // =========================================================================
  // Notification Settings (both modes)
  // =========================================================================

  /// Enable morning reminder notification
  final bool morningReminderEnabled;

  /// Time for morning reminder (HH:mm format)
  final String morningReminderTime;

  /// Enable evening dim lights reminder
  final bool eveningDimReminderEnabled;

  /// Time for evening dim reminder (HH:mm format, default: '20:00')
  final String eveningDimTime;

  /// Enable blue blocker glasses reminder
  final bool blueBlockerReminderEnabled;

  /// Time for blue blocker reminder (HH:mm format, default: '21:00')
  final String blueBlockerTime;

  // =========================================================================
  // Advanced Mode Fields
  // =========================================================================

  /// Multiple light sessions (only for advanced mode)
  final List<LightSession>? sessions;

  LightConfig({
    required this.mode,
    this.targetTime,
    this.targetDurationMinutes,
    this.lightType,
    this.morningReminderEnabled = true,
    this.morningReminderTime = '07:30',
    this.eveningDimReminderEnabled = true,
    this.eveningDimTime = '20:00',
    this.blueBlockerReminderEnabled = true,
    this.blueBlockerTime = '21:00',
    this.sessions,
  });

  /// Standard mode default configuration
  factory LightConfig.standardDefault() {
    return LightConfig(
      mode: 'standard',
      targetTime: '07:30',
      targetDurationMinutes: 30,
      lightType: 'natural_sunlight',
      morningReminderEnabled: true,
      morningReminderTime: '07:30',
      eveningDimReminderEnabled: true,
      eveningDimTime: '20:00',
      blueBlockerReminderEnabled: true,
      blueBlockerTime: '21:00',
    );
  }

  /// Advanced mode default configuration
  factory LightConfig.advancedDefault() {
    return LightConfig(
      mode: 'advanced',
      morningReminderEnabled: true,
      morningReminderTime: '07:30',
      eveningDimReminderEnabled: true,
      eveningDimTime: '20:00',
      blueBlockerReminderEnabled: true,
      blueBlockerTime: '21:00',
      sessions: [
        LightSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionTime: '07:30',
          durationMinutes: 30,
          lightType: 'natural_sunlight',
          isEnabled: true,
        ),
        LightSession(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          sessionTime: '20:00',
          durationMinutes: 20,
          lightType: 'red_light',
          isEnabled: true,
        ),
      ],
    );
  }

  /// From JSON (from database)
  factory LightConfig.fromJson(Map<String, dynamic> json) {
    return LightConfig(
      mode: json['mode'] as String? ?? 'standard',
      targetTime: json['targetTime'] as String?,
      targetDurationMinutes: json['targetDurationMinutes'] as int?,
      lightType: json['lightType'] as String?,
      morningReminderEnabled:
          json['morningReminderEnabled'] as bool? ?? true,
      morningReminderTime: json['morningReminderTime'] as String? ?? '07:30',
      eveningDimReminderEnabled:
          json['eveningDimReminderEnabled'] as bool? ?? true,
      eveningDimTime: json['eveningDimTime'] as String? ?? '20:00',
      blueBlockerReminderEnabled:
          json['blueBlockerReminderEnabled'] as bool? ?? true,
      blueBlockerTime: json['blueBlockerTime'] as String? ?? '21:00',
      sessions: json['sessions'] != null
          ? (json['sessions'] as List)
              .map((s) => LightSession.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// To JSON (for database)
  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      if (targetTime != null) 'targetTime': targetTime,
      if (targetDurationMinutes != null)
        'targetDurationMinutes': targetDurationMinutes,
      if (lightType != null) 'lightType': lightType,
      'morningReminderEnabled': morningReminderEnabled,
      'morningReminderTime': morningReminderTime,
      'eveningDimReminderEnabled': eveningDimReminderEnabled,
      'eveningDimTime': eveningDimTime,
      'blueBlockerReminderEnabled': blueBlockerReminderEnabled,
      'blueBlockerTime': blueBlockerTime,
      if (sessions != null)
        'sessions': sessions!.map((s) => s.toJson()).toList(),
    };
  }

  /// Create a copy with updated fields
  LightConfig copyWith({
    String? mode,
    String? targetTime,
    int? targetDurationMinutes,
    String? lightType,
    bool? morningReminderEnabled,
    String? morningReminderTime,
    bool? eveningDimReminderEnabled,
    String? eveningDimTime,
    bool? blueBlockerReminderEnabled,
    String? blueBlockerTime,
    List<LightSession>? sessions,
  }) {
    return LightConfig(
      mode: mode ?? this.mode,
      targetTime: targetTime ?? this.targetTime,
      targetDurationMinutes:
          targetDurationMinutes ?? this.targetDurationMinutes,
      lightType: lightType ?? this.lightType,
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      eveningDimReminderEnabled:
          eveningDimReminderEnabled ?? this.eveningDimReminderEnabled,
      eveningDimTime: eveningDimTime ?? this.eveningDimTime,
      blueBlockerReminderEnabled:
          blueBlockerReminderEnabled ?? this.blueBlockerReminderEnabled,
      blueBlockerTime: blueBlockerTime ?? this.blueBlockerTime,
      sessions: sessions ?? this.sessions,
    );
  }

  /// Validate configuration
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    // Validate mode
    if (mode != 'standard' && mode != 'advanced') {
      return 'Mode must be "standard" or "advanced"';
    }

    // Validate standard mode fields
    if (mode == 'standard') {
      if (targetTime == null) {
        return 'Standard mode requires targetTime';
      }
      if (targetDurationMinutes == null) {
        return 'Standard mode requires targetDurationMinutes';
      }
      if (targetDurationMinutes! < 15 || targetDurationMinutes! > 60) {
        return 'Standard mode duration must be 15-60 minutes';
      }
      if (lightType == null) {
        return 'Standard mode requires lightType';
      }
      if (!_isValidLightType(lightType!)) {
        return 'Invalid light type: $lightType';
      }
      if (!_isValidTime(targetTime!)) {
        return 'Invalid targetTime format (must be HH:mm)';
      }
    }

    // Validate advanced mode fields
    if (mode == 'advanced') {
      if (sessions == null || sessions!.isEmpty) {
        return 'Advanced mode requires at least one session';
      }
      for (var session in sessions!) {
        final sessionError = session.validate();
        if (sessionError != null) {
          return 'Session ${session.id}: $sessionError';
        }
      }
    }

    // Validate notification times
    if (!_isValidTime(morningReminderTime)) {
      return 'Invalid morningReminderTime format (must be HH:mm)';
    }
    if (!_isValidTime(eveningDimTime)) {
      return 'Invalid eveningDimTime format (must be HH:mm)';
    }
    if (!_isValidTime(blueBlockerTime)) {
      return 'Invalid blueBlockerTime format (must be HH:mm)';
    }

    return null; // Valid
  }

  /// Validate time format (HH:mm)
  bool _isValidTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;

    return true;
  }

  /// Validate light type
  bool _isValidLightType(String type) {
    const validTypes = [
      'natural_sunlight',
      'light_box',
      'blue_light',
      'red_light',
    ];
    return validTypes.contains(type);
  }
}

/// Light Session (for Advanced Mode)
///
/// Represents a single light therapy session in advanced mode.
class LightSession {
  /// Unique session identifier
  final String id;

  /// Time for this session (HH:mm format)
  final String sessionTime;

  /// Duration in minutes (5-120)
  final int durationMinutes;

  /// Light type for this session
  final String lightType;

  /// Whether this session is enabled
  final bool isEnabled;

  LightSession({
    required this.id,
    required this.sessionTime,
    required this.durationMinutes,
    required this.lightType,
    this.isEnabled = true,
  });

  /// From JSON
  factory LightSession.fromJson(Map<String, dynamic> json) {
    return LightSession(
      id: json['id'] as String,
      sessionTime: json['sessionTime'] as String,
      durationMinutes: json['durationMinutes'] as int,
      lightType: json['lightType'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionTime': sessionTime,
      'durationMinutes': durationMinutes,
      'lightType': lightType,
      'isEnabled': isEnabled,
    };
  }

  /// Create a copy with updated fields
  LightSession copyWith({
    String? id,
    String? sessionTime,
    int? durationMinutes,
    String? lightType,
    bool? isEnabled,
  }) {
    return LightSession(
      id: id ?? this.id,
      sessionTime: sessionTime ?? this.sessionTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      lightType: lightType ?? this.lightType,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Validate session
  ///
  /// Returns error message if invalid, null if valid
  String? validate() {
    if (durationMinutes < 5 || durationMinutes > 120) {
      return 'Duration must be 5-120 minutes';
    }

    final parts = sessionTime.split(':');
    if (parts.length != 2) {
      return 'Invalid time format (must be HH:mm)';
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return 'Invalid time format (must be HH:mm)';
    }
    if (hour < 0 || hour > 23) {
      return 'Hour must be 0-23';
    }
    if (minute < 0 || minute > 59) {
      return 'Minute must be 0-59';
    }

    const validTypes = [
      'natural_sunlight',
      'light_box',
      'blue_light',
      'red_light',
    ];
    if (!validTypes.contains(lightType)) {
      return 'Invalid light type: $lightType';
    }

    return null; // Valid
  }
}
