import 'package:tournament_manager/src/manager/game_manager_base.dart';
import 'package:tournament_manager/src/manager/settings_manager.dart';
import 'package:tournament_manager/src/service/sound_player_service.dart';
import 'package:watch_it/watch_it.dart';

import 'fake_game_manager.dart';
import 'fake_settings_manager.dart';
import 'fake_sound_player_service.dart';

/// Resets GetIt and registers fakes used by views under test.
Future<void> resetAndRegisterTestDi({
  FakeGameManager? gameManager,
  FakeSettingsManager? settingsManager,
  FakeSoundPlayerService? soundPlayer,
}) async {
  await di.reset();
  di.registerSingleton<GameManager>(gameManager ?? FakeGameManager());
  di.registerSingleton<SettingsManager>(
    settingsManager ?? FakeSettingsManager(),
  );
  di.registerSingleton<SoundPlayerService>(
    soundPlayer ?? FakeSoundPlayerService(),
  );
}
