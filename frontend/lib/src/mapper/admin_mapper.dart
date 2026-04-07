import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:tournament_manager/src/serialization/admin/extended_game_dto.dart';

class AdminMapper {
  ExtendedGame map(ExtendedGameDto dto) {
    return ExtendedGame(
      dto.gameNumber,
      dto.pitch,
      dto.teamA,
      dto.teamB,
      dto.leagueName,
      dto.ageGroupName,
      dto.pointsTeamA,
      dto.pointsTeamB,
      dto.startTime,
      dto.status,
    );
  }
}
