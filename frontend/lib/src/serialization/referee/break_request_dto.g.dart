// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'break_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BreakRequestDto _$BreakRequestDtoFromJson(Map<String, dynamic> json) =>
    BreakRequestDto(
      DateTime.parse(json['startTime'] as String),
      DateTime.parse(json['endTime'] as String),
      json['ageGroupName'] as String,
      json['message'] as String,
    );

Map<String, dynamic> _$BreakRequestDtoToJson(BreakRequestDto instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'ageGroupName': instance.ageGroupName,
      'message': instance.message,
    };
