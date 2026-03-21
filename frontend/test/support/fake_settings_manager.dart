import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:tournament_manager/src/manager/settings_manager.dart';

/// [SettingsManager] with in-memory state for widget tests (no SharedPreferences).
class FakeSettingsManager with ChangeNotifier implements SettingsManager {
  FakeSettingsManager({
    this.canPause = false,
    this.currentlyRunningGames,
    this.currentTimeInMilliseconds,
  }) {
    getCanPauseCommand = Command.createAsyncNoParamNoResult(() async {});
    setCanPauseCommand = Command.createAsyncNoResult<bool>((value) async {
      canPause = value;
      notifyListeners();
    });

    getCurrentlyRunningGamesCommand =
        Command.createAsyncNoParamNoResult(() async {});
    setCurrentlyRunningGamesCommand =
        Command.createAsyncNoResult<DateTime?>((value) async {
      currentlyRunningGames = value;
      notifyListeners();
    });

    getCurrentTimeInMillisecondsCommand =
        Command.createAsyncNoParamNoResult(() async {});
    setCurrentTimeInMillisecondsCommand =
        Command.createAsyncNoResult<int?>((value) async {
      currentTimeInMilliseconds = value;
      notifyListeners();
    });
  }

  @override
  late Command<void, void> getCanPauseCommand;

  @override
  late Command<bool, void> setCanPauseCommand;

  @override
  late Command<void, void> getCurrentlyRunningGamesCommand;

  @override
  late Command<DateTime?, void> setCurrentlyRunningGamesCommand;

  @override
  late Command<void, void> getCurrentTimeInMillisecondsCommand;

  @override
  late Command<int?, void> setCurrentTimeInMillisecondsCommand;

  @override
  bool canPause;

  @override
  DateTime? currentlyRunningGames;

  @override
  int? currentTimeInMilliseconds;
}
