import 'package:json_annotation/json_annotation.dart';

part 'break_global_creation_dto.g.dart';

@JsonSerializable()
class BreakGlobalCreationDto {
  BreakGlobalCreationDto({
    required this.startTime,
    required this.amountOfBreaks,
    required this.message,
  });

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime startTime;
  int amountOfBreaks;
  String message;

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Invalid DateTime format');
  }

  static String _dateTimeToJson(DateTime dateTime) =>
      dateTime.toIso8601String();

  factory BreakGlobalCreationDto.fromJson(Map<String, dynamic> json) =>
      _$BreakGlobalCreationDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BreakGlobalCreationDtoToJson(this);
}
