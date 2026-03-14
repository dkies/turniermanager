import 'package:json_annotation/json_annotation.dart';

part 'end_qualification_round_detailed_dto.g.dart';

/// Entspricht EndQualificationRoundDetailedDTO (Backend).
/// POST /turnier/end-qualification-detailed
@JsonSerializable()
class EndQualificationRoundDetailedDto {
  EndQualificationRoundDetailedDto(
    this.maxTeamsPerLeaguePerAgeGroup,
    this.playTimeInSeconds,
    this.breakTimeInSeconds,
    this.roundName,
  );

  /// Altersgruppen-ID (UUID-String) -> max. Teams pro Liga
  final Map<String, int> maxTeamsPerLeaguePerAgeGroup;
  final int playTimeInSeconds;
  final int breakTimeInSeconds;
  final String roundName;

  factory EndQualificationRoundDetailedDto.fromJson(
          Map<String, dynamic> json) =>
      _$EndQualificationRoundDetailedDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$EndQualificationRoundDetailedDtoToJson(this);
}
