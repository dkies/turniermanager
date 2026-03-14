// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'end_qualification_round_detailed_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EndQualificationRoundDetailedDto _$EndQualificationRoundDetailedDtoFromJson(
        Map<String, dynamic> json) =>
    EndQualificationRoundDetailedDto(
      Map<String, int>.from(json['maxTeamsPerLeaguePerAgeGroup'] as Map),
      (json['playTimeInSeconds'] as num).toInt(),
      (json['breakTimeInSeconds'] as num).toInt(),
      json['roundName'] as String,
    );

Map<String, dynamic> _$EndQualificationRoundDetailedDtoToJson(
        EndQualificationRoundDetailedDto instance) =>
    <String, dynamic>{
      'maxTeamsPerLeaguePerAgeGroup': instance.maxTeamsPerLeaguePerAgeGroup,
      'playTimeInSeconds': instance.playTimeInSeconds,
      'breakTimeInSeconds': instance.breakTimeInSeconds,
      'roundName': instance.roundName,
    };
