import 'package:tournament_manager/src/model/schedule/league.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule_entry.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';
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
    // Only map GAME entries, skip BREAK entries
    if (dto.itemType != ItemType.game) {
      // For breaks, return a placeholder entry
      return MatchScheduleEntry(
        dto.pitchName,
        'Pause', // teamAName
        '', // teamBName
        dto.startTime,
      );
    }

    return MatchScheduleEntry(
      dto.pitchName,
      dto.teamAName ?? '', // Provide empty string if null
      dto.teamBName ?? '', // Provide empty string if null
      dto.startTime,
    );
  }
}
