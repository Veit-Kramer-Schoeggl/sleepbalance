// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SleepRecord _$SleepRecordFromJson(Map<String, dynamic> json) => SleepRecord(
  id: json['id'] as String,
  userId: json['userId'] as String,
  sleepDate: DateTime.parse(json['sleepDate'] as String),
  bedTime: json['bedTime'] == null
      ? null
      : DateTime.parse(json['bedTime'] as String),
  sleepStartTime: json['sleepStartTime'] == null
      ? null
      : DateTime.parse(json['sleepStartTime'] as String),
  sleepEndTime: json['sleepEndTime'] == null
      ? null
      : DateTime.parse(json['sleepEndTime'] as String),
  wakeTime: json['wakeTime'] == null
      ? null
      : DateTime.parse(json['wakeTime'] as String),
  totalSleepTime: (json['totalSleepTime'] as num?)?.toInt(),
  deepSleepDuration: (json['deepSleepDuration'] as num?)?.toInt(),
  remSleepDuration: (json['remSleepDuration'] as num?)?.toInt(),
  lightSleepDuration: (json['lightSleepDuration'] as num?)?.toInt(),
  awakeDuration: (json['awakeDuration'] as num?)?.toInt(),
  avgHeartRate: (json['avgHeartRate'] as num?)?.toDouble(),
  minHeartRate: (json['minHeartRate'] as num?)?.toDouble(),
  maxHeartRate: (json['maxHeartRate'] as num?)?.toDouble(),
  avgHrv: (json['avgHrv'] as num?)?.toDouble(),
  avgHeartRateVariability: (json['avgHeartRateVariability'] as num?)
      ?.toDouble(),
  avgBreathingRate: (json['avgBreathingRate'] as num?)?.toDouble(),
  qualityRating: json['qualityRating'] as String?,
  qualityNotes: json['qualityNotes'] as String?,
  dataSource: json['dataSource'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$SleepRecordToJson(SleepRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'sleepDate': instance.sleepDate.toIso8601String(),
      'bedTime': instance.bedTime?.toIso8601String(),
      'sleepStartTime': instance.sleepStartTime?.toIso8601String(),
      'sleepEndTime': instance.sleepEndTime?.toIso8601String(),
      'wakeTime': instance.wakeTime?.toIso8601String(),
      'totalSleepTime': instance.totalSleepTime,
      'deepSleepDuration': instance.deepSleepDuration,
      'remSleepDuration': instance.remSleepDuration,
      'lightSleepDuration': instance.lightSleepDuration,
      'awakeDuration': instance.awakeDuration,
      'avgHeartRate': instance.avgHeartRate,
      'minHeartRate': instance.minHeartRate,
      'maxHeartRate': instance.maxHeartRate,
      'avgHrv': instance.avgHrv,
      'avgHeartRateVariability': instance.avgHeartRateVariability,
      'avgBreathingRate': instance.avgBreathingRate,
      'qualityRating': instance.qualityRating,
      'qualityNotes': instance.qualityNotes,
      'dataSource': instance.dataSource,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
