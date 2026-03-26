import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/helper/error_helper.dart';
import 'package:tournament_manager/src/manager/game_manager_base.dart';
import 'package:tournament_manager/src/manager/settings_manager.dart';
import 'package:tournament_manager/src/model/referee/game.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';
import 'package:tournament_manager/src/service/sound_player_service.dart';
import 'package:tournament_manager/src/views/unsaved_changes_browser_guard.dart'
    if (dart.library.html)
        'package:tournament_manager/src/views/unsaved_changes_browser_guard_web.dart';
import 'package:watch_it/watch_it.dart';
import 'package:intl/intl.dart';

class RefereeView extends StatefulWidget with WatchItStatefulWidgetMixin {
  RefereeView({super.key});

  static const routeName = '/referee';

  @override
  State<RefereeView> createState() => _RefereeViewState();
}

class _RefereeViewState extends State<RefereeView> {
  static const _leaveWarningText =
      'Es laufen noch Spiele. Seite wirklich verlassen?';
  bool barrierDissmissed = false;
  late final SettingsManager _settingsManager;
  late final BrowserUnsavedChangesGuard _browserUnsavedChangesGuard;

  @override
  void initState() {
    super.initState();
    _settingsManager = di<SettingsManager>();
    _browserUnsavedChangesGuard = createBrowserUnsavedChangesGuard();
    _browserUnsavedChangesGuard.register(
      _hasRunningGames,
      message: _leaveWarningText,
    );
  }

  @override
  void dispose() {
    _browserUnsavedChangesGuard.dispose();
    super.dispose();
  }

  bool _hasRunningGames() {
    return _settingsManager.currentlyRunningGames != null;
  }

  Future<bool> _confirmLeavingWithRunningGames() async {
    if (!_hasRunningGames()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Laufende Spiele'),
        content: const Text(_leaveWarningText),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Verlassen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Bleiben'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleBackNavigation() async {
    final canLeave = await _confirmLeavingWithRunningGames();
    if (!canLeave || !mounted) {
      return;
    }
    GoRouter.of(context).pop();
  }

  void _dismissBarrier() {
    setState(() {
      barrierDissmissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameGroups =
        watchPropertyValue((GameManager manager) => manager.gameGroups);

    final canPauseGames =
        watchPropertyValue((SettingsManager manager) => manager.canPause);
    final currentlyRunningGames = watchPropertyValue(
        (SettingsManager manager) => manager.currentlyRunningGames);

    var mainContent = Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Zurück',
              onPressed: _handleBackNavigation,
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Spielübersicht',
                  style: Constants.largeHeaderTextStyle,
                ),
              ),
            ),
          ],
        ),
        leadingWidth: 260,
        actions: [
          Tooltip(
            message: 'Umschalten: Spiele können pausiert werden',
            child: Switch(
              value: canPauseGames,
              onChanged: (value) {
                _settingsManager.setCanPauseCommand(!canPauseGames);
              },
              activeColor: Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => const _SoundPreviewDialog(),
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Sounds'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.builder(
          itemBuilder: (context, index) {
            var gameGroup = gameGroups[index];
            return GameView(
              key: ValueKey('${index}_${gameGroup.startTime.toString()}'),
              first: index == 0,
              gameGroup: gameGroup,
              canPauseGames: canPauseGames,
              onStart: _dismissBarrier,
            );
          },
          itemCount: gameGroups.length,
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.yellow.withOpacity(0.6),
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Während Spiele laufen: Seite neu laden vermeiden!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    final unmuteBarrier = [
      ModalBarrier(
        color: Colors.white.withOpacity(0.3),
        onDismiss: _dismissBarrier,
      ),
      Center(
        child: IconButton(
          onPressed: _dismissBarrier,
          icon: const Icon(
            Icons.volume_up,
            size: 100,
          ),
        ),
      )
    ];

    return PopScope(
      canPop: currentlyRunningGames == null,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final canLeave = await _confirmLeavingWithRunningGames();
        if (!canLeave || !context.mounted) {
          return;
        }
        GoRouter.of(context).pop();
      },
      child: Stack(
        children: [
          mainContent,
          if (currentlyRunningGames != null && !barrierDissmissed)
            ...unmuteBarrier,
        ],
      ),
    );
  }
}

class _SoundPreviewDialog extends StatefulWidget {
  const _SoundPreviewDialog();

  @override
  State<_SoundPreviewDialog> createState() => _SoundPreviewDialogState();
}

class _SoundPreviewDialogState extends State<_SoundPreviewDialog> {
  late final SoundPlayerService _soundPlayerService;
  StreamSubscription<void>? _playbackStateSubscription;

  @override
  void initState() {
    super.initState();
    _soundPlayerService = di<SoundPlayerService>();
    _playbackStateSubscription =
        _soundPlayerService.playbackStateChanges.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    super.dispose();
  }

  String _soundLabel(Sounds sound) {
    switch (sound) {
      case Sounds.gong:
        return 'Gong';
      case Sounds.horn:
        return 'Horn';
      case Sounds.endMusic:
        return 'Schlusslied';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verfügbare Sounds'),
      content: SizedBox(
        width: 350,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: Sounds.values.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final sound = Sounds.values[index];

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_soundLabel(sound)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _soundPlayerService.toggleSoundPlayback(sound);
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      tooltip: _soundPlayerService.activeSound == sound &&
                              _soundPlayerService.isPlaying
                          ? 'Pausieren'
                          : 'Abspielen',
                      icon: Icon(
                        _soundPlayerService.activeSound == sound &&
                                _soundPlayerService.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    IconButton(
                      onPressed: _soundPlayerService.activeSound == sound
                          ? () {
                              _soundPlayerService.stopPlayback();
                              if (mounted) {
                                setState(() {});
                              }
                            }
                          : null,
                      tooltip: 'Beenden',
                      icon: const Icon(Icons.stop),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => GoRouter.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}

class GameView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const GameView({
    super.key,
    required this.first,
    required this.gameGroup,
    this.canPauseGames = false,
    this.onStart,
  });

  final bool first;
  final bool canPauseGames;
  final GameGroup gameGroup;
  final void Function()? onStart;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  bool currentlyRunning = false;
  bool reset = false;
  bool gamesWereStarted = false;

  Color selectedTextColor = Colors.black;
  Color standardTextColor = Colors.white;

  final soundPlayerService = di<SoundPlayerService>();
  late final SettingsManager _settingsManager;
  late final GameManager _gameManager;

  bool gameTimeEnded = false;

  @override
  void initState() {
    super.initState();
    _settingsManager = di<SettingsManager>();
    _gameManager = di<GameManager>();
    _settingsManager.getCurrentTimeInMillisecondsCommand();
  }

  bool _isBreakGroup() {
    final games = widget.gameGroup.games;
    return games.isNotEmpty && games.every((g) => g.type == ItemType.break_);
  }

  @override
  Widget build(BuildContext context) {
    void startOrPauseGames() {
      if (_isBreakGroup()) {
        return;
      }

      if (!currentlyRunning && !gamesWereStarted) {
        gamesWereStarted = true;
        soundPlayerService.playSound(Sounds.horn);
        _settingsManager
            .setCurrentlyRunningGamesCommand(widget.gameGroup.startTime);
      }

      if (!widget.canPauseGames) {
        setState(() {
          reset = false;
          currentlyRunning = true;
        });

        return;
      }

      setState(() {
        reset = false;
        currentlyRunning = !currentlyRunning;
      });
    }

    final currentlyRunningGames = watchPropertyValue(
        (SettingsManager manager) => manager.currentlyRunningGames);

    if (currentlyRunningGames != null &&
        currentlyRunningGames == widget.gameGroup.startTime &&
        !currentlyRunning &&
        !reset) {
      _settingsManager.getCurrentTimeInMillisecondsCommand();
      startOrPauseGames();
    }

    final games = widget.gameGroup.games;
    final isBreakGroup = _isBreakGroup();

    final textColor = isBreakGroup
        ? Colors.black
        : (currentlyRunning ? selectedTextColor : standardTextColor);
    final cardColor = isBreakGroup
        ? Colors.yellow.shade400
        : (currentlyRunning ? Colors.blue : null);
    final gameWidgets = <Widget>[];

    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      gameWidgets.add(
        GameEntryView(
          gameRoundEntry: game,
          textColor: textColor,
          onDeleteBreak: game.type == ItemType.break_
              ? (breakId) async {
                  final result = await _gameManager.deleteBreakCommand
                      .executeWithFuture(breakId);
                  if (!context.mounted) return;
                  if (result) {
                    _gameManager.getCurrentRoundCommand();
                  } else {
                    showError(context, 'Pause konnte nicht entfernt werden.');
                  }
                }
              : null,
        ),
      );
      if (i < games.length - 1) {
        gameWidgets.add(const Divider());
      }
    }

    final headerTextStyle = Constants.mediumHeaderTextStyle.copyWith(
      color: textColor,
    );

    return Card(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        isBreakGroup
                            ? 'Pause: ${DateFormat.Hm().format(widget.gameGroup.startTime)} - ${DateFormat.Hm().format(widget.gameGroup.startTime.add(Duration(seconds: widget.gameGroup.playTimeInSeconds)))} Uhr'
                            : 'Spielzeit: ${DateFormat.Hm().format(widget.gameGroup.startTime)} - ${DateFormat.Hm().format(widget.gameGroup.startTime.add(Duration(seconds: widget.gameGroup.playTimeInSeconds)))} Uhr',
                        style: headerTextStyle,
                      ),
                      const SizedBox(width: 10),
                      if (widget.first && !isBreakGroup)
                        IconButton(
                          onPressed: !widget.canPauseGames
                              ? currentlyRunning
                                  ? null
                                  : () {
                                      startOrPauseGames();
                                      widget.onStart?.call();
                                    }
                              : () {
                                  startOrPauseGames();
                                  widget.onStart?.call();
                                },
                          icon: Icon(currentlyRunning
                              ? Icons.pause
                              : Icons.play_arrow),
                          color: textColor,
                          tooltip: "Spiel starten",
                        ),
                      const SizedBox(width: 5),
                      if (!isBreakGroup)
                        CountDownView(
                          playTimeInSeconds: widget.gameGroup.playTimeInSeconds,
                          textColor: textColor,
                          start: currentlyRunning,
                          refresh: reset,
                          startTimeInMilliSeconds: currentlyRunningGames == null
                              ? null
                              : _settingsManager.currentTimeInMilliseconds,
                          onHalftime: () {
                            if (!widget.canPauseGames) {
                              return;
                            }

                            setState(() {
                              currentlyRunning = false;
                            });
                          },
                          onEnded: () {
                            setState(() {
                              gameTimeEnded = true;
                            });
                          },
                        ),
                      const SizedBox(width: 5),
                      if (widget.first && !isBreakGroup)
                        IconButton(
                          onPressed: !widget.canPauseGames
                              ? null
                              : () {
                                  _settingsManager
                                      .setCurrentlyRunningGamesCommand(null);
                                  _settingsManager
                                      .setCurrentTimeInMillisecondsCommand(
                                          null);

                                  setState(() {
                                    currentlyRunning = false;
                                    reset = true;
                                    gamesWereStarted = false;
                                  });
                                },
                          icon: const Icon(Icons.refresh),
                          color: textColor,
                          tooltip: "Spiel zurücksetzen",
                        ),
                    ],
                  ),
                  if (widget.first)
                    IconButton(
                      onPressed: () => _handleEndGames(context),
                      icon: Icon(
                        Icons.start,
                        color: textColor,
                      ),
                      tooltip: "Spiel beenden",
                    )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
              bottom: 10,
            ),
            child: Column(
              children: gameWidgets,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEndGames(BuildContext context) async {
    final isBreakGroup = _isBreakGroup();

    if (!isBreakGroup && !gamesWereStarted) {
      if (context.mounted) {
        showError(
          context,
          'Spiele wurden nicht gestartet und konnten daher nicht beendet werden',
        );
      }
      return;
    }

    if (!gameTimeEnded && !isBreakGroup) {
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning),
          iconColor: Colors.yellow,
          title: const Text('Spiele beenden'),
          content: const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Spielzeit ist noch nicht abgelaufen. Spiele wirklich beenden?',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => GoRouter.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () => GoRouter.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      );

      if (dialogResult != true) {
        return;
      }
    }

    final result = await _gameManager.endCurrentGamesCommand.executeWithFuture(
      widget.gameGroup.startTime,
    );

    setState(() {
      currentlyRunning = false;
      reset = true;
      gamesWereStarted = false;
    });

    if (result) {
      _settingsManager.setCurrentlyRunningGamesCommand(null);
      _settingsManager.setCurrentTimeInMillisecondsCommand(null);
      _gameManager.getCurrentRoundCommand();
      return;
    }

    if (context.mounted) {
      showError(context, 'Spiele konnten nicht beendet werden');
    }
  }
}

class CountDownView extends StatefulWidget {
  const CountDownView({
    super.key,
    required this.playTimeInSeconds,
    required this.textColor,
    required this.start,
    required this.refresh,
    this.onEnded,
    this.onHalftime,
    this.startTimeInMilliSeconds,
  });

  final int playTimeInSeconds;
  final Color textColor;
  final bool start;
  final bool refresh;
  final void Function()? onEnded;
  final void Function()? onHalftime;

  final int? startTimeInMilliSeconds;

  @override
  State<CountDownView> createState() => _CountDownViewState();
}

class _CountDownViewState extends State<CountDownView> {
  String currentTime = '';
  bool onEndedCalled = false;
  bool halfTimeSoundPlayed = false;

  final soundPlayerService = di<SoundPlayerService>();
  var settingsManager = di<SettingsManager>();

  late final StopWatchTimer _stopWatchTimer;

  @override
  void initState() {
    final minutes = widget.playTimeInSeconds ~/ 60;
    final seconds = widget.playTimeInSeconds % 60;
    currentTime =
        '00:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.00';
    var totalTimeInMilliSeconds = widget.playTimeInSeconds * 1000;

    _stopWatchTimer = StopWatchTimer(
      mode: StopWatchMode.countDown,
      presetMillisecond: totalTimeInMilliSeconds,
      onChange: (value) {
        settingsManager.setCurrentTimeInMillisecondsCommand(value);
        final displayTime = StopWatchTimer.getDisplayTime(value);

        setState(() {
          currentTime = displayTime;
        });

        final halfTimeThreshold = totalTimeInMilliSeconds / 2;
        if (value <= halfTimeThreshold && !halfTimeSoundPlayed) {
          soundPlayerService.playSound(Sounds.horn);
          setState(() {
            halfTimeSoundPlayed = true;
          });
          widget.onHalftime?.call();
        }

        // end music is 32 seconds, where 3 seconds are the horn that signals the end
        const endMusicThreshold = 29 * 1000;
        if (value <= endMusicThreshold && !onEndedCalled) {
          soundPlayerService.playSound(Sounds.endMusic);
          setState(() {
            onEndedCalled = true;
          });
        }
      },
      onEnded: () {
        settingsManager.setCurrentlyRunningGamesCommand(null);
        settingsManager.setCurrentTimeInMillisecondsCommand(null);
        widget.onEnded?.call();

        // in case the end music was not yet played (maybe because of too short duration), play horn at the end
        if (!onEndedCalled) {
          soundPlayerService.playSound(Sounds.horn);
          setState(() {
            onEndedCalled = true;
          });
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _stopWatchTimer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.refresh) {
      if (_stopWatchTimer.isRunning) {
        _stopWatchTimer.onResetTimer();
        _stopWatchTimer.clearPresetTime();
      }

      if (mounted) {
        setState(() {
          onEndedCalled = false;
          halfTimeSoundPlayed = false;
        });
      }
    } else if (widget.start) {
      if (!_stopWatchTimer.isRunning) {
        if (widget.startTimeInMilliSeconds != null) {
          _stopWatchTimer.setPresetTime(
            mSec: widget.startTimeInMilliSeconds!,
            add: false,
          );
        } else {
          _stopWatchTimer.setPresetTime(
            mSec: widget.playTimeInSeconds * 1000,
            add: false,
          );
        }
        _stopWatchTimer.onStartTimer();
      }
    } else if (_stopWatchTimer.isRunning) {
      _stopWatchTimer.onStopTimer();
    }

    return Text(
      currentTime,
      style: Constants.mediumHeaderTextStyle.copyWith(color: widget.textColor),
    );
  }
}

class GameEntryView extends StatelessWidget {
  const GameEntryView({
    super.key,
    required this.gameRoundEntry,
    required this.textColor,
    this.onDeleteBreak,
  });

  final Game gameRoundEntry;
  final Color textColor;
  final void Function(String breakId)? onDeleteBreak;

  @override
  Widget build(BuildContext context) {
    final isBreak = gameRoundEntry.type == ItemType.break_;
    final effectiveColor = isBreak ? Colors.black : textColor;
    var textStyle = Constants.standardTextStyle.copyWith(color: effectiveColor);

    final row = Row(
      children: [
        Row(
          children: [
            Text(
              gameRoundEntry.ageGroupName,
              style: textStyle,
            ),
            const SizedBox(width: 5),
            Text(
              '|',
              style: textStyle,
            ),
            const SizedBox(width: 5),
            Text(
              gameRoundEntry.leagueName,
              style: textStyle,
            ),
            const SizedBox(width: 5),
            Text(
              '|',
              style: textStyle,
            ),
            const SizedBox(width: 5),
            Text(
              gameRoundEntry.pitch.name,
              style: textStyle,
            ),
          ],
        ),
        const SizedBox(width: 5),
        Expanded(
          child: isBreak
              ? Center(
                  child: Text(
                    'PAUSE',
                    style: textStyle,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gameRoundEntry.teamA.name,
                      style: textStyle,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      ':',
                      style: textStyle,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      gameRoundEntry.teamB.name,
                      style: textStyle,
                    ),
                  ],
                ),
        ),
        if (isBreak && onDeleteBreak != null)
          IconButton(
            onPressed: () => onDeleteBreak!(gameRoundEntry.id),
            icon: const Icon(Icons.delete),
            tooltip: 'Pause entfernen',
            color: effectiveColor,
          ),
      ],
    );

    if (isBreak) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.yellow.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: row,
        ),
      );
    }
    return row;
  }
}
