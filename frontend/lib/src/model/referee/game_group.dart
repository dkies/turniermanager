import 'package:tournament_manager/src/model/referee/game.dart';

class GameGroup {
  GameGroup(
    this.startTime,
    this.playTimeInSeconds,
  );

  DateTime startTime;
  int playTimeInSeconds;
  List<Game> games = [];
}
