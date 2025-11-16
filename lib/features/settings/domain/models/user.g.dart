// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  passwordHash: json['passwordHash'] as String?,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  birthDate: DateTime.parse(json['birthDate'] as String),
  timezone: json['timezone'] as String,
  targetSleepDuration: (json['targetSleepDuration'] as num?)?.toInt(),
  targetBedTime: json['targetBedTime'] as String?,
  targetWakeTime: json['targetWakeTime'] as String?,
  hasSleepDisorder: json['hasSleepDisorder'] as bool? ?? false,
  sleepDisorderType: json['sleepDisorderType'] as String?,
  takesSleepMedication: json['takesSleepMedication'] as bool? ?? false,
  preferredUnitSystem: json['preferredUnitSystem'] as String? ?? 'metric',
  language: json['language'] as String? ?? 'en',
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'passwordHash': instance.passwordHash,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'birthDate': instance.birthDate.toIso8601String(),
  'timezone': instance.timezone,
  'targetSleepDuration': instance.targetSleepDuration,
  'targetBedTime': instance.targetBedTime,
  'targetWakeTime': instance.targetWakeTime,
  'hasSleepDisorder': instance.hasSleepDisorder,
  'sleepDisorderType': instance.sleepDisorderType,
  'takesSleepMedication': instance.takesSleepMedication,
  'preferredUnitSystem': instance.preferredUnitSystem,
  'language': instance.language,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
