// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultsDto _$ResultsDtoFromJson(Map<String, dynamic> json) => ResultsDto(
      json['roundId'] as String,
      json['roundName'] as String,
    )..leagueTables = (json['leagueTables'] as List<dynamic>)
        .map((e) => LeagueDto.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$ResultsDtoToJson(ResultsDto instance) =>
    <String, dynamic>{
      'roundId': instance.roundId,
      'roundName': instance.roundName,
      'leagueTables': instance.leagueTables.map((e) => e.toJson()).toList(),
    };
