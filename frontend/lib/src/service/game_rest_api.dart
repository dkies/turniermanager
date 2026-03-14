import 'dart:convert';
import 'dart:math';
import 'package:download/download.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tournament_manager/src/serialization/admin/extended_game_dto.dart';
import 'package:tournament_manager/src/serialization/admin/game_score_update_dto.dart';
import 'package:tournament_manager/src/serialization/age_group_dto.dart';
import 'package:tournament_manager/src/serialization/referee/break_request_dto.dart';
import 'package:tournament_manager/src/serialization/referee/game_dto.dart';
import 'package:tournament_manager/src/serialization/referee/game_group_dto.dart';
import 'package:tournament_manager/src/serialization/referee/pitch_dto.dart';
import 'package:tournament_manager/src/serialization/referee/round_settings_dto.dart';
import 'package:tournament_manager/src/serialization/results/result_entry_dto.dart';
import 'package:tournament_manager/src/serialization/results/results_dto.dart';
import 'package:tournament_manager/src/serialization/schedule/league_dto.dart';
import 'package:tournament_manager/src/serialization/results/league_dto.dart'
    as resultleague;
import 'package:tournament_manager/src/serialization/game_status.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';
import 'package:tournament_manager/src/serialization/schedule/match_schedule_dto.dart';
import 'package:tournament_manager/src/serialization/schedule/match_schedule_entry_dto.dart';
import 'package:tournament_manager/src/service/rest_client.dart';
import 'package:collection/collection.dart';

abstract class GameRestApi {
  Future<MatchScheduleDto?> getSchedule(String ageGroupId);

  Future<ResultsDto?> getResults(String ageGroupId);

  Future<bool> endCurrentGames(
    DateTime originalStart,
    DateTime actualStart,
    DateTime end,
  );

  Future<bool> startNextRound(RoundSettingsDto settings);

  Future<List<AgeGroupDto>> getAllAgeGroups();
  Future<AgeGroupDto?> getAgeGroup(String ageGroupName);

  Future<List<GameGroupDto>> getCurrentRound();
  Future<List<ExtendedGameDto>> getAllGames();
  Future<bool> saveGame(int gameNumber, int teamAScore, int teamBScore);

  Future<bool> addBreak(
      DateTime start, DateTime end, String ageGroupId, String message);

  Future<List<PitchDto>> getAllPitches();
  Future<bool> printPitch(String pitchId);
}

class GameRestApiImplementation extends RestClient implements GameRestApi {
  late final String _baseUri;

  late final String getSchedulePath;
  late final String getResultsPath;
  late final Uri getAllAgeGroupsUri;
  late final Uri createRoundUri;
  late final Uri saveGameUri;
  late final Uri addBreakUri;
  late final Uri getAllPitchesUri;
  late final String printPitchPath;
  late final Uri getAllGameGroupsUri;
  late final Uri getAllGamesUri;

  GameRestApiImplementation(String baseUri) {
    _baseUri = baseUri;

    getSchedulePath = '$_baseUri/gameplan/agegroup/';
    getResultsPath = '$_baseUri/stats/agegroup/';
    getAllAgeGroupsUri = Uri.parse('$_baseUri/agegroups/getAll');
    createRoundUri = Uri.parse('$_baseUri/rounds');
    saveGameUri = Uri.parse('$_baseUri/games/score');
    addBreakUri = Uri.parse('$_baseUri/breaks/createBreak');
    getAllPitchesUri = Uri.parse('$_baseUri/pitches');
    printPitchPath = '$_baseUri/pitches/result-card/';
    getAllGameGroupsUri =
        Uri.parse('$_baseUri/gameplan/activeGamesSortedDateTimeList');
    getAllGamesUri =
        Uri.parse('$_baseUri/gameplan/get-all-games-listed-extended');
  }

  @override
  Future<MatchScheduleDto?> getSchedule(String ageGroupId) async {
    final uri = Uri.parse(getSchedulePath + ageGroupId);

    final response = await client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      return MatchScheduleDto.fromJson(json);
    }

    return null;
  }

  @override
  Future<ResultsDto?> getResults(String ageGroupId) async {
    final uri = Uri.parse(getResultsPath + ageGroupId);

    final response = await client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      return ResultsDto.fromJson(json);
    }

    return null;
  }

  @override
  Future<bool> endCurrentGames(
    DateTime originalStart,
    DateTime actualStart,
    DateTime end,
  ) async {
    // This endpoint has been removed from the backend
    // Keeping the method for backward compatibility but it will always return false
    return false;
  }

  @override
  Future<bool> startNextRound(RoundSettingsDto settings) async {
    try {
      var json = jsonEncode(settings);

      final response = await client.post(
        createRoundUri,
        body: json,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<AgeGroupDto>> getAllAgeGroups() async {
    final response = await client.get(getAllAgeGroupsUri, headers: headers);

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);

      if (json is List) {
        return json.map((e) => AgeGroupDto.fromJson(e)).toList();
      }
    }

    return [];
  }

  @override
  Future<AgeGroupDto?> getAgeGroup(String ageGroupName) async {
    var ageGroups = await getAllAgeGroups();
    var ageGroup =
        ageGroups.firstWhereOrNull((element) => element.name == ageGroupName);

    return ageGroup;
  }

  @override
  Future<List<GameGroupDto>> getCurrentRound() async {
    final response = await client.get(getAllGameGroupsUri, headers: headers);

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);

      if (json is List) {
        return json.map((e) => GameGroupDto.fromJson(e)).toList();
      }
    }

    return [];
  }

  @override
  Future<List<ExtendedGameDto>> getAllGames() async {
    final response = await client.get(getAllGamesUri, headers: headers);

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);

      if (json is List) {
        return json.map((e) => ExtendedGameDto.fromJson(e)).toList();
      }
    }

    return [];
  }

  @override
  Future<bool> saveGame(int gameNumber, int teamAScore, int teamBScore) async {
    try {
      var dto = GameScoreUpdateDto(gameNumber, teamAScore, teamBScore);
      var serialized = jsonEncode(dto);

      final response = await client.post(
        saveGameUri,
        body: serialized,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> addBreak(
      DateTime start, DateTime end, String ageGroupId, String message) async {
    try {
      var dto = BreakRequestDto(start, end, ageGroupId, message);
      var serialized = jsonEncode(dto);

      final response = await client.post(
        addBreakUri,
        body: serialized,
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      return false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<List<PitchDto>> getAllPitches() async {
    final response = await client.get(getAllPitchesUri, headers: headers);

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);

      if (json is List) {
        return json.map((e) => PitchDto.fromJson(e)).toList();
      }
    }

    return [];
  }

  @override
  Future<bool> printPitch(String pitchId) async {
    try {
      final uri = Uri.parse(printPitchPath + pitchId);

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        String fileName = 'Schiedsrichterzettel_Platz_$pitchId.pdf';

        final stream = Stream.fromIterable(response.bodyBytes);
        await download(stream, fileName);
        return true;
      }

      return false;
    } on Exception {
      return false;
    }
  }
}

class GameTestRestApi extends GameRestApi {
  var ageGroups = [
    AgeGroupDto('1', 'Altersklasse 1'),
    AgeGroupDto('2', 'Altersklasse 2'),
    AgeGroupDto('3', 'Altersklasse 3'),
  ];

  @override
  Future<bool> endCurrentGames(
    DateTime originalStart,
    DateTime actualStart,
    DateTime end,
  ) async {
    var seedBase = DateTime.now();
    var random = Random(seedBase.second + seedBase.millisecond);

    for (var gameGroup in gameGroups) {
      gameGroup.startTime = DateTime(
        2025,
        4,
        1,
        random.nextInt(25),
        random.nextInt(61),
        0,
      );
    }

    return true;
  }

  @override
  Future<List<AgeGroupDto>> getAllAgeGroups() async {
    return ageGroups;
  }

  @override
  Future<AgeGroupDto?> getAgeGroup(String ageGroupName) async {
    return ageGroups
        .firstWhereOrNull((element) => element.name == ageGroupName);
  }

  var gameGroups = [
    GameGroupDto(
      DateTime(2025, 4, 1, 15, 30, 0),
      2,
    )..games = [
        GameDto(
          'test-id-1',
          DateTime(2025, 4, 1, 15, 30, 0),
          1,
          "Team A",
          "Team B",
          "Feld 1",
          'Liga 1',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-2',
          DateTime(2025, 4, 1, 15, 30, 0),
          1,
          "Team A",
          "Team B",
          "Feld 2",
          'Liga 1',
          'Altersklasse 2',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-3',
          DateTime(2025, 4, 1, 15, 30, 0),
          2,
          "Team A",
          "Team B",
          "Feld 1",
          'Liga 2',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-4',
          DateTime(2025, 4, 1, 15, 30, 0),
          2,
          "Team A",
          "Team B",
          "Feld 2",
          'Liga 2',
          'Altersklasse 2',
          GameStatus.scheduled,
          ItemType.game,
        ),
      ],
    GameGroupDto(
      DateTime(2025, 4, 1, 15, 45, 0),
      12,
    )..games = [
        GameDto(
          'test-id-5',
          DateTime(2025, 4, 1, 15, 45, 0),
          1,
          "Team A",
          "Team B",
          "Feld 1",
          'Liga 1',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-6',
          DateTime(2025, 4, 1, 15, 45, 0),
          1,
          "Team A",
          "Team B",
          "Feld 2",
          'Liga 3',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-7',
          DateTime(2025, 4, 1, 15, 45, 0),
          2,
          "Team A",
          "Team B",
          "Feld 1",
          'Liga 1',
          'Altersklasse 4',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-8',
          DateTime(2025, 4, 1, 15, 45, 0),
          2,
          "Team A",
          "Team B",
          "Feld 2",
          'Liga 5',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.game,
        ),
      ],
  ];

  @override
  Future<List<GameGroupDto>> getCurrentRound() async {
    var prefs = await SharedPreferences.getInstance();
    var result = prefs.getString('currentlyRunningGames');

    if (result != null) {
      var converted = DateTime.tryParse(result);

      if (converted != null) {
        gameGroups[0].startTime = converted;
      }
    }

    return gameGroups;
  }

  @override
  Future<ResultsDto?> getResults(String ageGroupId) async {
    var resultList = List.generate(
      10,
      (index) {
        var randomGenerator = Random(index);
        var ownScoredGoals = randomGenerator.nextInt(100);
        var enemyScoredGoals = randomGenerator.nextInt(100);
        var result = ResultEntryDto(
          'Team$index',
          randomGenerator.nextInt(100), // victories
          randomGenerator.nextInt(100), // defeats
          randomGenerator.nextInt(100), // draws
          ownScoredGoals - enemyScoredGoals, // pointsDifference
          randomGenerator.nextInt(100), // totalPoints
          ownScoredGoals,
          enemyScoredGoals,
          randomGenerator.nextDouble() * 9 + 1, // avgScore (1.0–10.0)
        );

        return result;
      },
    );

    resultList.sort(
      (a, b) => a.totalPoints.compareTo(b.totalPoints),
    );

    return ResultsDto('test-round-id', 'Runde 1')
      ..leagueTables = List.generate(
        3,
        (index) {
          return resultleague.LeagueDto(
              'test-league-id-$index', 'Liga ${index + 1}', null)
            ..teams = resultList.reversed.toList();
        },
      );
  }

  @override
  Future<MatchScheduleDto?> getSchedule(String ageGroupId) async {
    int fieldCount = 1;
    int teamCount = 1;

    var scheduleList = List.generate(
      10,
      (innerIndex) {
        var startTime = DateTime.now();
        var result = MatchScheduleEntryDto(
          ItemType.game, // itemType
          "Platz $fieldCount", // pitchName
          startTime, // startTime
          startTime.add(const Duration(minutes: 20)), // endTime
          "team${teamCount++}", // teamAName
          "team${teamCount++}", // teamBName
          innerIndex + 1, // gameNumber
        );

        fieldCount++;
        if (fieldCount > 3) {
          fieldCount = 1;
        }

        if (teamCount > 4) {
          teamCount = 1;
        }

        return result;
      },
    );

    return MatchScheduleDto('Runde 1', 'Altersklasse 1')
      ..leagues = List.generate(
        8,
        (index) {
          return LeagueDto('Liga ${index + 1}')..entries = scheduleList;
        },
      );
  }

  @override
  Future<bool> startNextRound(RoundSettingsDto settings) async {
    return true;
  }

  @override
  Future<List<ExtendedGameDto>> getAllGames() async {
    return [
      ExtendedGameDto(
        'test-extended-id-1',
        DateTime.now().add(const Duration(minutes: 10)),
        1,
        'Team 1',
        'Team 2',
        'Platz 1',
        'Liga 1',
        'Altersklasse 1',
        2,
        3,
        GameStatus.scheduled,
      ),
      ExtendedGameDto(
        'test-extended-id-2',
        DateTime.now(),
        2,
        'Team 3',
        'Team 4',
        'Platz 2',
        'Liga 2',
        'Altersklasse 2',
        5,
        6,
        GameStatus.scheduled,
      ),
    ];
  }

  @override
  Future<bool> saveGame(int gameNumber, int teamAScore, int teamBScore) async {
    return true;
  }

  @override
  Future<bool> addBreak(
      DateTime start, DateTime end, String ageGroupId, String message) async {
    return true;
  }

  @override
  Future<List<PitchDto>> getAllPitches() async {
    return [
      PitchDto(
        '1',
        'Platz 1',
        null,
      ),
      PitchDto(
        '2',
        'Platz 2',
        null,
      ),
      PitchDto(
        '3',
        'Platz 3',
        null,
      ),
    ];
  }

  @override
  Future<bool> printPitch(String pitchId) async {
    return true;
  }
}
