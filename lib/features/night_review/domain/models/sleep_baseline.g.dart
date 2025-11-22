// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_baseline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SleepBaseline _$SleepBaselineFromJson(Map<String, dynamic> json) =>
    SleepBaseline(
      id: json['id'] as String,
      userId: json['userId'] as String,
      baselineType: json['baselineType'] as String,
      metricName: json['metricName'] as String,
      metricValue: (json['metricValue'] as num).toDouble(),
      dataRangeStart: DateTime.parse(json['dataRangeStart'] as String),
      dataRangeEnd: DateTime.parse(json['dataRangeEnd'] as String),
      computedAt: DateTime.parse(json['computedAt'] as String),
    );

Map<String, dynamic> _$SleepBaselineToJson(SleepBaseline instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'baselineType': instance.baselineType,
      'metricName': instance.metricName,
      'metricValue': instance.metricValue,
      'dataRangeStart': instance.dataRangeStart.toIso8601String(),
      'dataRangeEnd': instance.dataRangeEnd.toIso8601String(),
      'computedAt': instance.computedAt.toIso8601String(),
    };
