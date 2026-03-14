import 'package:tournament_manager/src/model/referee/pitch.dart';
import 'package:tournament_manager/src/model/referee/team.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';

class Game {
  Game(
    this.gameNumber,
    this.pitch,
    this.teamA,
    this.teamB,
    this.leagueName,
    this.ageGroupName,
    this.type,
  );

  int gameNumber;
  Pitch pitch;
  Team teamA;
  Team teamB;
  String leagueName;
  String ageGroupName;
  ItemType type;
}
