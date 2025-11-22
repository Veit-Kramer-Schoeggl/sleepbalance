// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) => Module(
  id: json['id'] as String,
  name: json['name'] as String,
  displayName: json['displayName'] as String,
  description: json['description'] as String?,
  icon: json['icon'] as String?,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ModuleToJson(Module instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'displayName': instance.displayName,
  'description': instance.description,
  'icon': instance.icon,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
};
