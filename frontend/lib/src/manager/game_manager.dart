import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:tournament_manager/src/mapper/admin_mapper.dart';
import 'package:tournament_manager/src/mapper/match_schedule_mapper.dart';
import 'package:tournament_manager/src/mapper/referee_mapper.dart';
import 'package:tournament_manager/src/mapper/results_mapper.dart';
import 'package:tournament_manager/src/mapper/age_group_mapper.dart';
import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:tournament_manager/src/serialization/admin/extended_game_dto.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/model/referee/pitch.dart';
import 'package:tournament_manager/src/model/referee/round_settings.dart';
import 'package:tournament_manager/src/model/results/results.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule.dart';
import 'package:tournament_manager/src/service/game_rest_api.dart';
import 'package:watch_it/watch_it.dart';

abstract class GameManager extends ChangeNotifier {
  late Command<String, void> getScheduleCommand;
  late Command<String, void> getScheduleByAgeGroupNameCommand;

  late Command<String, void> getResultsCommand;
  late Command<String, void> getResultsByAgeGroupNameCommand;

  late Command<(DateTime originalStart, DateTime actualStart, DateTime end),
      bool> endCurrentGamesCommand;
  late Command<RoundSettings, bool> startNextRoundCommand;
  late Command<void, void> getCurrentRoundCommand;

  late Command<void, void> getAgeGroupsCommand;

  late Command<void, void> getAllGamesCommand;
  late Command<(int gameNumber, int teamAScore, int teamBScore), bool>
      saveGameCommand;

  late Command<
      (DateTime start, DateTime end, String ageGroupId, String message),
      bool> addBreakCommand;

  late Command<void, void> getAllPitchesCommand;
  late Command<String, bool> printPitchCommand;
  late Command<void, bool> printAllPitchesCommand;

  AgeGroup? getAgeGroupByName(String name);

  MatchSchedule get schedule;
  Results get results;
  List<GameGroup> get gameGroups;
  List<AgeGroup> get ageGroups;

  List<ExtendedGame> get games;

  List<Pitch> get pitches;
}

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
  late Command<(DateTime originalStart, DateTime actualStart, DateTime end),
      bool> endCurrentGamesCommand;
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
  late Command<(DateTime, DateTime, String, String), bool> addBreakCommand;

  @override
  late Command<void, void> getAllPitchesCommand;
  @override
  late Command<String, bool> printPitchCommand;
  @override
  late Command<void, bool> printAllPitchesCommand;

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
      (param) async {
        return await _gameRestApi.endCurrentGames(param.$1, param.$2, param.$3);
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
        return await _gameRestApi.saveGame(
            gameResult.$1, gameResult.$2, gameResult.$3);
      },
      initialValue: false,
    );

    addBreakCommand = Command.createAsync(
      (breakRequest) async {
        return await _gameRestApi.addBreak(
          breakRequest.$1,
          breakRequest.$2,
          breakRequest.$3,
          breakRequest.$4,
        );
      },
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
  }

  @override
  AgeGroup? getAgeGroupByName(String name) {
    var filtered = ageGroups.where((element) => element.name == name);

    return filtered.isNotEmpty ? filtered.first : null;
  }
}
