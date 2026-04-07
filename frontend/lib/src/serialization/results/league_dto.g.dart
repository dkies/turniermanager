// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'league_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeagueDto _$LeagueDtoFromJson(Map<String, dynamic> json) => LeagueDto(
      json['leagueId'] as String,
      json['leagueName'] as String,
      json['ageGroup'] == null
          ? null
          : AgeGroupDto.fromJson(json['ageGroup'] as Map<String, dynamic>),
    )..teams = (json['teams'] as List<dynamic>)
        .map((e) => ResultEntryDto.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$LeagueDtoToJson(LeagueDto instance) => <String, dynamic>{
      'leagueId': instance.leagueId,
      'leagueName': instance.leagueName,
      'ageGroup': instance.ageGroup?.toJson(),
      'teams': instance.teams.map((e) => e.toJson()).toList(),
    };
