// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameDto _$GameDtoFromJson(Map<String, dynamic> json) => GameDto(
      json['id'] as String,
      DateTime.parse(json['startTime'] as String),
      (json['gameNumber'] as num).toInt(),
      json['teamA'] as String,
      json['teamB'] as String,
      json['pitch'] as String,
      json['leagueName'] as String,
      json['ageGroupName'] as String,
      GameDto._statusFromJson(json['status'] as String),
      GameDto._typeFromJson(json['type'] as String),
    );

Map<String, dynamic> _$GameDtoToJson(GameDto instance) => <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'gameNumber': instance.gameNumber,
      'teamA': instance.teamA,
      'teamB': instance.teamB,
      'pitch': instance.pitch,
      'leagueName': instance.leagueName,
      'ageGroupName': instance.ageGroupName,
      'status': GameDto._statusToJson(instance.status),
      'type': GameDto._typeToJson(instance.type),
    };
