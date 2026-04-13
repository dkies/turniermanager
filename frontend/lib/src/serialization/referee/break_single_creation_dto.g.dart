// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'break_single_creation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BreakSingleCreationDto _$BreakSingleCreationDtoFromJson(
        Map<String, dynamic> json) =>
    BreakSingleCreationDto(
      startTime: BreakSingleCreationDto._dateTimeFromJson(json['startTime']),
      amountOfBreaks: (json['amountOfBreaks'] as num).toInt(),
      ageGroupId: json['ageGroupName'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$BreakSingleCreationDtoToJson(
        BreakSingleCreationDto instance) =>
    <String, dynamic>{
      'startTime': BreakSingleCreationDto._dateTimeToJson(instance.startTime),
      'amountOfBreaks': instance.amountOfBreaks,
      'ageGroupName': instance.ageGroupId,
      'message': instance.message,
    };
