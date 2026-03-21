import 'dart:async';

import 'package:tournament_manager/src/service/sound_player_service.dart';

/// Minimal [SoundPlayerService] for widget tests (no audio).
class FakeSoundPlayerService implements SoundPlayerService {
  /// All sounds passed to [playSound] / [toggleSoundPlayback] (for assertions).
  final List<Sounds> playSoundLog = [];

  @override
  Sounds? activeSound;

  @override
  bool isPaused = false;

  @override
  bool isPlaying = false;

  final _playback = StreamController<void>.broadcast();

  @override
  Stream<void> get playbackStateChanges => _playback.stream;

  @override
  void playSound(Sounds sound) {
    playSoundLog.add(sound);
    activeSound = sound;
    isPlaying = true;
    isPaused = false;
    if (!_playback.isClosed) {
      _playback.add(null);
    }
  }

  @override
  void stopPlayback() {
    activeSound = null;
    isPlaying = false;
    isPaused = false;
    if (!_playback.isClosed) {
      _playback.add(null);
    }
  }

  @override
  void toggleSoundPlayback(Sounds sound) {
    playSound(sound);
  }

  @override
  FutureOr<void> onDispose() async {
    await _playback.close();
  }
}
