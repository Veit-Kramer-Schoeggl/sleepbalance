// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_module_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModuleConfig _$UserModuleConfigFromJson(Map<String, dynamic> json) =>
    UserModuleConfig(
      id: json['id'] as String,
      userId: json['userId'] as String,
      moduleId: json['moduleId'] as String,
      isEnabled: json['isEnabled'] as bool,
      configuration: json['configuration'] as Map<String, dynamic>,
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserModuleConfigToJson(UserModuleConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'moduleId': instance.moduleId,
      'isEnabled': instance.isEnabled,
      'configuration': instance.configuration,
      'enrolledAt': instance.enrolledAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
