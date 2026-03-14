import 'package:tournament_manager/src/model/referee/game.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/model/referee/game_settings.dart';
import 'package:tournament_manager/src/model/referee/pitch.dart';
import 'package:tournament_manager/src/model/referee/round_settings.dart';
import 'package:tournament_manager/src/model/referee/team.dart';
import 'package:tournament_manager/src/serialization/referee/game_dto.dart';
import 'package:tournament_manager/src/serialization/referee/game_group_dto.dart';
import 'package:tournament_manager/src/serialization/referee/game_settings_dto.dart';
import 'package:tournament_manager/src/serialization/referee/pitch_dto.dart';
import 'package:tournament_manager/src/serialization/referee/round_settings_dto.dart';
import 'package:tournament_manager/src/serialization/referee/team_dto.dart';

class RefereeMapper {
  Pitch mapPitch(PitchDto dto) {
    return Pitch(
      dto.id,
      dto.name,
    );
  }

  GameGroup mapGameGroup(GameGroupDto dto) {
    return GameGroup(
      dto.startTime,
      dto.playTimeInSeconds,
    )..games = dto.games.map((game) => mapGame(game)).toList();
  }

  Team mapTeam(TeamDto dto) {
    return Team(
      dto.name,
    );
  }

  Game mapGame(GameDto dto) {
    // New structure: all fields are Strings
    return Game(
      dto.id,
      dto.gameNumber,
      Pitch('', dto.pitch), // Create Pitch with empty id and name from string
      Team(dto.teamA), // Create Team from string
      Team(dto.teamB), // Create Team from string
      dto.leagueName,
      dto.ageGroupName,
      dto.type,
    );
  }

  RoundSettings mapRoundSettings(RoundSettingsDto dto) {
    final gameSettings = GameSettings(
      DateTime.now(),
      dto.breakTimeInSeconds,
      dto.playTimeInSeconds,
    );
    return RoundSettings(gameSettings, roundName: dto.roundName)
      ..numberPerRounds =
          Map<String, int>.from(dto.maxTeamsPerLeaguePerAgeGroup);
  }

  GameSettings mapGameSettings(GameSettingsDto dto) {
    return GameSettings(
      dto.startTime,
      dto.breakTime,
      dto.playTime,
    );
  }

  RoundSettingsDto reverseMapRoundSettings(RoundSettings model) {
    return RoundSettingsDto(
      Map<String, int>.from(model.numberPerRounds),
      model.gameSettings.playTime,
      model.gameSettings.breakTime,
      model.roundName,
    );
  }

  GameSettingsDto reverseMapGameSettings(GameSettings model) {
    return GameSettingsDto(
      model.startTime,
      model.breakTime,
      model.playTime,
    );
  }
}
