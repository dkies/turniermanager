import 'package:tournament_manager/src/serialization/schedule/item_type.dart';

class MatchScheduleEntry {
  MatchScheduleEntry(
    this.itemType,
    this.pitchName,
    this.teamAName,
    this.teamBName,
    this.startTime,
    this.endTime,
  );

  ItemType itemType;
  String pitchName;
  String teamAName;
  String teamBName;
  DateTime startTime;
  DateTime endTime;
}
