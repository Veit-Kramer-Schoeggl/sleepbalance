import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';

/// Light Therapy Activity
///
/// Extends InterventionActivity with light-specific fields stored in moduleSpecificData.
///
/// Light-specific data includes:
/// - light_type: Type of light used
/// - location: Where the session occurred (optional)
/// - weather: Weather conditions for outdoor sessions (optional)
/// - device_used: Specific device or equipment (optional)
class LightActivity extends InterventionActivity {
  LightActivity({
    required super.id,
    required super.userId,
    required super.activityDate,
    required super.wasCompleted,
    super.completedAt,
    super.durationMinutes,
    super.timeOfDay,
    super.intensity,
    super.notes,
    required super.createdAt,
    super.updatedAt,
    // Light-specific parameters
    required String lightType,
    String? location,
    String? weather,
    String? deviceUsed,
  }) : super(
          moduleId: 'light',
          moduleSpecificData: {
            'light_type': lightType,
            if (location != null) 'location': location,
            if (weather != null) 'weather': weather,
            if (deviceUsed != null) 'device_used': deviceUsed,
          },
        );

  /// Create LightActivity from InterventionActivity
  ///
  /// Used when reading from database - converts base InterventionActivity
  /// to LightActivity with typed access to light-specific fields.
  factory LightActivity.fromInterventionActivity(
      InterventionActivity activity) {
    if (activity.moduleId != 'light') {
      throw ArgumentError(
          'Cannot create LightActivity from non-light intervention');
    }

    final data = activity.moduleSpecificData ?? {};

    return LightActivity(
      id: activity.id,
      userId: activity.userId,
      activityDate: activity.activityDate,
      wasCompleted: activity.wasCompleted,
      completedAt: activity.completedAt,
      durationMinutes: activity.durationMinutes,
      timeOfDay: activity.timeOfDay,
      intensity: activity.intensity,
      notes: activity.notes,
      createdAt: activity.createdAt,
      updatedAt: activity.updatedAt,
      lightType: data['light_type'] as String? ?? 'natural_sunlight',
      location: data['location'] as String?,
      weather: data['weather'] as String?,
      deviceUsed: data['device_used'] as String?,
    );
  }

  /// From database (delegates to InterventionActivity)
  factory LightActivity.fromDatabase(Map<String, dynamic> map) {
    final baseActivity = InterventionActivity.fromDatabase(map);
    return LightActivity.fromInterventionActivity(baseActivity);
  }

  /// From JSON (delegates to InterventionActivity)
  factory LightActivity.fromJson(Map<String, dynamic> json) {
    final baseActivity = InterventionActivity.fromJson(json);
    return LightActivity.fromInterventionActivity(baseActivity);
  }

  // =========================================================================
  // Typed Getters for Light-Specific Data
  // =========================================================================

  /// Type of light used in this session
  ///
  /// Values: 'natural_sunlight', 'light_box', 'blue_light', 'red_light'
  String get lightType =>
      moduleSpecificData?['light_type'] as String? ?? 'natural_sunlight';

  /// Location where session occurred (e.g., 'outdoor', 'living room', 'office')
  String? get location => moduleSpecificData?['location'] as String?;

  /// Weather conditions for outdoor sessions (e.g., 'sunny', 'cloudy', 'overcast')
  String? get weather => moduleSpecificData?['weather'] as String?;

  /// Specific device or equipment used (e.g., 'Philips Wake-Up Light', 'Verilux HappyLight')
  String? get deviceUsed => moduleSpecificData?['device_used'] as String?;

  // =========================================================================
  // Convenience Methods
  // =========================================================================

  /// Create a copy with updated light-specific fields
  LightActivity copyWithLight({
    String? id,
    String? userId,
    DateTime? activityDate,
    bool? wasCompleted,
    DateTime? completedAt,
    int? durationMinutes,
    String? timeOfDay,
    String? intensity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lightType,
    String? location,
    String? weather,
    String? deviceUsed,
  }) {
    return LightActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityDate: activityDate ?? this.activityDate,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lightType: lightType ?? this.lightType,
      location: location ?? this.location,
      weather: weather ?? this.weather,
      deviceUsed: deviceUsed ?? this.deviceUsed,
    );
  }

  /// Get a human-readable description of this activity
  String getDescription() {
    final buffer = StringBuffer();

    // Light type
    final typeLabel = {
      'natural_sunlight': 'Natural Sunlight',
      'light_box': 'Light Box',
      'blue_light': 'Blue Light Therapy',
      'red_light': 'Red Light Therapy',
    }[lightType] ?? lightType;

    buffer.write(typeLabel);

    // Duration
    if (durationMinutes != null) {
      buffer.write(' for $durationMinutes minutes');
    }

    // Location
    if (location != null) {
      buffer.write(' ($location)');
    }

    // Weather
    if (weather != null) {
      buffer.write(' - $weather');
    }

    return buffer.toString();
  }

  /// Check if this was an outdoor session
  bool get isOutdoorSession =>
      location?.toLowerCase().contains('outdoor') == true ||
      lightType == 'natural_sunlight';

  /// Check if this used therapeutic equipment
  bool get usedTherapeuticDevice =>
      lightType == 'light_box' ||
      lightType == 'blue_light' ||
      lightType == 'red_light';
}
