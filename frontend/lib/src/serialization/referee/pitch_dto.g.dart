// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pitch_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PitchDto _$PitchDtoFromJson(Map<String, dynamic> json) => PitchDto(
      json['id'] as String,
      json['name'] as String,
      json['ageGroup'] == null
          ? null
          : AgeGroupDto.fromJson(json['ageGroup'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PitchDtoToJson(PitchDto instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'ageGroup': instance.ageGroup,
    };
