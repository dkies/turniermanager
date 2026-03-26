import 'package:tournament_manager/src/serialization/game_status.dart';

class ExtendedGame {
  ExtendedGame(
    this.gameNumber,
    this.pitch,
    this.teamA,
    this.teamB,
    this.leagueName,
    this.ageGroupName,
    this.pointsTeamA,
    this.pointsTeamB,
    this.startTime,
    this.status,
  );

  int gameNumber;
  String pitch;
  String teamA;
  String teamB;
  String leagueName;
  String ageGroupName;
  int pointsTeamA;
  int pointsTeamB;
  DateTime startTime;
  GameStatus status;
}
