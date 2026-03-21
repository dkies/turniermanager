import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/model/referee/pitch.dart';
import 'package:tournament_manager/src/model/referee/round_settings.dart';
import 'package:tournament_manager/src/model/results/results.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule.dart';
import 'package:tournament_manager/src/manager/game_manager_base.dart';

/// In-memory [GameManager] for widget tests (no REST).
class FakeGameManager extends ChangeNotifier implements GameManager {
  FakeGameManager({
    MatchSchedule? schedule,
    Results? results,
    List<AgeGroup>? ageGroups,
    List<GameGroup>? gameGroups,
    List<ExtendedGame>? games,
    List<Pitch>? pitches,
  })  : _schedule = schedule ?? MatchSchedule('Testrunde'),
        _results = results ?? Results('Testrunde'),
        _ageGroups = ageGroups ?? [],
        _gameGroups = gameGroups ?? [],
        _games = games ?? [],
        _pitches = pitches ?? [] {
    getScheduleCommand = Command.createAsyncNoResult<String>((_) async {});
    getScheduleByAgeGroupNameCommand =
        Command.createAsyncNoResult<String>((_) async {});

    getResultsCommand = Command.createAsyncNoResult<String>((_) async {});
    getResultsByAgeGroupNameCommand =
        Command.createAsyncNoResult<String>((_) async {});

    endCurrentGamesCommand = Command.createAsync<DateTime, bool>(
      (_) async {
        endCurrentGamesInvocations++;
        return endCurrentGamesReturns;
      },
      initialValue: false,
    );
    startNextRoundCommand = Command.createAsync<RoundSettings, bool>(
      (_) async {
        startNextRoundInvocations++;
        return startNextRoundReturns;
      },
      initialValue: false,
    );
    getCurrentRoundCommand = Command.createAsyncNoParamNoResult(() async {
      getCurrentRoundInvocations++;
    });

    getAgeGroupsCommand = Command.createAsyncNoParamNoResult(() async {});

    getAllGamesCommand = Command.createAsyncNoParamNoResult(() async {});

    saveGameCommand = Command.createAsync<
        (int gameNumber, int teamAScore, int teamBScore), bool>(
      (_) async => false,
      initialValue: false,
    );

    addBreakCommand = Command.createAsync<
        (bool isGlobal, DateTime startTime, int amountOfBreaks, String message,
            String? ageGroupId),
        bool>(
      (_) async {
        addBreakInvocations++;
        return addBreakReturns;
      },
      initialValue: false,
    );

    deleteBreakCommand = Command.createAsync<String, bool>(
      (_) async {
        deleteBreakInvocations++;
        return deleteBreakReturns;
      },
      initialValue: false,
    );

    getAllPitchesCommand = Command.createAsyncNoParamNoResult(() async {});

    printPitchCommand = Command.createAsync<String, bool>(
      (_) async => false,
      initialValue: false,
    );
    printAllPitchesCommand = Command.createAsyncNoParam<bool>(
      () async => false,
      initialValue: false,
    );
    printResultsCommand = Command.createAsync<String, bool>(
      (_) async => false,
      initialValue: false,
    );
    printAllResultsCommand = Command.createAsyncNoParam<bool>(
      () async => false,
      initialValue: false,
    );
  }

  MatchSchedule _schedule;
  Results _results;
  List<AgeGroup> _ageGroups;
  List<GameGroup> _gameGroups;
  final List<ExtendedGame> _games;
  final List<Pitch> _pitches;

  /// Configure outcomes for integration / widget tests (default: false).
  bool endCurrentGamesReturns = false;
  int endCurrentGamesInvocations = 0;

  bool startNextRoundReturns = false;
  int startNextRoundInvocations = 0;

  bool addBreakReturns = false;
  int addBreakInvocations = 0;

  bool deleteBreakReturns = false;
  int deleteBreakInvocations = 0;

  int getCurrentRoundInvocations = 0;

  @override
  late Command<String, void> getScheduleCommand;

  @override
  late Command<String, void> getScheduleByAgeGroupNameCommand;

  @override
  late Command<String, void> getResultsCommand;

  @override
  late Command<String, void> getResultsByAgeGroupNameCommand;

  @override
  late Command<DateTime, bool> endCurrentGamesCommand;

  @override
  late Command<RoundSettings, bool> startNextRoundCommand;

  @override
  late Command<void, void> getCurrentRoundCommand;

  @override
  late Command<void, void> getAgeGroupsCommand;

  @override
  late Command<void, void> getAllGamesCommand;

  @override
  late Command<(int gameNumber, int teamAScore, int teamBScore), bool>
      saveGameCommand;

  @override
  late Command<
      (bool isGlobal, DateTime startTime, int amountOfBreaks, String message,
          String? ageGroupId),
      bool> addBreakCommand;

  @override
  late Command<String, bool> deleteBreakCommand;

  @override
  late Command<void, void> getAllPitchesCommand;

  @override
  late Command<String, bool> printPitchCommand;

  @override
  late Command<void, bool> printAllPitchesCommand;

  @override
  late Command<String, bool> printResultsCommand;

  @override
  late Command<void, bool> printAllResultsCommand;

  @override
  MatchSchedule get schedule => _schedule;

  @override
  Results get results => _results;

  @override
  List<GameGroup> get gameGroups => _gameGroups;

  @override
  List<AgeGroup> get ageGroups => _ageGroups;

  @override
  List<ExtendedGame> get games => _games;

  @override
  List<Pitch> get pitches => _pitches;

  @override
  AgeGroup? getAgeGroupByName(String name) {
    final filtered = _ageGroups.where((e) => e.name == name);
    return filtered.isNotEmpty ? filtered.first : null;
  }

  /// Mutators for tests that need to simulate API updates.
  void setSchedule(MatchSchedule value) {
    _schedule = value;
    notifyListeners();
  }

  void setResults(Results value) {
    _results = value;
    notifyListeners();
  }

  void setAgeGroups(List<AgeGroup> value) {
    _ageGroups = value;
    notifyListeners();
  }

  void setGameGroups(List<GameGroup> value) {
    _gameGroups = value;
    notifyListeners();
  }
}
