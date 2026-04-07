import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_manager/src/serialization/admin/extended_game_dto.dart';
import 'package:tournament_manager/src/serialization/admin/game_score_update_dto.dart';
import 'package:tournament_manager/src/serialization/age_group_dto.dart';
import 'package:tournament_manager/src/serialization/game_status.dart';
import 'package:tournament_manager/src/serialization/referee/game_group_dto.dart';
import 'package:tournament_manager/src/serialization/referee/pitch_dto.dart';
import 'package:tournament_manager/src/serialization/results/results_dto.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';
import 'package:tournament_manager/src/serialization/schedule/match_schedule_dto.dart';

/// JSON-Fixtures wie `GameRestApiImplementation` nach HTTP 200 auswertet
/// (jsonDecode + jeweiliges fromJson).
String _fixture(String name) =>
    File('test/fixtures/game_rest_api/$name').readAsStringSync();

void main() {
  group('GameRestApi JSON fixtures', () {
    test('getAllGames: list of ExtendedGameDto', () {
      final decoded = jsonDecode(_fixture('get_all_games.json'));
      expect(decoded, isA<List<dynamic>>());
      final list = (decoded as List<dynamic>)
          .map((e) => ExtendedGameDto.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list, hasLength(2));
      expect(list[0].gameNumber, 812);
      expect(list[0].status, GameStatus.scheduled);
      expect(list[1].gameNumber, 5);
      expect(list[1].status, GameStatus.inProgress);
      expect(list[0].startTime, list[1].startTime);
    });

    test('getSchedule: MatchScheduleDto with leagues and entries', () {
      final decoded =
          jsonDecode(_fixture('match_schedule.json')) as Map<String, dynamic>;
      final dto = MatchScheduleDto.fromJson(decoded);

      expect(dto.roundName, 'Runde 1');
      expect(dto.ageGroupName, 'U12');
      expect(dto.leagues, hasLength(1));
      expect(dto.leagues.first.leagueName, 'Liga A');
      final entries = dto.leagues.first.entries;
      expect(entries, hasLength(3));
      expect(entries[0].itemType, ItemType.game);
      expect(entries[2].itemType, ItemType.break_);
      expect(entries[0].startTime, entries[1].startTime);
      expect(entries[2].gameNumber, isNull);
    });

    test('getResults: ResultsDto with leagueTables', () {
      final decoded =
          jsonDecode(_fixture('results.json')) as Map<String, dynamic>;
      final dto = ResultsDto.fromJson(decoded);

      expect(dto.roundId, 'round-test-1');
      expect(dto.roundName, 'Runde 1');
      expect(dto.leagueTables, hasLength(1));
      expect(dto.leagueTables.first.leagueName, 'Liga A');
      expect(dto.leagueTables.first.teams, hasLength(1));
      expect(dto.leagueTables.first.teams.first.teamName, 'Team Alpha');
      expect(dto.leagueTables.first.teams.first.avgGoalDiffScore, 2.5);
    });

    test('getAllAgeGroups: list of AgeGroupDto', () {
      final decoded = jsonDecode(_fixture('age_groups.json'));
      expect(decoded, isA<List<dynamic>>());
      final list = (decoded as List<dynamic>)
          .map((e) => AgeGroupDto.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list.map((e) => e.name).toList(), ['U12', 'U14']);
    });

    test('getCurrentRound: list of GameGroupDto', () {
      final decoded = jsonDecode(_fixture('game_groups.json'));
      expect(decoded, isA<List<dynamic>>());
      final list = (decoded as List<dynamic>)
          .map((e) => GameGroupDto.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list, hasLength(1));
      expect(list.first.playTimeInSeconds, 1200);
      expect(list.first.games, hasLength(1));
      expect(list.first.games.first.gameNumber, 1);
    });

    test('getAllPitches: list of PitchDto', () {
      final decoded = jsonDecode(_fixture('pitches.json'));
      expect(decoded, isA<List<dynamic>>());
      final list = (decoded as List<dynamic>)
          .map((e) => PitchDto.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list, hasLength(2));
      expect(list[0].name, 'Platz 1');
      expect(list[0].ageGroup, isNull);
      expect(list[1].ageGroup?.name, 'U12');
    });

    test('saveGame POST body: GameScoreUpdateDto', () {
      final decoded = jsonDecode(_fixture('save_game_body.json'))
          as Map<String, dynamic>;
      final dto = GameScoreUpdateDto.fromJson(decoded);
      expect(dto.gameNumber, 42);
      expect(dto.teamAScore, 3);
      expect(dto.teamBScore, 1);
      expect(dto.toJson(), decoded);
    });
  });
}
