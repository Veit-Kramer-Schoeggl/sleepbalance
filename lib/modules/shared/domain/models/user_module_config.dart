import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/database_date_utils.dart';

part 'user_module_config.g.dart';

/// User's configuration for a specific module
///
/// Stored in user_module_configurations table.
/// Contains both activation status and module-specific settings.
@JsonSerializable()
class UserModuleConfig {
  /// Unique config ID (UUID)
  final String id;

  /// User who owns this configuration
  final String userId;

  /// Module this configuration belongs to
  /// Examples: 'light', 'sport', 'meditation'
  final String moduleId;

  /// Whether module is currently active
  /// true = user is using this module
  /// false = user deactivated, but we keep settings
  final bool isEnabled;

  /// Module-specific configuration as JSON
  ///
  /// Each module defines its own configuration structure.
  /// Stored as Map\<String, dynamic\> in Dart, JSON string in database.
  ///
  /// Example for Light module:
  /// {
  ///   'mode': 'standard',
  ///   'sessions': [...]
  /// }
  final Map<String, dynamic> configuration;

  /// When user first activated this module
  final DateTime enrolledAt;

  /// When configuration was last updated
  final DateTime updatedAt;

  UserModuleConfig({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.isEnabled,
    required this.configuration,
    required this.enrolledAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Get typed value from configuration
  ///
  /// Type-safe way to extract values from configuration map.
  ///
  /// Example:
  /// ```dart
  /// final mode = config.getConfigValue<String>('mode'); // 'standard'
  /// final sessions = config.getConfigValue<List>('sessions');
  /// ```
  T? getConfigValue<T>(String key) {
    return configuration[key] as T?;
  }

  /// Update a single configuration value
  ///
  /// Returns new UserModuleConfig with updated configuration.
  /// Does NOT mutate original object (immutable pattern).
  ///
  /// Example:
  /// ```dart
  /// final updated = config.updateConfigValue('mode', 'advanced');
  /// ```
  UserModuleConfig updateConfigValue(String key, dynamic value) {
    final newConfig = Map<String, dynamic>.from(configuration);
    newConfig[key] = value;
    return copyWith(
      configuration: newConfig,
      updatedAt: DateTime.now(),
    );
  }

  // ========================================================================
  // JSON Serialization (for API - future use)
  // ========================================================================

  factory UserModuleConfig.fromJson(Map<String, dynamic> json) =>
      _$UserModuleConfigFromJson(json);

  Map<String, dynamic> toJson() => _$UserModuleConfigToJson(this);

  // ========================================================================
  // Database Serialization (for SQLite)
  // ========================================================================

  /// Create from database row
  ///
  /// Converts SQLite row to UserModuleConfig instance.
  /// Handles type conversions:
  /// - INTEGER → bool (is_enabled)
  /// - TEXT → DateTime (enrolled_at, updated_at)
  /// - TEXT → Map\<String, dynamic\> (configuration JSON)
  factory UserModuleConfig.fromDatabase(Map<String, dynamic> map) {
    return UserModuleConfig(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      moduleId: map['module_id'] as String,
      isEnabled: (map['is_enabled'] as int) == 1,
      configuration: json.decode(map['configuration'] as String) as Map<String, dynamic>,
      enrolledAt: DatabaseDateUtils.fromString(map['enrolled_at'] as String),
      updatedAt: DatabaseDateUtils.fromString(map['updated_at'] as String),
    );
  }

  /// Convert to database row
  ///
  /// Converts UserModuleConfig to Map for SQLite insertion.
  /// Handles type conversions:
  /// - bool → INTEGER (1 or 0)
  /// - DateTime → TEXT (ISO 8601)
  /// - Map → TEXT (JSON string)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'is_enabled': isEnabled ? 1 : 0,
      'configuration': json.encode(configuration),
      'enrolled_at': DatabaseDateUtils.toTimestamp(enrolledAt),
      'updated_at': DatabaseDateUtils.toTimestamp(updatedAt),
    };
  }

  // ========================================================================
  // CopyWith
  // ========================================================================

  UserModuleConfig copyWith({
    String? id,
    String? userId,
    String? moduleId,
    bool? isEnabled,
    Map<String, dynamic>? configuration,
    DateTime? enrolledAt,
    DateTime? updatedAt,
  }) {
    return UserModuleConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      isEnabled: isEnabled ?? this.isEnabled,
      configuration: configuration ?? this.configuration,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModuleConfig(id: $id, userId: $userId, moduleId: $moduleId, '
        'isEnabled: $isEnabled, enrolledAt: $enrolledAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModuleConfig &&
        other.id == id &&
        other.userId == userId &&
        other.moduleId == moduleId &&
        other.isEnabled == isEnabled &&
        other.enrolledAt == enrolledAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      moduleId,
      isEnabled,
      enrolledAt,
      updatedAt,
    );
  }
}
