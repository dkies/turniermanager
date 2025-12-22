// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultEntryDto _$ResultEntryDtoFromJson(Map<String, dynamic> json) =>
    ResultEntryDto(
      json['teamName'] as String,
      (json['victories'] as num).toInt(),
      (json['defeats'] as num).toInt(),
      (json['draws'] as num).toInt(),
      (json['pointsDifference'] as num).toInt(),
      (json['totalPoints'] as num).toInt(),
      (json['ownScoredGoals'] as num).toInt(),
      (json['enemyScoredGoals'] as num).toInt(),
      (json['avgScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ResultEntryDtoToJson(ResultEntryDto instance) =>
    <String, dynamic>{
      'teamName': instance.teamName,
      'victories': instance.victories,
      'defeats': instance.defeats,
      'draws': instance.draws,
      'pointsDifference': instance.pointsDifference,
      'totalPoints': instance.totalPoints,
      'ownScoredGoals': instance.ownScoredGoals,
      'enemyScoredGoals': instance.enemyScoredGoals,
      'avgScore': instance.avgScore,
    };
