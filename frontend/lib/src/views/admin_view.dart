import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/helper/error_helper.dart';
import 'package:tournament_manager/src/manager/game_manager_base.dart';
import 'package:tournament_manager/src/manager/settings_manager.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:tournament_manager/src/model/referee/game_settings.dart';
import 'package:tournament_manager/src/model/referee/round_settings.dart';
import 'package:tournament_manager/src/serialization/game_status.dart';
import 'package:tournament_manager/src/views/unsaved_changes_browser_guard.dart'
    if (dart.library.html)
        'package:tournament_manager/src/views/unsaved_changes_browser_guard_web.dart';
import 'package:watch_it/watch_it.dart';

class AdminView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const AdminView({super.key});

  static const routeName = '/admin';

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  static const _leaveWarningText =
      'Es gibt ungespeicherte Änderungen. Seite wirklich verlassen?';
  final roundSettings = RoundSettings(
    GameSettings(
      DateTime.now(),
      60,
      300,
    ),
  );
  late final GameManager _gameManager;
  late final SettingsManager _settingsManager;
  late final BrowserUnsavedChangesGuard _browserUnsavedChangesGuard;
  bool _hasUnsavedLocalChanges = false;

  @override
  void initState() {
    super.initState();
    _gameManager = di<GameManager>();
    _settingsManager = di<SettingsManager>();
    _browserUnsavedChangesGuard = createBrowserUnsavedChangesGuard();
    _browserUnsavedChangesGuard.register(
      () => _hasUnsavedLocalChanges,
      message: _leaveWarningText,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ageGroups = _gameManager.ageGroups;
      for (final ageGroup in ageGroups) {
        roundSettings.numberPerRounds.update(
          ageGroup.id,
          (value) => Constants.maxNumberOfTeamsDefault,
          ifAbsent: () => Constants.maxNumberOfTeamsDefault,
        );
      }
    });
  }

  @override
  void dispose() {
    _browserUnsavedChangesGuard.dispose();
    super.dispose();
  }

  void _onHasUnsavedLocalChangesChanged(bool value) {
    if (_hasUnsavedLocalChanges == value) {
      return;
    }
    setState(() {
      _hasUnsavedLocalChanges = value;
    });
  }

  Future<bool> _confirmLeavingWithUnsavedChanges() async {
    if (!_hasUnsavedLocalChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.report_gmailerrorred_rounded,
          color: Colors.red,
        ),
        title: const Text('Ungespeicherte Änderungen'),
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
    final canLeave = await _confirmLeavingWithUnsavedChanges();
    if (!canLeave || !mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ageGroups =
        watchPropertyValue((GameManager manager) => manager.ageGroups);
    final currentlyRunningGames = watchPropertyValue(
        (SettingsManager manager) => manager.currentlyRunningGames);

    if (ageGroups.isNotEmpty) {
      for (final ageGroup in ageGroups) {
        roundSettings.numberPerRounds.update(
          ageGroup.id,
          (value) => Constants.maxNumberOfTeamsDefault,
          ifAbsent: () => Constants.maxNumberOfTeamsDefault,
        );
      }
    }

    return PopScope(
      canPop: !_hasUnsavedLocalChanges,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final canLeave = await _confirmLeavingWithUnsavedChanges();
        if (!canLeave || !context.mounted) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
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
                  'Admin',
                  style: Constants.largeHeaderTextStyle,
                ),
              ),
            ),
          ],
        ),
        leadingWidth: 220,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => _InsertBreakDialog(
                  gameManager: _gameManager,
                  ageGroups: ageGroups,
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Pause einfügen'),
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

                          Navigator.of(dialogContext).pop();

                          if (!result && context.mounted) {
                            showError(context,
                                'Nächste Runde konnte nicht gestartet werden!');
                          }
                        },
                        child: const Text('OK'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
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
          const SizedBox(width: 10),
        ],
        ),
        body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            GameScoreView(
              onHasUnsavedLocalChangesChanged: _onHasUnsavedLocalChangesChanged,
            ),
            SizedBox(height: 10),
            const PitchPrinter(),
            SizedBox(height: 10),
            const ResultPrinter(),
          ],
        ),
      ),
      ),
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
                label: Text('Pausenzeit (sek)'),
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
                label: Text('Spielzeit / Spiel (sek)'),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _InsertBreakDialog extends StatefulWidget {
  const _InsertBreakDialog({
    required this.gameManager,
    required this.ageGroups,
  });

  final GameManager gameManager;
  final List<AgeGroup> ageGroups;

  @override
  State<_InsertBreakDialog> createState() => _InsertBreakDialogState();
}

class _InsertBreakDialogState extends State<_InsertBreakDialog> {
  final _nameController = TextEditingController(text: 'Pause');
  bool _isGlobal = true;
  String? _selectedAgeGroupId;
  TimeOfDay _selectedTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 2)));
  int _amount = 1;

  @override
  void initState() {
    super.initState();
    if (widget.ageGroups.isNotEmpty) {
      _selectedAgeGroupId = widget.ageGroups.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final message = _nameController.text.trim();
    if (message.isEmpty) {
      showError(context, 'Name eingeben.');
      return;
    }
    if (!_isGlobal &&
        (_selectedAgeGroupId == null || _selectedAgeGroupId!.isEmpty)) {
      showError(context, 'Altersgruppe auswählen.');
      return;
    }

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (startTime.isBefore(now)) {
      showError(context, 'Die Uhrzeit darf nicht in der Vergangenheit liegen.');
      return;
    }

    final result = await widget.gameManager.addBreakCommand.executeWithFuture(
      (
        _isGlobal,
        startTime,
        _amount,
        message,
        _isGlobal ? null : _selectedAgeGroupId
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    if (result) {
      widget.gameManager.getCurrentRoundCommand();
    } else {
      showError(context, 'Pause konnte nicht eingefügt werden.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pause einfügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  label: Text('Uhrzeit'),
                  suffixIcon: Icon(Icons.schedule),
                ),
                child: Text(
                  _selectedTime.format(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                label: Text('Anzahl geblockte Spieleinheiten'),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed:
                        _amount <= 1 ? null : () => setState(() => _amount--),
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_amount',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _amount++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                label: Text('Name'),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isGlobal,
              onChanged: (v) => setState(() => _isGlobal = v ?? true),
              title: const Text('Global (alle Altersgruppen)'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (!_isGlobal) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAgeGroupId,
                decoration: const InputDecoration(
                  label: Text('Altersgruppe'),
                ),
                items: widget.ageGroups
                    .map((g) =>
                        DropdownMenuItem(value: g.id, child: Text(g.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAgeGroupId = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Einfügen'),
        ),
      ],
    );
  }
}

class PitchPrinter extends StatelessWidget with WatchItMixin {
  const PitchPrinter({super.key});

  GameManager get _gameManager => di<GameManager>();

  @override
  Widget build(BuildContext context) {
    final pitches =
        watchPropertyValue((GameManager manager) => manager.pitches);
    final pitchWidgets = pitches
        .map(
          (pitch) => SeparatedRow(
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            children: [
              Text('${pitch.name} (ID: ${pitch.id})'),
              IconButton(
                onPressed: () => _handlePrintPitch(context, pitch.id),
                icon: const Icon(Icons.print),
              ),
            ],
          ),
        )
        .toList();

    return SeparatedColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      children: [
        SeparatedRow(
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          children: [
            const Text(
              'Schiedsrichterzettel',
              style: Constants.mediumHeaderTextStyle,
            ),
            IconButton(
              onPressed: () => _handlePrintAllPitches(context),
              icon: const Icon(Icons.print),
              tooltip: 'Alles drucken',
            ),
          ],
        ),
        ...pitchWidgets
      ],
    );
  }

  Future<void> _handlePrintPitch(BuildContext context, String pitchId) async {
    final result =
        await _gameManager.printPitchCommand.executeWithFuture(pitchId);

    if (result || !context.mounted) {
      return;
    }

    showError(
      context,
      'Schiedrichterzettel für Platz #$pitchId konnte nicht erstellt werden!',
    );
  }

  Future<void> _handlePrintAllPitches(BuildContext context) async {
    final result =
        await _gameManager.printAllPitchesCommand.executeWithFuture();

    if (result || !context.mounted) {
      return;
    }

    showError(
      context,
      'Ein oder mehrere Schiedrichterzettel konnten nicht erstellt werden!',
    );
  }
}

class ResultPrinter extends StatelessWidget with WatchItMixin {
  const ResultPrinter({super.key});

  GameManager get _gameManager => di<GameManager>();

  @override
  Widget build(BuildContext context) {
    final ageGroups =
        watchPropertyValue((GameManager manager) => manager.ageGroups);

    final ageGroupWidgets = ageGroups
        .map(
          (ageGroup) => SeparatedRow(
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            children: [
              Text('${ageGroup.name} (ID: ${ageGroup.id})'),
              IconButton(
                onPressed: () => _handlePrintResults(context, ageGroup.id),
                icon: const Icon(Icons.print),
              ),
            ],
          ),
        )
        .toList();

    return SeparatedColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      children: [
        SeparatedRow(
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          children: [
            const Text(
              'Turnierergebnisse',
              style: Constants.mediumHeaderTextStyle,
            ),
            IconButton(
              onPressed: () => _handlePrintAllResults(context),
              icon: const Icon(Icons.print),
              tooltip: 'Alles drucken',
            ),
          ],
        ),
        ...ageGroupWidgets,
      ],
    );
  }

  Future<void> _handlePrintResults(
      BuildContext context, String ageGroupId) async {
    final result =
        await _gameManager.printResultsCommand.executeWithFuture(ageGroupId);

    if (result || !context.mounted) {
      return;
    }

    showError(
      context,
      'Turnierergebnisse für Altersgruppe #$ageGroupId konnten nicht erstellt werden!',
    );
  }

  Future<void> _handlePrintAllResults(BuildContext context) async {
    final result =
        await _gameManager.printAllResultsCommand.executeWithFuture();

    if (result || !context.mounted) {
      return;
    }

    showError(
      context,
      'Ein oder mehrere Turnierergebnisse konnten nicht erstellt werden!',
    );
  }
}

class GameScoreView extends StatelessWidget with WatchItMixin {
  const GameScoreView({
    super.key,
    required this.onHasUnsavedLocalChangesChanged,
  });

  GameManager get _gameManager => di<GameManager>();
  final ValueChanged<bool> onHasUnsavedLocalChangesChanged;

  static List<DataColumn> get _columns => [
        DataColumn(
            label: Text('#',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Startzeit',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Altersklasse',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Liga',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Team A Name',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Team A Score',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text(':',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Team B Score',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Team B Name',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Actions',
                style: Constants.standardTextStyle
                    .copyWith(fontWeight: FontWeight.bold))),
      ];

  @override
  Widget build(BuildContext context) {
    var games = watchPropertyValue((GameManager manager) => manager.games);

    final sortedGames = List<ExtendedGame>.from(games)
      ..sort((a, b) {
        final timeCmp = a.startTime.compareTo(b.startTime);
        if (timeCmp != 0) return timeCmp;
        return a.ageGroupName.compareTo(b.ageGroupName);
      });

    return SeparatedColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      children: [
        const Text(
          'Spielwertungen',
          style: Constants.mediumHeaderTextStyle,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: const [
            _LegendItem(
              color: Color(0x4DFFEB3B),
              label: 'Completed',
            ),
            _LegendItem(
              color: Color(0x4D4CAF50),
              label: 'Completed and stated',
            ),
            _LegendItem(
              color: Color(0x40F44336),
              label: 'Canceled',
            ),
            _LegendItem(
              color: Color(0x59FF9800),
              label: 'Ungespeicherte lokale Änderung (completed_and_stated)',
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _GameDataTable(
            games: sortedGames,
            gameManager: _gameManager,
            columns: _columns,
            onHasUnsavedLocalChangesChanged: onHasUnsavedLocalChangesChanged,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Constants.standardTextStyle),
      ],
    );
  }
}

class _GameDataTable extends StatefulWidget {
  const _GameDataTable({
    required this.games,
    required this.gameManager,
    required this.columns,
    required this.onHasUnsavedLocalChangesChanged,
  });

  final List<ExtendedGame> games;
  final GameManager gameManager;
  final List<DataColumn> columns;
  final ValueChanged<bool> onHasUnsavedLocalChangesChanged;

  @override
  State<_GameDataTable> createState() => _GameDataTableState();
}

class _GameDataTableState extends State<_GameDataTable> {
  final Map<int, TextEditingController> _teamAControllers = {};
  final Map<int, TextEditingController> _teamBControllers = {};
  final Set<int> _dirtyCompletedAndStatedGameNumbers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _emitUnsavedChangesState();
  }

  @override
  void didUpdateWidget(_GameDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Do not treat every parent rebuild as data update.
    // GameScoreView creates a new list instance on build; we only want to
    // sync controllers when the underlying game data actually changed.
    if (_hasRelevantGameDataChanged(oldWidget.games, widget.games)) {
      // Dispose controllers for games that are no longer in the list
      final currentGameNumbers = widget.games.map((g) => g.gameNumber).toSet();
      final oldGameNumbers = oldWidget.games.map((g) => g.gameNumber).toSet();

      for (final gameNumber in oldGameNumbers) {
        if (!currentGameNumbers.contains(gameNumber)) {
          _teamAControllers[gameNumber]?.dispose();
          _teamBControllers[gameNumber]?.dispose();
          _teamAControllers.remove(gameNumber);
          _teamBControllers.remove(gameNumber);
        }
      }

      // Create controllers for new games or update existing ones
      _initializeControllers();

      // Clear dirty status for games that are no longer in the list
      final currentGameNumbersSet =
          widget.games.map((g) => g.gameNumber).toSet();
      _dirtyCompletedAndStatedGameNumbers.removeWhere(
          (gameNumber) => !currentGameNumbersSet.contains(gameNumber));
      _emitUnsavedChangesState();
    }
  }

  bool _hasRelevantGameDataChanged(
    List<ExtendedGame> oldGames,
    List<ExtendedGame> newGames,
  ) {
    if (identical(oldGames, newGames)) {
      return false;
    }
    if (oldGames.length != newGames.length) {
      return true;
    }

    for (var i = 0; i < oldGames.length; i++) {
      final oldGame = oldGames[i];
      final newGame = newGames[i];
      if (oldGame.gameNumber != newGame.gameNumber ||
          oldGame.pointsTeamA != newGame.pointsTeamA ||
          oldGame.pointsTeamB != newGame.pointsTeamB ||
          oldGame.status != newGame.status ||
          oldGame.startTime != newGame.startTime) {
        return true;
      }
    }

    return false;
  }

  void _emitUnsavedChangesState() {
    widget.onHasUnsavedLocalChangesChanged(
      _dirtyCompletedAndStatedGameNumbers.isNotEmpty,
    );
  }

  void _initializeControllers() {
    for (final game in widget.games) {
      if (!_teamAControllers.containsKey(game.gameNumber)) {
        _teamAControllers[game.gameNumber] =
            TextEditingController(text: game.pointsTeamA.toString());
      } else {
        // Update existing controller if value changed
        final controller = _teamAControllers[game.gameNumber]!;
        if (controller.text != game.pointsTeamA.toString()) {
          controller.text = game.pointsTeamA.toString();
        }
      }

      if (!_teamBControllers.containsKey(game.gameNumber)) {
        _teamBControllers[game.gameNumber] =
            TextEditingController(text: game.pointsTeamB.toString());
      } else {
        // Update existing controller if value changed
        final controller = _teamBControllers[game.gameNumber]!;
        if (controller.text != game.pointsTeamB.toString()) {
          controller.text = game.pointsTeamB.toString();
        }
      }
    }
  }

  void _updateDirtyCompletedAndStatedStatus(
    ExtendedGame game,
    TextEditingController teamAController,
    TextEditingController teamBController,
  ) {
    final edited = teamAController.text != game.pointsTeamA.toString() ||
        teamBController.text != game.pointsTeamB.toString();
    final shouldBeDirty = game.status == GameStatus.completedAndStated && edited;
    final isDirty =
        _dirtyCompletedAndStatedGameNumbers.contains(game.gameNumber);

    if (shouldBeDirty == isDirty) {
      return;
    }

    setState(() {
      if (shouldBeDirty) {
        _dirtyCompletedAndStatedGameNumbers.add(game.gameNumber);
      } else {
        _dirtyCompletedAndStatedGameNumbers.remove(game.gameNumber);
      }
    });
    _emitUnsavedChangesState();
  }

  @override
  void dispose() {
    for (final controller in _teamAControllers.values) {
      controller.dispose();
    }
    for (final controller in _teamBControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: widget.columns,
      rows: _buildRows(context),
    );
  }

  bool _sameStartTime(ExtendedGame a, ExtendedGame b) =>
      a.startTime == b.startTime;

  DataRow _spacerRow() {
    return DataRow(
      cells: List.generate(
        widget.columns.length,
        (_) => const DataCell(SizedBox(height: 14)),
      ),
    );
  }

  List<DataRow> _buildRows(BuildContext context) {
    final games = widget.games;
    final rows = <DataRow>[];

    for (var i = 0; i < games.length; i++) {
      rows.add(_buildRow(context, games[i]));

      final hasNext = i + 1 < games.length;
      if (!hasNext) continue;

      final cur = games[i];
      final next = games[i + 1];
      if (_sameStartTime(cur, next)) continue;

      // Leerzeile nach jedem Startzeit-Block (ein oder mehrere Spiele).
      rows.add(_spacerRow());
    }

    return rows;
  }

  DataRow _buildRow(BuildContext context, ExtendedGame game) {
    // Ensure controllers exist (safety check)
    final teamAController = _teamAControllers[game.gameNumber] ??=
        TextEditingController(text: game.pointsTeamA.toString());
    final teamBController = _teamBControllers[game.gameNumber] ??=
        TextEditingController(text: game.pointsTeamB.toString());

    final isDirtyCompletedAndStated =
        _dirtyCompletedAndStatedGameNumbers.contains(game.gameNumber);
    final canSave = game.status == GameStatus.completed ||
        game.status == GameStatus.completedAndStated;
    final statusColor = switch (game.status) {
      GameStatus.completed => Colors.yellow.withOpacity(0.3),
      GameStatus.completedAndStated => Colors.green.withOpacity(0.3),
      GameStatus.canceled => Colors.red.withOpacity(0.25),
      _ => null,
    };
    final effectiveColor = isDirtyCompletedAndStated
        ? WidgetStateProperty.all(Colors.orange.withOpacity(0.35))
        : (statusColor == null ? null : WidgetStateProperty.all(statusColor));

    return DataRow(
      color: effectiveColor,
      cells: [
        DataCell(Text(game.gameNumber.toString(),
            style: Constants.standardTextStyle)),
        DataCell(Text(
          DateFormat.Hm().format(game.startTime),
          style: Constants.standardTextStyle,
        )),
        DataCell(Text(game.ageGroupName, style: Constants.standardTextStyle)),
        DataCell(Text(game.leagueName, style: Constants.standardTextStyle)),
        DataCell(Text(game.teamA, style: Constants.standardTextStyle)),
        DataCell(TextField(
          controller: teamAController,
          onChanged: (_) {
            _updateDirtyCompletedAndStatedStatus(
                game, teamAController, teamBController);
          },
        )),
        const DataCell(Text(':', style: Constants.standardTextStyle)),
        DataCell(TextField(
          controller: teamBController,
          onChanged: (_) {
            _updateDirtyCompletedAndStatedStatus(
                game, teamAController, teamBController);
          },
        )),
        DataCell(Text(game.teamB, style: Constants.standardTextStyle)),
        DataCell(
          IconButton(
            onPressed: !canSave
                ? null
                : () async {
              final teamAScore = int.tryParse(teamAController.text);
              final teamBScore = int.tryParse(teamBController.text);

              if (teamAScore == null || teamBScore == null) {
                if (context.mounted) {
                  showError(
                    context,
                    "Spiel #${game.gameNumber} konnte nicht gespeichert werden! Falsches Zahlenformat!",
                  );
                }
                return;
              }

              final result =
                  await widget.gameManager.saveGameCommand.executeWithFuture((
                game.gameNumber,
                teamAScore,
                teamBScore,
              ));

              if (!context.mounted) {
                return;
              }

              if (result) {
                setState(() {
                  _dirtyCompletedAndStatedGameNumbers.remove(game.gameNumber);
                });
                _emitUnsavedChangesState();
              } else {
                showError(
                  context,
                  "Spiel #${game.gameNumber} konnte nicht gespeichert werden! Server-Fehler / Exception!",
                );
              }
            },
            icon: const Icon(Icons.save),
          ),
        ),
      ],
    );
  }
}
