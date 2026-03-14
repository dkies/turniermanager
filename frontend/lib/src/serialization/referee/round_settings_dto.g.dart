// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_settings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoundSettingsDto _$RoundSettingsDtoFromJson(Map<String, dynamic> json) =>
    RoundSettingsDto(
      GameSettingsDto.fromJson(json['gameSettings'] as Map<String, dynamic>),
      roundName: json['roundName'] as String? ?? 'Qualifikation',
    )..numberPerRounds = Map<String, int>.from(json['numberPerRounds'] as Map);

Map<String, dynamic> _$RoundSettingsDtoToJson(RoundSettingsDto instance) =>
    <String, dynamic>{
      'numberPerRounds': instance.numberPerRounds,
      'gameSettings': instance.gameSettings.toJson(),
      'roundName': instance.roundName,
    };
