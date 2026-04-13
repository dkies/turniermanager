// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_settings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoundSettingsDto _$RoundSettingsDtoFromJson(Map<String, dynamic> json) =>
    RoundSettingsDto(
      Map<String, int>.from(json['maxTeamsPerLeaguePerAgeGroup'] as Map),
      (json['playTimeInSeconds'] as num).toInt(),
      (json['breakTimeInSeconds'] as num).toInt(),
      json['roundName'] as String,
    );

Map<String, dynamic> _$RoundSettingsDtoToJson(RoundSettingsDto instance) =>
    <String, dynamic>{
      'maxTeamsPerLeaguePerAgeGroup': instance.maxTeamsPerLeaguePerAgeGroup,
      'playTimeInSeconds': instance.playTimeInSeconds,
      'breakTimeInSeconds': instance.breakTimeInSeconds,
      'roundName': instance.roundName,
    };
