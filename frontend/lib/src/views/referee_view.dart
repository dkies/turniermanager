import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/helper/error_helper.dart';
import 'package:tournament_manager/src/manager/game_manager.dart';
import 'package:tournament_manager/src/manager/settings_manager.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/referee/game.dart';
import 'package:tournament_manager/src/model/referee/game_group.dart';
import 'package:tournament_manager/src/model/referee/game_settings.dart';
import 'package:tournament_manager/src/model/referee/round_settings.dart';
import 'package:tournament_manager/src/service/sound_player_service.dart';
import 'package:watch_it/watch_it.dart';
import 'package:intl/intl.dart';

class RefereeView extends StatefulWidget with WatchItStatefulWidgetMixin {
  RefereeView({super.key});

  static const routeName = '/referee';

  @override
  State<RefereeView> createState() => _RefereeViewState();
}

class _RefereeViewState extends State<RefereeView> {
  final roundSettings = RoundSettings(
    GameSettings(
      DateTime.now(),
      1,
      3,
    ),
  );
  bool barrierDissmissed = false;
  late final GameManager _gameManager;
  late final SettingsManager _settingsManager;

  @override
  void initState() {
    super.initState();
    _gameManager = di<GameManager>();
    _settingsManager = di<SettingsManager>();

    // Initialize round settings when age groups are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ageGroups = _gameManager.ageGroups;
      for (var ageGroup in ageGroups) {
        roundSettings.numberPerRounds.update(
          ageGroup.id,
          (value) => Constants.maxNumberOfTeamsDefault,
          ifAbsent: () => Constants.maxNumberOfTeamsDefault,
        );
      }
    });
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
    final ageGroups =
        watchPropertyValue((GameManager manager) => manager.ageGroups);

    // Update round settings when age groups change
    if (ageGroups.isNotEmpty) {
      for (var ageGroup in ageGroups) {
        roundSettings.numberPerRounds.update(
          ageGroup.id,
          (value) => Constants.maxNumberOfTeamsDefault,
          ifAbsent: () => Constants.maxNumberOfTeamsDefault,
        );
      }
    }

    final canPauseGames =
        watchPropertyValue((SettingsManager manager) => manager.canPause);
    final currentlyRunningGames = watchPropertyValue(
        (SettingsManager manager) => manager.currentlyRunningGames);

    var mainContent = Scaffold(
      appBar: AppBar(
        leading: const Center(
          child: Text(
            'Spielübersicht',
            style: Constants.largeHeaderTextStyle,
          ),
        ),
        leadingWidth: 200,
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
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => _SettingsDialog(
                  roundSettings: roundSettings,
                  ageGroups: ageGroups,
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: "Einstellungen (nächste Runde)",
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              if (currentlyRunningGames != null) {
                showError(context,
                    'Runde konnte nicht gewechselt werden, es laufen noch Spiele!');
                return;
              }

              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    icon: const Icon(Icons.warning),
                    iconColor: Colors.yellow,
                    title: const Text('Wechsel zur nächsten Runde'),
                    content: const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Soll diese Runde wirklich beendet werden?\nDieser Schritt kann nicht rückgängig gemacht werden!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () async {
                          final result = await _gameManager
                              .startNextRoundCommand
                              .executeWithFuture(roundSettings);
                          if (result) {
                            _gameManager.getCurrentRoundCommand();
                            _settingsManager
                                .setCurrentlyRunningGamesCommand(null);
                            _settingsManager
                                .setCurrentTimeInMillisecondsCommand(null);
                          }

                          if (!dialogContext.mounted) {
                            return;
                          }

                          GoRouter.of(dialogContext).pop();

                          if (!result && context.mounted) {
                            showError(context,
                                'Nächste Runde konnte nicht gestartet werden!');
                          }
                        },
                        child: const Text('OK'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          GoRouter.of(dialogContext).pop();
                        },
                        child: const Text('Abbrechen'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Row(
              children: [
                Icon(
                  Icons.double_arrow,
                  color: Colors.white,
                  size: Constants.headerIonSize,
                ),
                SizedBox(width: 5),
                Text(
                  'Nächste Runde',
                  style: Constants.largeHeaderTextStyle,
                ),
                SizedBox(width: 5),
                Icon(
                  Icons.double_arrow,
                  color: Colors.white,
                  size: Constants.headerIonSize,
                ),
              ],
            ),
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

    return Stack(
      children: [
        mainContent,
        if (currentlyRunningGames != null && !barrierDissmissed)
          ...unmuteBarrier,
      ],
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({
    required this.roundSettings,
    required this.ageGroups,
  });

  final RoundSettings roundSettings;
  final List<AgeGroup> ageGroups;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late final Map<String, TextEditingController> _teamControllers;
  late final TextEditingController _breakTimeController;
  late final TextEditingController _playTimeController;

  @override
  void initState() {
    super.initState();
    _teamControllers = {
      for (var ageGroup in widget.ageGroups)
        ageGroup.id: TextEditingController(
          text: widget.roundSettings.numberPerRounds[ageGroup.id]?.toString() ??
              Constants.maxNumberOfTeamsDefault.toString(),
        )
    };
    _breakTimeController = TextEditingController(
      text: widget.roundSettings.gameSettings.breakTime.toString(),
    );
    _playTimeController = TextEditingController(
      text: widget.roundSettings.gameSettings.playTime.toString(),
    );
  }

  @override
  void dispose() {
    for (var controller in _teamControllers.values) {
      controller.dispose();
    }
    _breakTimeController.dispose();
    _playTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Einstellungen (nächste Runde)'),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: 300,
        child: Column(
          children: [
            const Text('Max. Anzahl Teams / Runde'),
            Expanded(
              child: ListView.separated(
                itemBuilder: (_, index) {
                  final ageGroup = widget.ageGroups[index];
                  final controller = _teamControllers[ageGroup.id]!;

                  return TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      label: Text(ageGroup.name),
                    ),
                    onChanged: (userInput) {
                      final result = int.tryParse(userInput);
                      if (result == null) {
                        return;
                      }

                      widget.roundSettings.numberPerRounds.update(
                        ageGroup.id,
                        (value) => result,
                        ifAbsent: () => result,
                      );
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: widget.ageGroups.length,
              ),
            ),
            const Text('Sonstiges'),
            TextField(
              controller: _breakTimeController,
              decoration: const InputDecoration(
                label: Text('Pausenzeit (min)'),
              ),
              onChanged: (userInput) {
                final result = int.tryParse(userInput);
                if (result == null) {
                  return;
                }

                widget.roundSettings.gameSettings.breakTime = result;
              },
            ),
            TextField(
              controller: _playTimeController,
              decoration: const InputDecoration(
                label: Text('Spielzeit / Spiel (min)'),
              ),
              onChanged: (userInput) {
                final result = int.tryParse(userInput);
                if (result == null) {
                  return;
                }

                widget.roundSettings.gameSettings.playTime = result;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => GoRouter.of(context).pop(),
          child: const Text('OK'),
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
  DateTime? currentGamesActualStart;

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

  @override
  Widget build(BuildContext context) {
    void startOrPauseGames() {
      if (!currentlyRunning && currentGamesActualStart == null) {
        currentGamesActualStart = DateTime.now();
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

    final textColor = currentlyRunning ? selectedTextColor : standardTextColor;
    final games = widget.gameGroup.games;
    final gameWidgets = <Widget>[];

    for (var i = 0; i < games.length; i++) {
      gameWidgets.add(
        GameEntryView(
          gameRoundEntry: games[i],
          textColor: textColor,
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
      color: currentlyRunning ? Colors.blue : null,
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
                        'Startzeit: ${DateFormat.Hm().format(widget.gameGroup.startTime)} Uhr',
                        style: headerTextStyle,
                      ),
                      const SizedBox(width: 10),
                      if (widget.first)
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
                      CountDownView(
                        timeInMinutes: widget.gameGroup.gameDurationInMinutes,
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
                      if (widget.first)
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
                                  });

                                  currentGamesActualStart = null;
                                },
                          icon: const Icon(Icons.refresh),
                          color: textColor,
                          tooltip: "Spiel zurücksetzen",
                        ),
                    ],
                  ),
                  if (!widget.first)
                    SizedBox(
                      width: 100,
                      child: Tooltip(
                        message: 'Pause einfügen (vorher)',
                        child: _BreakTextField(
                          gameGroup: widget.gameGroup,
                          gameManager: _gameManager,
                        ),
                      ),
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
    if (currentGamesActualStart == null) {
      if (context.mounted) {
        showError(context,
            'Spiele wurden nicht gestartet und konnten daher nicht beendet werden');
      }
      return;
    }

    if (!gameTimeEnded) {
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
      (
        widget.gameGroup.startTime,
        currentGamesActualStart!,
        DateTime.now(),
      ),
    );

    setState(() {
      currentlyRunning = false;
      reset = true;
      currentGamesActualStart = null;
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

class _BreakTextField extends StatelessWidget {
  const _BreakTextField({
    required this.gameGroup,
    required this.gameManager,
  });

  final GameGroup gameGroup;
  final GameManager gameManager;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        suffixIcon: Icon(Icons.more_time),
      ),
      onSubmitted: (value) async {
        final parsed = int.tryParse(value);
        if (parsed == null) {
          if (context.mounted) {
            showError(context, 'Falsches Zahlenformat!');
          }
          return;
        }

        final result = await gameManager.addBreakCommand.executeWithFuture(
          (
            gameGroup.startTime.subtract(
              const Duration(minutes: 1),
            ),
            parsed,
          ),
        );

        if (result) {
          gameManager.getCurrentRoundCommand();
          return;
        }

        if (context.mounted) {
          showError(context, 'Pause konnte nicht eingefügt werden!');
        }
      },
    );
  }
}

class CountDownView extends StatefulWidget {
  const CountDownView({
    super.key,
    required this.timeInMinutes,
    required this.textColor,
    required this.start,
    required this.refresh,
    this.onEnded,
    this.onHalftime,
    this.startTimeInMilliSeconds,
  });

  final int timeInMinutes;
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
    currentTime =
        '00:${widget.timeInMinutes < 10 ? '0' : ''}${widget.timeInMinutes}:00.00';
    var totalTimeInMilliSeconds =
        StopWatchTimer.getMilliSecFromMinute(widget.timeInMinutes);

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
  });

  final Game gameRoundEntry;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    var textStyle = Constants.standardTextStyle.copyWith(color: textColor);

    return Row(
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
          child: Row(
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
      ],
    );
  }
}
