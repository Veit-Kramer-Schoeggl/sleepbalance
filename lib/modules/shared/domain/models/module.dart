import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/database_date_utils.dart';

part 'module.g.dart';

/// Module metadata from the modules table.
///
/// Represents an intervention module available in the app (e.g., Light, Sport, Meditation).
/// Module metadata is also hardcoded in `module_metadata.dart` for compile-time safety,
/// but this model is used for database queries and type safety.
@JsonSerializable()
class Module {
  /// Module identifier (e.g., 'light', 'sport', 'meditation')
  final String id;

  /// Internal name
  final String name;

  /// User-facing display name (e.g., 'Light Therapy')
  final String displayName;

  /// Optional description of what this module does
  final String? description;

  /// Optional icon identifier (legacy, now using module_metadata.dart)
  final String? icon;

  /// Whether this module is active app-wide
  final bool isActive;

  /// When this module was added to the app
  final DateTime createdAt;

  Module({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.icon,
    required this.isActive,
    required this.createdAt,
  });

  /// JSON serialization (for API and data transfer)
  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleToJson(this);

  /// Database serialization (for SQLite storage)
  ///
  /// Converts from SQLite row format where:
  /// - isActive is stored as INTEGER (1/0)
  /// - createdAt is stored as TEXT (ISO 8601)
  factory Module.fromDatabase(Map<String, dynamic> map) {
    return Module(
      id: map['id'] as String,
      name: map['name'] as String,
      displayName: map['display_name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DatabaseDateUtils.fromString(map['created_at'] as String),
    );
  }

  /// Convert to SQLite row format
  ///
  /// Converts to SQLite format where:
  /// - isActive becomes INTEGER (1/0)
  /// - createdAt becomes TEXT (ISO 8601)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'created_at': DatabaseDateUtils.toTimestamp(createdAt),
    };
  }
}
