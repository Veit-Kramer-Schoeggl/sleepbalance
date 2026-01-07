// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailVerification _$EmailVerificationFromJson(Map<String, dynamic> json) =>
    EmailVerification(
      id: json['id'] as String,
      email: json['email'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      isUsed: json['isUsed'] as bool? ?? false,
    );

Map<String, dynamic> _$EmailVerificationToJson(EmailVerification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'code': instance.code,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'isUsed': instance.isUsed,
    };
