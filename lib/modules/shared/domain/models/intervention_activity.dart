import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/database_date_utils.dart';

part 'intervention_activity.g.dart';

/// Base model for ALL intervention tracking across all modules.
///
/// This model is used by all intervention modules (Light, Sport, Meditation, etc.)
/// to track daily activities in the `intervention_activities` database table.
///
/// Common fields are typed columns for query performance, while module-specific
/// data is stored in the flexible `moduleSpecificData` JSON field.
@JsonSerializable()
class InterventionActivity {
  /// Unique identifier (UUID)
  final String id;

  /// User who performed this intervention
  final String userId;

  /// Module identifier (e.g., 'light', 'sport', 'meditation')
  final String moduleId;

  /// The day this intervention was performed (date only, time ignored)
  final DateTime activityDate;

  /// REQUIRED: Did the user complete this intervention?
  final bool wasCompleted;

  /// Optional: When specifically was this completed (timestamp)
  final DateTime? completedAt;

  /// Optional: How long did the intervention take (in minutes)
  final int? durationMinutes;

  /// Optional: Time of day category
  /// Valid values: 'morning', 'afternoon', 'evening', 'night'
  final String? timeOfDay;

  /// Optional: Intensity level
  /// Valid values: 'low', 'medium', 'high'
  final String? intensity;

  /// Module-specific flexible data stored as JSON.
  ///
  /// Example for Light module:
  /// ```dart
  /// {
  ///   'light_type': 'natural_sunlight',
  ///   'location': 'outdoor',
  ///   'weather': 'sunny'
  /// }
  /// ```
  final Map<String, dynamic>? moduleSpecificData;

  /// Optional user notes
  final String? notes;

  /// When this record was created
  final DateTime createdAt;

  /// When this record was last updated
  final DateTime updatedAt;

  InterventionActivity({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.activityDate,
    required this.wasCompleted,
    this.completedAt,
    this.durationMinutes,
    this.timeOfDay,
    this.intensity,
    this.moduleSpecificData,
    this.notes,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// JSON serialization (for API and data transfer)
  factory InterventionActivity.fromJson(Map<String, dynamic> json) =>
      _$InterventionActivityFromJson(json);

  Map<String, dynamic> toJson() => _$InterventionActivityToJson(this);

  /// Database serialization (for SQLite storage)
  ///
  /// Converts from SQLite row format where:
  /// - Booleans are stored as INTEGER (1/0)
  /// - DateTimes are stored as TEXT (ISO 8601)
  /// - JSON is stored as TEXT
  factory InterventionActivity.fromDatabase(Map<String, dynamic> map) {
    return InterventionActivity(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      moduleId: map['module_id'] as String,
      activityDate:
          DatabaseDateUtils.fromString(map['activity_date'] as String),
      wasCompleted: (map['was_completed'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DatabaseDateUtils.fromString(map['completed_at'] as String)
          : null,
      durationMinutes: map['duration_minutes'] as int?,
      timeOfDay: map['time_of_day'] as String?,
      intensity: map['intensity'] as String?,
      moduleSpecificData: map['module_specific_data'] != null
          ? json.decode(map['module_specific_data'] as String)
              as Map<String, dynamic>
          : null,
      notes: map['notes'] as String?,
      createdAt:
          DatabaseDateUtils.fromString(map['created_at'] as String),
      updatedAt:
          DatabaseDateUtils.fromString(map['updated_at'] as String),
    );
  }

  /// Convert to SQLite row format
  ///
  /// Converts to SQLite format where:
  /// - Booleans become INTEGER (1/0)
  /// - DateTimes become TEXT (ISO 8601)
  /// - JSON becomes TEXT
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'activity_date': DatabaseDateUtils.toDateString(activityDate),
      'was_completed': wasCompleted ? 1 : 0,
      'completed_at': completedAt != null
          ? DatabaseDateUtils.toTimestamp(completedAt!)
          : null,
      'duration_minutes': durationMinutes,
      'time_of_day': timeOfDay,
      'intensity': intensity,
      'module_specific_data':
          moduleSpecificData != null ? json.encode(moduleSpecificData) : null,
      'notes': notes,
      'created_at': DatabaseDateUtils.toTimestamp(createdAt),
      'updated_at': DatabaseDateUtils.toTimestamp(updatedAt),
    };
  }

  /// Create a copy with updated fields (immutability pattern)
  InterventionActivity copyWith({
    String? id,
    String? userId,
    String? moduleId,
    DateTime? activityDate,
    bool? wasCompleted,
    DateTime? completedAt,
    int? durationMinutes,
    String? timeOfDay,
    String? intensity,
    Map<String, dynamic>? moduleSpecificData,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterventionActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      activityDate: activityDate ?? this.activityDate,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      intensity: intensity ?? this.intensity,
      moduleSpecificData: moduleSpecificData ?? this.moduleSpecificData,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
