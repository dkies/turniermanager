// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_score_update_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameScoreUpdateDto _$GameScoreUpdateDtoFromJson(Map<String, dynamic> json) =>
    GameScoreUpdateDto(
      (json['gameNumber'] as num).toInt(),
      (json['teamAScore'] as num).toInt(),
      (json['teamBScore'] as num).toInt(),
    );

Map<String, dynamic> _$GameScoreUpdateDtoToJson(GameScoreUpdateDto instance) =>
    <String, dynamic>{
      'gameNumber': instance.gameNumber,
      'teamAScore': instance.teamAScore,
      'teamBScore': instance.teamBScore,
    };
