import 'package:tournament_manager/src/model/referee/game_settings.dart';

class RoundSettings {
  RoundSettings(
    this.gameSettings, {
    this.roundName = 'Qualifikation',
  });

  Map<String, int> numberPerRounds = {};
  GameSettings gameSettings;

  /// Name der Runde für /turnier/end-qualification-detailed
  String roundName;
}
