import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tournament_manager/src/serialization/game_status.dart';
import 'package:tournament_manager/src/service/game_rest_api.dart';

String _fixture(String name) =>
    File('test/fixtures/game_rest_api/$name').readAsStringSync();

/// Routing wie GameRestApiImplementation-URIs (relativ zu `http://test.local`).
Future<http.Response> _mockHandler(http.Request request) async {
  final path = request.url.path;
  final jsonHeaders = {'content-type': 'application/json'};

  if (path.endsWith('/agegroups/getAll') && request.method == 'GET') {
    return http.Response(_fixture('age_groups.json'), 200,
        headers: jsonHeaders);
  }
  if (path.contains('/gameplan/agegroup/') && request.method == 'GET') {
    return http.Response(_fixture('match_schedule.json'), 200,
        headers: jsonHeaders);
  }
  if (path.contains('/stats/agegroup/') && request.method == 'GET') {
    return http.Response(_fixture('results.json'), 200, headers: jsonHeaders);
  }
  if (path.endsWith('/gameplan/get-all-games-listed-extended') &&
      request.method == 'GET') {
    return http.Response(_fixture('get_all_games.json'), 200,
        headers: jsonHeaders);
  }
  if (path.endsWith('/gameplan/activeGamesSortedDateTimeList') &&
      request.method == 'GET') {
    return http.Response(_fixture('game_groups.json'), 200,
        headers: jsonHeaders);
  }
  if (path.endsWith('/pitches') && request.method == 'GET') {
    return http.Response(_fixture('pitches.json'), 200, headers: jsonHeaders);
  }
  if (path.endsWith('/games/score') && request.method == 'POST') {
    return http.Response('', 200);
  }

  return http.Response('not found', 404);
}

void main() {
  const base = 'http://test.local';

  group('GameRestApiImplementation + MockClient', () {
    late MockClient client;
    late GameRestApiImplementation api;

    setUp(() {
      client = MockClient(_mockHandler);
      api = GameRestApiImplementation(base, httpClient: client);
    });

    tearDown(() {
      client.close();
    });

    test('getAllAgeGroups', () async {
      final list = await api.getAllAgeGroups();
      expect(list, hasLength(2));
      expect(list.map((e) => e.name).toList(), ['U12', 'U14']);
    });

    test('getAgeGroup', () async {
      final g = await api.getAgeGroup('U12');
      expect(g, isNotNull);
      expect(g!.id, 'age-1');
      expect(g.name, 'U12');
    });

    test('getSchedule', () async {
      final schedule = await api.getSchedule('age-1');
      expect(schedule, isNotNull);
      expect(schedule!.roundName, 'Runde 1');
      expect(schedule.leagues.first.entries, hasLength(3));
    });

    test('getResults', () async {
      final results = await api.getResults('age-1');
      expect(results, isNotNull);
      expect(results!.leagueTables.first.teams.first.teamName, 'Team Alpha');
    });

    test('getAllGames', () async {
      final games = await api.getAllGames();
      expect(games, hasLength(2));
      expect(games[0].gameNumber, 812);
      expect(games[1].status, GameStatus.inProgress);
    });

    test('getCurrentRound', () async {
      final groups = await api.getCurrentRound();
      expect(groups, hasLength(1));
      expect(groups.first.games.first.gameNumber, 1);
    });

    test('getAllPitches', () async {
      final pitches = await api.getAllPitches();
      expect(pitches, hasLength(2));
      expect(pitches[1].ageGroup?.name, 'U12');
    });

    test('saveGame on HTTP 200', () async {
      final ok = await api.saveGame(1, 2, 3);
      expect(ok, isTrue);
    });

    test('getSchedule returns null on non-200', () async {
      final failing = MockClient((request) async => http.Response('', 500));
      final api500 = GameRestApiImplementation(base, httpClient: failing);
      addTearDown(failing.close);
      final schedule = await api500.getSchedule('x');
      expect(schedule, isNull);
    });

    test('saveGame posts JSON body', () async {
      http.Request? captured;
      final recording = MockClient((request) async {
        captured = request;
        return http.Response('', 200);
      });
      final apiRec = GameRestApiImplementation(base, httpClient: recording);
      addTearDown(recording.close);

      await apiRec.saveGame(42, 7, 8);

      expect(captured, isNotNull);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, endsWith('/games/score'));
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['gameNumber'], 42);
      expect(body['teamAScore'], 7);
      expect(body['teamBScore'], 8);
    });
  });
}
