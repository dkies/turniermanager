import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:watch_it/watch_it.dart';

abstract class SoundPlayerService implements Disposable {
  void playSound(Sounds sound);
  void toggleSoundPlayback(Sounds sound);
  void stopPlayback();
  bool get isPlaying;
  bool get isPaused;
  Sounds? get activeSound;
}

class SoundPlayerServiceImplementation implements SoundPlayerService {
  final _player = AudioPlayer();
  Sounds? _activeSound;
  PlayerState _playerState = PlayerState.stopped;
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<void> _playerCompleteSubscription;

  SoundPlayerServiceImplementation() {
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
    });
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      _activeSound = null;
      _playerState = PlayerState.stopped;
    });
  }

  String? _soundPathFor(Sounds sound) {
    switch (sound) {
      case Sounds.gong:
        return 'sounds/gong_sound.wav';
      case Sounds.horn:
        return 'sounds/horn.wav';
      case Sounds.endMusic:
        return 'sounds/end_of_game.wav';
    }
  }

  @override
  void playSound(Sounds sound) async {
    if (_playerState == PlayerState.playing) {
      return;
    }

    final soundPath = _soundPathFor(sound);

    if (soundPath == null || soundPath.isEmpty) {
      return;
    }

    try {
      _activeSound = sound;
      _playerState = PlayerState.playing;
      await _player.play(AssetSource(soundPath));
    } on Exception {
      _playerState = PlayerState.stopped;
      return;
    }
  }

  @override
  void toggleSoundPlayback(Sounds sound) async {
    if (_activeSound == sound && _playerState == PlayerState.playing) {
      _playerState = PlayerState.paused;
      await _player.pause();
      return;
    }

    if (_activeSound == sound && _playerState == PlayerState.paused) {
      _playerState = PlayerState.playing;
      await _player.resume();
      return;
    }

    final soundPath = _soundPathFor(sound);
    if (soundPath == null || soundPath.isEmpty) {
      return;
    }

    await _player.stop();
    _activeSound = sound;
    _playerState = PlayerState.playing;
    await _player.play(AssetSource(soundPath));
  }

  @override
  void stopPlayback() async {
    await _player.stop();
    _activeSound = null;
    _playerState = PlayerState.stopped;
  }

  @override
  bool get isPlaying => _playerState == PlayerState.playing;

  @override
  bool get isPaused => _playerState == PlayerState.paused;

  @override
  Sounds? get activeSound => _activeSound;

  @override
  FutureOr onDispose() async {
    await _playerStateSubscription.cancel();
    await _playerCompleteSubscription.cancel();
    await _player.stop();
    await _player.dispose();
  }
}

enum Sounds {
  gong,
  horn,
  endMusic;
}
