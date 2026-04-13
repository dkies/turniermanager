import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:tournament_manager/src/mapper/admin_mapper.dart';
import 'package:tournament_manager/src/mapper/age_group_mapper.dart';
import 'package:tournament_manager/src/mapper/match_schedule_mapper.dart';
import 'package:tournament_manager/src/mapper/referee_mapper.dart';
import 'package:tournament_manager/src/mapper/results_mapper.dart';
import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/model/referee/pitch.dart';
import 'package:tournament_manager/src/model/referee/round_settings.dart';
import 'package:tournament_manager/src/model/results/results.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule.dart';
import 'package:tournament_manager/src/serialization/admin/extended_game_dto.dart';
import 'package:tournament_manager/src/serialization/game_status.dart';
import 'package:tournament_manager/src/serialization/referee/break_global_creation_dto.dart';
import 'package:tournament_manager/src/serialization/referee/break_single_creation_dto.dart';
import 'package:tournament_manager/src/service/game_rest_api.dart';
import 'package:watch_it/watch_it.dart';

import 'game_manager_base.dart';

class GameManagerImplementation extends ChangeNotifier implements GameManager {
  late final GameRestApi _gameRestApi;
  late final MatchScheduleMapper _scheduleMapper;
  late final ResultsMapper _resultsMapper;
  late final RefereeMapper _refereeMapper;
  late final AgeGroupMapper _ageGroupMapper;
  late final AdminMapper _adminMapper;

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
  late Command<(int, int, int), bool> saveGameCommand;

  @override
  late Command<(bool, DateTime, int, String, String?), bool> addBreakCommand;

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

  MatchSchedule _schedule = MatchSchedule('Runde ??');

  @override
  MatchSchedule get schedule => _schedule;
  set schedule(MatchSchedule value) {
    _schedule = value;
    notifyListeners();
  }

  Results _results = Results('Runde ??');
  @override
  Results get results => _results;
  set results(Results value) {
    _results = value;
    notifyListeners();
  }

  List<GameGroup> _gameGroups = [];
  @override
  List<GameGroup> get gameGroups => _gameGroups;
  set gameGroups(List<GameGroup> value) {
    _gameGroups = value;
    notifyListeners();
  }

  List<AgeGroup> _ageGroups = [];
  @override
  List<AgeGroup> get ageGroups => _ageGroups;
  set ageGroups(List<AgeGroup> value) {
    _ageGroups = value;
    notifyListeners();
  }

  List<ExtendedGame> _games = [];
  @override
  List<ExtendedGame> get games => _games;
  set games(List<ExtendedGame> value) {
    _games = value;
    notifyListeners();
  }

  List<Pitch> _pitches = [];
  @override
  List<Pitch> get pitches => _pitches;
  set pitches(List<Pitch> value) {
    _pitches = value;
    notifyListeners();
  }

  GameManagerImplementation() {
    _gameRestApi = di<GameRestApi>();
    _scheduleMapper = MatchScheduleMapper();
    _resultsMapper = ResultsMapper();
    _refereeMapper = RefereeMapper();
    _ageGroupMapper = AgeGroupMapper();
    _adminMapper = AdminMapper();

    getScheduleCommand = Command.createAsyncNoResult(
      (input) async {
        var result = await _gameRestApi.getSchedule(input);
        if (result == null) {
          return; //TODO: error handling
        }

        schedule = _scheduleMapper.map(result);
      },
    );

    getScheduleByAgeGroupNameCommand = Command.createAsyncNoResult(
      (ageGroupName) async {
        var agegroup = await _gameRestApi.getAgeGroup(ageGroupName);

        if (agegroup == null) {
          return;
        }

        var result = await _gameRestApi.getSchedule(agegroup.id);
        if (result == null) {
          return; //TODO: error handling
        }

        schedule = _scheduleMapper.map(result);
      },
    );

    getResultsCommand = Command.createAsyncNoResult(
      (input) async {
        var result = await _gameRestApi.getResults(input);
        if (result == null) {
          return; //TODO: error handling
        }

        results = _resultsMapper.map(result);
      },
    );

    getResultsByAgeGroupNameCommand = Command.createAsyncNoResult(
      (ageGroupName) async {
        var agegroup = await _gameRestApi.getAgeGroup(ageGroupName);

        if (agegroup == null) {
          return;
        }

        var result = await _gameRestApi.getResults(agegroup.id);
        if (result == null) {
          return; //TODO: error handling
        }

        results = _resultsMapper.map(result);
      },
    );

    endCurrentGamesCommand = Command.createAsync(
      (originalStart) async {
        return await _gameRestApi.endCurrentGames(originalStart);
      },
      initialValue: false,
    );

    startNextRoundCommand = Command.createAsync(
      (settings) async {
        return await _gameRestApi
            .startNextRound(_refereeMapper.reverseMapRoundSettings(settings));
      },
      initialValue: false,
    );

    getCurrentRoundCommand = Command.createAsyncNoParamNoResult(() async {
      var result = await _gameRestApi.getCurrentRound();

      gameGroups = result
          .map((gameGroup) => _refereeMapper.mapGameGroup(gameGroup))
          .toList();
    });

    getAgeGroupsCommand = Command.createAsyncNoParamNoResult(
      () async {
        var result = await _gameRestApi.getAllAgeGroups();

        ageGroups = result.map((e) => _ageGroupMapper.map(e)).toList();
      },
    );

    getAllGamesCommand = Command.createAsyncNoParamNoResult(
      () async {
        List<ExtendedGameDto> result = await _gameRestApi.getAllGames();
        games = result.map((e) => _adminMapper.map(e)).toList();
      },
    );

    saveGameCommand = Command.createAsync(
      (gameResult) async {
        final ok = await _gameRestApi.saveGame(
          gameResult.$1,
          gameResult.$2,
          gameResult.$3,
        );
        if (!ok) {
          return false;
        }
        final refreshed = await _gameRestApi.getAllGames();
        if (refreshed.isNotEmpty) {
          games = refreshed.map((e) => _adminMapper.map(e)).toList();
        } else {
          _applySavedGameLocally(
            gameResult.$1,
            gameResult.$2,
            gameResult.$3,
          );
        }
        return true;
      },
      initialValue: false,
    );

    addBreakCommand = Command.createAsync(
      (req) async {
        if (req.$1) {
          return await _gameRestApi.createGlobalBreak(
            BreakGlobalCreationDto(
              startTime: req.$2,
              amountOfBreaks: req.$3,
              message: req.$4,
            ),
          );
        }
        final ageGroupId = req.$5;
        if (ageGroupId == null || ageGroupId.isEmpty) {
          return false;
        }
        return await _gameRestApi.createBreakForAgeGroup(
          BreakSingleCreationDto(
            startTime: req.$2,
            amountOfBreaks: req.$3,
            ageGroupId: ageGroupId,
            message: req.$4,
          ),
        );
      },
      initialValue: false,
    );

    deleteBreakCommand = Command.createAsync(
      (breakId) async => await _gameRestApi.deleteBreak(breakId),
      initialValue: false,
    );

    getAllPitchesCommand = Command.createAsyncNoParamNoResult(
      () async {
        var result = await _gameRestApi.getAllPitches();
        pitches = result.map((e) => _refereeMapper.mapPitch(e)).toList();
      },
    );

    printPitchCommand = Command.createAsync(
      (pitchId) async {
        return await _gameRestApi.printPitch(pitchId);
      },
      initialValue: false,
    );

    printAllPitchesCommand = Command.createAsyncNoParam(
      () async {
        var result = true;
        for (var pitch in pitches) {
          result = await _gameRestApi.printPitch(pitch.id);
        }

        return result;
      },
      initialValue: false,
    );

    printResultsCommand = Command.createAsync(
      (ageGroupId) async {
        return await _gameRestApi.printResults(ageGroupId);
      },
      initialValue: false,
    );

    printAllResultsCommand = Command.createAsyncNoParam(
      () async {
        var result = true;
        for (var ageGroup in ageGroups) {
          result = await _gameRestApi.printResults(ageGroup.id);
        }
        return result;
      },
      initialValue: false,
    );
  }

  @override
  AgeGroup? getAgeGroupByName(String name) {
    var filtered = ageGroups.where((element) => element.name == name);

    return filtered.isNotEmpty ? filtered.first : null;
  }

  /// If reloading all games after save yields no data, still update the row so
  /// status colours and scores match the server (typically completed → completedAndStated).
  void _applySavedGameLocally(
    int gameNumber,
    int teamAScore,
    int teamBScore,
  ) {
    final index = _games.indexWhere((g) => g.gameNumber == gameNumber);
    if (index == -1) {
      notifyListeners();
      return;
    }
    final g = _games[index];
    final nextStatus = g.status == GameStatus.completed
        ? GameStatus.completedAndStated
        : g.status;
    final updated = ExtendedGame(
      g.gameNumber,
      g.pitch,
      g.teamA,
      g.teamB,
      g.leagueName,
      g.ageGroupName,
      teamAScore,
      teamBScore,
      g.startTime,
      nextStatus,
    );
    final copy = List<ExtendedGame>.from(_games);
    copy[index] = updated;
    games = copy;
  }
}
