import 'package:json_annotation/json_annotation.dart';

part 'break_single_creation_dto.g.dart';

@JsonSerializable()
class BreakSingleCreationDto {
  BreakSingleCreationDto({
    required this.startTime,
    required this.amountOfBreaks,
    required this.ageGroupId,
    required this.message,
  });

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime startTime;
  int amountOfBreaks;
  @JsonKey(name: 'ageGroupName')
  String ageGroupId;
  String message;

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Invalid DateTime format');
  }

  static String _dateTimeToJson(DateTime dateTime) =>
      dateTime.toIso8601String();

  factory BreakSingleCreationDto.fromJson(Map<String, dynamic> json) =>
      _$BreakSingleCreationDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BreakSingleCreationDtoToJson(this);
}
