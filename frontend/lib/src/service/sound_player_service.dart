import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:watch_it/watch_it.dart';

abstract class SoundPlayerService implements Disposable {
  void playSound(Sounds sound);
  void toggleSoundPlayback(Sounds sound);
  void stopPlayback();
  Stream<void> get playbackStateChanges;
  bool get isPlaying;
  bool get isPaused;
  Sounds? get activeSound;
}

class SoundPlayerServiceImplementation implements SoundPlayerService {
  final _player = AudioPlayer();
  final _playbackStateChangesController = StreamController<void>.broadcast();
  Sounds? _activeSound;
  PlayerState _playerState = PlayerState.stopped;
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<void> _playerCompleteSubscription;

  SoundPlayerServiceImplementation() {
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _playbackStateChangesController.add(null);
    });
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      _activeSound = null;
      _playerState = PlayerState.stopped;
      _playbackStateChangesController.add(null);
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
      _playbackStateChangesController.add(null);
      await _player.play(AssetSource(soundPath));
    } on Exception {
      _playerState = PlayerState.stopped;
      _playbackStateChangesController.add(null);
      return;
    }
  }

  @override
  void toggleSoundPlayback(Sounds sound) async {
    if (_activeSound == sound && _playerState == PlayerState.playing) {
      _playerState = PlayerState.paused;
      _playbackStateChangesController.add(null);
      await _player.pause();
      return;
    }

    if (_activeSound == sound && _playerState == PlayerState.paused) {
      _playerState = PlayerState.playing;
      _playbackStateChangesController.add(null);
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
    _playbackStateChangesController.add(null);
    await _player.play(AssetSource(soundPath));
  }

  @override
  void stopPlayback() async {
    await _player.stop();
    _activeSound = null;
    _playerState = PlayerState.stopped;
    _playbackStateChangesController.add(null);
  }

  @override
  Stream<void> get playbackStateChanges => _playbackStateChangesController.stream;

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
    await _playbackStateChangesController.close();
    await _player.stop();
    await _player.dispose();
  }
}

enum Sounds {
  gong,
  horn,
  endMusic;
}
