// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'break_global_creation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BreakGlobalCreationDto _$BreakGlobalCreationDtoFromJson(
        Map<String, dynamic> json) =>
    BreakGlobalCreationDto(
      startTime: BreakGlobalCreationDto._dateTimeFromJson(json['startTime']),
      amountOfBreaks: (json['amountOfBreaks'] as num).toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$BreakGlobalCreationDtoToJson(
        BreakGlobalCreationDto instance) =>
    <String, dynamic>{
      'startTime': BreakGlobalCreationDto._dateTimeToJson(instance.startTime),
      'amountOfBreaks': instance.amountOfBreaks,
      'message': instance.message,
    };
