import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/model/referee/pitch.dart';
import 'package:tournament_manager/src/model/referee/round_settings.dart';
import 'package:tournament_manager/src/model/results/results.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule.dart';

/// Contract for tournament state and REST-backed commands.
/// Kept separate from [GameManagerImplementation] so tests can depend on this
/// file without importing HTTP / web-only code.
abstract class GameManager extends ChangeNotifier {
  late Command<String, void> getScheduleCommand;
  late Command<String, void> getScheduleByAgeGroupNameCommand;

  late Command<String, void> getResultsCommand;
  late Command<String, void> getResultsByAgeGroupNameCommand;

  late Command<DateTime, bool> endCurrentGamesCommand;
  late Command<RoundSettings, bool> startNextRoundCommand;
  late Command<void, void> getCurrentRoundCommand;

  late Command<void, void> getAgeGroupsCommand;

  late Command<void, void> getAllGamesCommand;
  late Command<(int gameNumber, int teamAScore, int teamBScore), bool>
      saveGameCommand;

  /// (isGlobal, startTime, amountOfBreaks, message, ageGroupId when !isGlobal)
  late Command<
      (bool isGlobal, DateTime startTime, int amountOfBreaks, String message,
          String? ageGroupId),
      bool> addBreakCommand;

  late Command<String, bool> deleteBreakCommand;

  late Command<void, void> getAllPitchesCommand;
  late Command<String, bool> printPitchCommand;
  late Command<void, bool> printAllPitchesCommand;
  late Command<String, bool> printResultsCommand;
  late Command<void, bool> printAllResultsCommand;

  AgeGroup? getAgeGroupByName(String name);

  MatchSchedule get schedule;
  Results get results;
  List<GameGroup> get gameGroups;
  List<AgeGroup> get ageGroups;

  List<ExtendedGame> get games;

  List<Pitch> get pitches;
}
