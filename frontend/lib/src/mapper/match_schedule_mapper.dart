import 'package:tournament_manager/src/model/schedule/league.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule_entry.dart';
import 'package:tournament_manager/src/serialization/schedule/league_dto.dart';
import 'package:tournament_manager/src/serialization/schedule/match_schedule_dto.dart';
import 'package:tournament_manager/src/serialization/schedule/match_schedule_entry_dto.dart';

class MatchScheduleMapper {
  MatchSchedule map(MatchScheduleDto dto) {
    return MatchSchedule(dto.roundName)
      ..leagueSchedules = dto.leagues.map((entry) => mapLeague(entry)).toList();
  }

  League mapLeague(LeagueDto dto) {
    return League(dto.leagueName)
      ..entries = dto.entries.map((entry) => mapEntry(entry)).toList();
  }

  MatchScheduleEntry mapEntry(MatchScheduleEntryDto dto) {
    return MatchScheduleEntry(
      dto.itemType,
      dto.pitchName,
      dto.teamAName ?? '',
      dto.teamBName ?? '',
      dto.startTime,
    );
  }
}
