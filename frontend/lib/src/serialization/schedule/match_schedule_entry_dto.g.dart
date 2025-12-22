// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_schedule_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchScheduleEntryDto _$MatchScheduleEntryDtoFromJson(
        Map<String, dynamic> json) =>
    MatchScheduleEntryDto(
      MatchScheduleEntryDto._itemTypeFromJson(json['itemType'] as String),
      json['pitchName'] as String,
      MatchScheduleEntryDto._dateTimeFromJson(json['startTime']),
      MatchScheduleEntryDto._dateTimeFromJson(json['endTime']),
      json['teamAName'] as String?,
      json['teamBName'] as String?,
      (json['gameNumber'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MatchScheduleEntryDtoToJson(
        MatchScheduleEntryDto instance) =>
    <String, dynamic>{
      'itemType': MatchScheduleEntryDto._itemTypeToJson(instance.itemType),
      'pitchName': instance.pitchName,
      'startTime': MatchScheduleEntryDto._dateTimeToJson(instance.startTime),
      'endTime': MatchScheduleEntryDto._dateTimeToJson(instance.endTime),
      'teamAName': instance.teamAName,
      'teamBName': instance.teamBName,
      'gameNumber': instance.gameNumber,
    };
