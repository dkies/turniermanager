// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_group_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameGroupDto _$GameGroupDtoFromJson(Map<String, dynamic> json) => GameGroupDto(
      DateTime.parse(json['startTime'] as String),
      json['gameDurationInMinutes'] != null
          ? (json['gameDurationInMinutes'] as num).toInt()
          : null,
    )..games = (json['games'] as List<dynamic>)
        .map((e) => GameDto.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$GameGroupDtoToJson(GameGroupDto instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'gameDurationInMinutes': instance.gameDurationInMinutes,
      'games': instance.games.map((e) => e.toJson()).toList(),
    };
