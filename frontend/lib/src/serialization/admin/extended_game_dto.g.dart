// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extended_game_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtendedGameDto _$ExtendedGameDtoFromJson(Map<String, dynamic> json) =>
    ExtendedGameDto(
      json['id'] as String,
      DateTime.parse(json['startTime'] as String),
      (json['gameNumber'] as num).toInt(),
      json['teamA'] as String,
      json['teamB'] as String,
      json['pitch'] as String,
      json['leagueName'] as String,
      json['ageGroupName'] as String,
      (json['pointsTeamA'] as num).toInt(),
      (json['pointsTeamB'] as num).toInt(),
      ExtendedGameDto._statusFromJson(json['status'] as String),
    );

Map<String, dynamic> _$ExtendedGameDtoToJson(ExtendedGameDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'gameNumber': instance.gameNumber,
      'teamA': instance.teamA,
      'teamB': instance.teamB,
      'pitch': instance.pitch,
      'leagueName': instance.leagueName,
      'ageGroupName': instance.ageGroupName,
      'pointsTeamA': instance.pointsTeamA,
      'pointsTeamB': instance.pointsTeamB,
      'status': ExtendedGameDto._statusToJson(instance.status),
    };
