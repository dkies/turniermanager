import 'dart:convert';
import 'dart:math';
import 'package:download/download.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tournament_manager/src/serialization/admin/extended_game_dto.dart';
import 'package:tournament_manager/src/serialization/admin/game_score_update_dto.dart';
import 'package:tournament_manager/src/serialization/age_group_dto.dart';
import 'package:tournament_manager/src/serialization/referee/break_global_creation_dto.dart';
import 'package:tournament_manager/src/serialization/referee/break_single_creation_dto.dart';
import 'package:tournament_manager/src/serialization/referee/game_dto.dart';
import 'package:tournament_manager/src/serialization/referee/game_group_dto.dart';
import 'package:tournament_manager/src/serialization/referee/pitch_dto.dart';
import 'package:tournament_manager/src/serialization/referee/round_settings_dto.dart';
import 'package:tournament_manager/src/serialization/referee/timing_request_dto.dart';
import 'package:tournament_manager/src/serialization/results/result_entry_dto.dart';
import 'package:tournament_manager/src/serialization/results/results_dto.dart';
import 'package:tournament_manager/src/serialization/schedule/league_dto.dart';
import 'package:tournament_manager/src/serialization/results/league_dto.dart'
    as resultleague;
import 'package:tournament_manager/src/serialization/game_status.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';
import 'package:tournament_manager/src/serialization/schedule/match_schedule_dto.dart';
import 'package:tournament_manager/src/serialization/schedule/match_schedule_entry_dto.dart';
import 'package:http/http.dart' as http;
import 'package:tournament_manager/src/service/rest_client.dart';
import 'package:collection/collection.dart';

abstract class GameRestApi {
  Future<MatchScheduleDto?> getSchedule(String ageGroupId);

  Future<ResultsDto?> getResults(String ageGroupId);

  Future<bool> endCurrentGames(DateTime originalStart);

  Future<bool> startNextRound(RoundSettingsDto settings);

  Future<List<AgeGroupDto>> getAllAgeGroups();
  Future<AgeGroupDto?> getAgeGroup(String ageGroupName);

  Future<List<GameGroupDto>> getCurrentRound();
  Future<List<ExtendedGameDto>> getAllGames();
  Future<bool> saveGame(int gameNumber, int teamAScore, int teamBScore);

  Future<bool> createBreakForAgeGroup(BreakSingleCreationDto dto);
  Future<bool> createGlobalBreak(BreakGlobalCreationDto dto);
  Future<bool> deleteBreak(String breakId);

  Future<List<PitchDto>> getAllPitches();
  Future<bool> printPitch(String pitchId);
  Future<bool> printResults(String ageGroupId);
}

class GameRestApiImplementation extends RestClient implements GameRestApi {
  late final String _baseUri;

  late final String getSchedulePath;
  late final String getResultsPath;
  late final Uri getAllAgeGroupsUri;
  late final Uri saveGameUri;
  late final Uri createBreakUri;
  late final Uri createGlobalBreakUri;
  late final Uri deleteBreakUri;
  late final Uri getAllPitchesUri;
  late final String printPitchPath;
  late final String printResultsPath;
  late final Uri getAllGameGroupsUri;
  late final Uri getAllGamesUri;
  late final Uri refreshTimingsUri;
  late final Uri endQualificationDetailedUri;

  GameRestApiImplementation(String baseUri, {required http.Client httpClient})
      : super(httpClient) {
    _baseUri = baseUri;

    getSchedulePath = '$_baseUri/gameplan/agegroup/';
    getResultsPath = '$_baseUri/stats/agegroup/';
    getAllAgeGroupsUri = Uri.parse('$_baseUri/agegroups/getAll');
    endQualificationDetailedUri =
        Uri.parse('$_baseUri/turnier/end-qualification-detailed');
    saveGameUri = Uri.parse('$_baseUri/games/score');
    createBreakUri = Uri.parse('$_baseUri/breaks/createBreak');
    createGlobalBreakUri = Uri.parse('$_baseUri/breaks/createGlobalBreak');
    deleteBreakUri = Uri.parse('$_baseUri/breaks/delete');
    getAllPitchesUri = Uri.parse('$_baseUri/pitches');
    printPitchPath = '$_baseUri/pitches/result-card/';
    printResultsPath = '$_baseUri/reporting/tournament-results/';
    getAllGameGroupsUri =
        Uri.parse('$_baseUri/gameplan/activeGamesSortedDateTimeList');
    getAllGamesUri =
        Uri.parse('$_baseUri/gameplan/get-all-games-listed-extended');
    refreshTimingsUri = Uri.parse('$_baseUri/games/refresh-timings');
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
  Future<bool> endCurrentGames(DateTime originalStart) async {
    try {
      final dto = TimingRequestDto(originalStart);
      final json = jsonEncode(dto.toJson());

      final response = await client.post(
        refreshTimingsUri,
        body: json,
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> startNextRound(RoundSettingsDto settings) async {
    try {
      final json = jsonEncode(settings.toJson());

      final response = await client.post(
        endQualificationDetailedUri,
        body: json,
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
  Future<bool> createBreakForAgeGroup(BreakSingleCreationDto dto) async {
    try {
      final response = await client.post(
        createBreakUri,
        body: jsonEncode(dto.toJson()),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> createGlobalBreak(BreakGlobalCreationDto dto) async {
    try {
      final response = await client.post(
        createGlobalBreakUri,
        body: jsonEncode(dto.toJson()),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> deleteBreak(String breakId) async {
    try {
      final response = await client.delete(
        deleteBreakUri,
        headers: headers,
        body: jsonEncode(breakId),
      );
      return response.statusCode == 200 || response.statusCode == 204;
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

  @override
  Future<bool> printResults(String ageGroupId) async {
    try {
      final uri = Uri.parse(printResultsPath + ageGroupId);
      final response = await client.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final fileName = 'Turnierergebnisse_$ageGroupId.pdf';
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
  Future<bool> endCurrentGames(DateTime originalStart) async {
    gameGroups.removeWhere(
      (group) => group.startTime.isAtSameMomentAs(originalStart),
    );

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
      20 * 60, // playTimeInSeconds (20 min)
    )..games = [
        GameDto(
          'test-id-1',
          DateTime(2025, 4, 1, 15, 30, 0),
          1,
          "Größenkönige",
          "Straßenläufer",
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
          "Müller FC",
          "Düsseldorf äußerst",
          "Feld 2",
          'Liga 1',
          'Altersklasse 2',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-break-1',
          DateTime(2025, 4, 1, 15, 30, 0),
          0,
          '-',
          '-',
          'Feld 1',
          'Liga 1',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.break_,
        ),
        GameDto(
          'test-id-3',
          DateTime(2025, 4, 1, 15, 30, 0),
          2,
          "Überflieger",
          "Köln-Schlümpfe",
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
      12 * 60, // playTimeInSeconds (12 min)
    )..games = [
        GameDto(
          'test-id-5',
          DateTime(2025, 4, 1, 15, 45, 0),
          1,
          "Heiße Füße",
          "Großstadt-Bären",
          "Feld 1",
          'Liga 1',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.game,
        ),
        GameDto(
          'test-id-break-2',
          DateTime(2025, 4, 1, 15, 45, 0),
          0,
          '-',
          '-',
          'Feld 2',
          'Liga 3',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.break_,
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
    GameGroupDto(
      DateTime(2025, 4, 1, 16, 0, 0),
      10 * 60, // playTimeInSeconds (10 min)
    )..games = [
        GameDto(
          'test-id-break-only-1',
          DateTime(2025, 4, 1, 16, 0, 0),
          0,
          '-',
          '-',
          'Feld 1',
          'Liga 1',
          'Altersklasse 1',
          GameStatus.scheduled,
          ItemType.break_,
        ),
        GameDto(
          'test-id-break-only-2',
          DateTime(2025, 4, 1, 16, 0, 0),
          0,
          '-',
          '-',
          'Feld 2',
          'Liga 1',
          'Altersklasse 2',
          GameStatus.scheduled,
          ItemType.break_,
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

  static const _resultTeamNames = [
    'Größenkönige',
    'Straßenläufer',
    'Müller FC',
    'Düsseldorf äußerst',
    'Überflieger',
    'Köln-Schlümpfe',
    'Heiße Füße',
    'Großstadt-Bären',
    'Schlüpfer United',
    'Äußere Neun',
  ];

  @override
  Future<ResultsDto?> getResults(String ageGroupId) async {
    var resultList = List.generate(
      10,
      (index) {
        var randomGenerator = Random(index);
        var ownScoredGoals = randomGenerator.nextInt(100);
        var enemyScoredGoals = randomGenerator.nextInt(100);
        var result = ResultEntryDto(
          _resultTeamNames[index],
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
    int gameNumber = 0;
    var baseTime = DateTime.now();

    const scheduleTeams = [
      'Größenkönige',
      'Straßenläufer',
      'Müller FC',
      'Düsseldorf äußerst'
    ];

    var scheduleList = <MatchScheduleEntryDto>[];
    // Mixed pattern: games, single breaks (message in teamAName), grouped breaks (same slot, two pitches)
    for (var i = 0; i < 16; i++) {
      var startTime = baseTime.add(Duration(minutes: i * 25));
      var endTime = startTime.add(const Duration(minutes: 20));

      // Single break entries (one slot, one card)
      if (i == 2 || i == 9) {
        final label = i == 2 ? 'Kurze Pause' : 'Getränkepause';
        scheduleList.add(MatchScheduleEntryDto(
          ItemType.break_,
          "Platz $fieldCount",
          startTime,
          endTime,
          label,
          null,
          null,
        ));
        fieldCount++;
        if (fieldCount > 3) fieldCount = 1;
        continue;
      }

      // Grouped breaks: same start/end, two pitches (combined card in UI)
      if (i == 5 || i == 12) {
        final label = i == 5 ? 'Mittagspause' : 'Verschnaufpause';
        scheduleList.add(MatchScheduleEntryDto(
          ItemType.break_,
          "Platz $fieldCount",
          startTime,
          endTime,
          label,
          null,
          null,
        ));
        fieldCount++;
        if (fieldCount > 3) fieldCount = 1;
        scheduleList.add(MatchScheduleEntryDto(
          ItemType.break_,
          "Platz $fieldCount",
          startTime,
          endTime,
          label,
          null,
          null,
        ));
        fieldCount++;
        if (fieldCount > 3) fieldCount = 1;
        continue;
      }

      gameNumber++;
      scheduleList.add(MatchScheduleEntryDto(
        ItemType.game,
        "Platz $fieldCount",
        startTime,
        endTime,
        scheduleTeams[teamCount - 1],
        scheduleTeams[(teamCount % 4)],
        gameNumber,
      ));
      teamCount += 2;
      if (teamCount > 4) teamCount = 1;
      fieldCount++;
      if (fieldCount > 3) fieldCount = 1;
    }

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

  /// In-memory admin games for [GameTestRestApi]; survives [saveGame] like a real backend.
  List<ExtendedGameDto>? _mockAdminGames;

  List<ExtendedGameDto> _ensureMockAdminGames() {
    if (_mockAdminGames != null) {
      return _mockAdminGames!;
    }
    // Wie Schedule-Mock: Slots mit 1–4 Spielen gleicher Startzeit + Einzelspiele (Admin-Gruppierung).
    const teams = [
      'Größenkönige',
      'Straßenläufer',
      'Müller FC',
      'Düsseldorf äußerst',
      'Überflieger',
      'Köln-Schlümpfe',
      'Heiße Füße',
      'Großstadt-Bären',
    ];

    var pairIndex = 0;
    final result = <ExtendedGameDto>[];
    var slotTime = DateTime.now();
    const betweenSlots = Duration(minutes: 35);

    // Pro Slot: absichtlich nicht sortierte, lückenhafte gameNumbers (API-Reihenfolge ≠ Anzeige).
    GameStatus demoStatusFor(int gameNumber) {
      if (gameNumber % 7 == 0) return GameStatus.canceled;
      if (gameNumber % 5 == 0) return GameStatus.completedAndStated;
      if (gameNumber % 3 == 0) return GameStatus.completed;
      return GameStatus.scheduled;
    }

    void addParallelSlot(DateTime start, List<int> gameNumbersInApiOrder) {
      for (var p = 0; p < gameNumbersInApiOrder.length; p++) {
        final gameNumber = gameNumbersInApiOrder[p];
        final ti = (pairIndex * 2) % teams.length;
        final tj = (pairIndex * 2 + 1) % teams.length;
        pairIndex++;
        result.add(
          ExtendedGameDto(
            'test-extended-id-$gameNumber',
            start,
            gameNumber,
            teams[ti],
            teams[tj],
            'Platz ${p + 1}',
            'Liga ${(gameNumber % 3) + 1}',
            'Altersklasse ${(gameNumber % 2) + 1}',
            (gameNumber % 5) + 1,
            (gameNumber % 4) + 1,
            demoStatusFor(gameNumber),
          ),
        );
      }
      slotTime = start.add(betweenSlots);
    }

    addParallelSlot(slotTime, [812, 5, 400, 99]);
    addParallelSlot(slotTime, [701]);
    addParallelSlot(slotTime, [888, 12, 550]);
    addParallelSlot(slotTime, [300, 1]);
    addParallelSlot(slotTime, [42]);
    addParallelSlot(slotTime, [600]);
    addParallelSlot(slotTime, [115, 999, 2, 77]);
    addParallelSlot(slotTime, [330, 44]);
    addParallelSlot(slotTime, [18, 900, 505]);
    addParallelSlot(slotTime, [303]);

    _mockAdminGames = result;
    return result;
  }

  @override
  Future<List<ExtendedGameDto>> getAllGames() async {
    return List<ExtendedGameDto>.from(_ensureMockAdminGames());
  }

  @override
  Future<bool> saveGame(int gameNumber, int teamAScore, int teamBScore) async {
    final games = _ensureMockAdminGames();
    final idx = games.indexWhere((g) => g.gameNumber == gameNumber);
    if (idx == -1) {
      return false;
    }
    final g = games[idx];
    g.pointsTeamA = teamAScore;
    g.pointsTeamB = teamBScore;
    if (g.status == GameStatus.completed) {
      g.status = GameStatus.completedAndStated;
    }
    return true;
  }

  @override
  Future<bool> createBreakForAgeGroup(BreakSingleCreationDto dto) async {
    return true;
  }

  @override
  Future<bool> createGlobalBreak(BreakGlobalCreationDto dto) async {
    return true;
  }

  @override
  Future<bool> deleteBreak(String breakId) async {
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

  @override
  Future<bool> printResults(String ageGroupId) async {
    return true;
  }
}
