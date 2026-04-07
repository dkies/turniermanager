import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/referee/game.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/model/referee/pitch.dart';
import 'package:tournament_manager/src/model/referee/team.dart';
import 'package:tournament_manager/src/model/results/league.dart' as results;
import 'package:tournament_manager/src/model/results/result_entry.dart';
import 'package:tournament_manager/src/model/results/results.dart';
import 'package:tournament_manager/src/model/schedule/league.dart' as schedule;
import 'package:tournament_manager/src/model/schedule/match_schedule.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule_entry.dart';
import 'package:tournament_manager/src/serialization/game_status.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';

const testAgeGroupName = 'U12';
const testAgeGroupId = 'age-1';

AgeGroup sampleAgeGroup() => AgeGroup(testAgeGroupId, testAgeGroupName);

MatchSchedule sampleMatchSchedule() {
  final league = schedule.League('Liga A');
  final t0 = DateTime(2025, 6, 1, 9, 0);
  league.entries.add(
    MatchScheduleEntry(
      ItemType.game,
      'P1',
      'Alpha',
      'Beta',
      t0,
      t0.add(const Duration(minutes: 30)),
    ),
  );
  league.entries.add(
    MatchScheduleEntry(
      ItemType.break_,
      'P1',
      'Mittagspause',
      '',
      t0.add(const Duration(minutes: 30)),
      t0.add(const Duration(hours: 1)),
    ),
  );
  final ms = MatchSchedule('Runde 1');
  ms.leagueSchedules = [league];
  return ms;
}

Results sampleResults() {
  final league = results.League('Liga A');
  league.teams.add(
    ResultEntry(
      'Team Alpha',
      3,
      1,
      0,
      0,
      10,
      8,
      2,
      1.5,
    ),
  );
  final r = Results('Runde 1');
  r.leagueTables = [league];
  return r;
}

GameGroup sampleGameGroup() {
  final pitch = Pitch('p1', 'Platz 1');
  final g = Game(
    'g1',
    1,
    pitch,
    Team('A'),
    Team('B'),
    'Liga A',
    testAgeGroupName,
    ItemType.game,
  );
  final gg = GameGroup(DateTime(2025, 6, 1, 10, 0), 300);
  gg.games.add(g);
  return gg;
}

/// Same time as [sampleGameGroup] — use with settings `currentlyRunningGames` for barrier tests.
DateTime sampleGameGroupStartTime() => DateTime(2025, 6, 1, 10, 0);

/// Only break entries — yellow card, "Pause:" header, no play row.
/// Normal game plus a break row (for delete-break integration tests).
GameGroup sampleGameGroupWithBreak() {
  final gg = sampleGameGroup();
  gg.games.add(
    Game(
      'break-del-1',
      2,
      Pitch('p1', 'Platz 1'),
      Team('x'),
      Team('y'),
      'Liga A',
      testAgeGroupName,
      ItemType.break_,
    ),
  );
  return gg;
}

GameGroup sampleBreakOnlyGameGroup() {
  final pitch = Pitch('p1', 'Platz 1');
  final g = Game(
    'break-1',
    1,
    pitch,
    Team(''),
    Team(''),
    'Liga A',
    testAgeGroupName,
    ItemType.break_,
  );
  final gg = GameGroup(DateTime(2025, 6, 1, 11, 0), 120);
  gg.games.add(g);
  return gg;
}

ExtendedGame sampleExtendedGame() => ExtendedGame(
      1,
      'Platz 1',
      'Team A',
      'Team B',
      'Liga A',
      testAgeGroupName,
      2,
      1,
      DateTime(2025, 6, 1, 10, 0),
      GameStatus.completed,
    );

List<Pitch> samplePitches() => [Pitch('pitch-1', 'Platz 1')];
