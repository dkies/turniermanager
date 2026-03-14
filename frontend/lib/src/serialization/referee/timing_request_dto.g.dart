// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timing_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimingRequestDto _$TimingRequestDtoFromJson(Map<String, dynamic> json) =>
    TimingRequestDto(
      DateTime.parse(json['plannedStartTime'] as String),
    );

Map<String, dynamic> _$TimingRequestDtoToJson(TimingRequestDto instance) =>
    <String, dynamic>{
      'plannedStartTime': instance.plannedStartTime.toIso8601String(),
    };
