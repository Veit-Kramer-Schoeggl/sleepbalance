// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterventionActivity _$InterventionActivityFromJson(
  Map<String, dynamic> json,
) => InterventionActivity(
  id: json['id'] as String,
  userId: json['userId'] as String,
  moduleId: json['moduleId'] as String,
  activityDate: DateTime.parse(json['activityDate'] as String),
  wasCompleted: json['wasCompleted'] as bool,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
  timeOfDay: json['timeOfDay'] as String?,
  intensity: json['intensity'] as String?,
  moduleSpecificData: json['moduleSpecificData'] as Map<String, dynamic>?,
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$InterventionActivityToJson(
  InterventionActivity instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'moduleId': instance.moduleId,
  'activityDate': instance.activityDate.toIso8601String(),
  'wasCompleted': instance.wasCompleted,
  'completedAt': instance.completedAt?.toIso8601String(),
  'durationMinutes': instance.durationMinutes,
  'timeOfDay': instance.timeOfDay,
  'intensity': instance.intensity,
  'moduleSpecificData': instance.moduleSpecificData,
  'notes': instance.notes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
