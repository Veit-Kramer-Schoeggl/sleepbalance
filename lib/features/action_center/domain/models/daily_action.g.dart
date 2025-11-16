// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyAction _$DailyActionFromJson(Map<String, dynamic> json) => DailyAction(
  id: json['id'] as String,
  userId: json['userId'] as String,
  title: json['title'] as String,
  iconName: json['iconName'] as String,
  isCompleted: json['isCompleted'] as bool,
  actionDate: DateTime.parse(json['actionDate'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$DailyActionToJson(DailyAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'iconName': instance.iconName,
      'isCompleted': instance.isCompleted,
      'actionDate': instance.actionDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };
