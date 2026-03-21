import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/helper/error_helper.dart';
import 'package:tournament_manager/src/manager/game_manager_base.dart';
import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:watch_it/watch_it.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  static const routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Zurück',
              onPressed: () => Navigator.of(context).pop(),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: const [
            GameScoreView(),
            SizedBox(height: 10),
            PitchPrinter(),
            SizedBox(height: 10),
            ResultPrinter(),
          ],
        ),
      ),
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
    final result = await _gameManager.printAllResultsCommand.executeWithFuture();

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
  const GameScoreView({super.key});

  GameManager get _gameManager => di<GameManager>();

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

    // Create a sorted copy instead of mutating the original list
    final sortedGames = List<ExtendedGame>.from(games)
      ..sort((a, b) => a.gameNumber.compareTo(b.gameNumber));

    return SeparatedColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      children: [
        const Text(
          'Spielwertungen',
          style: Constants.mediumHeaderTextStyle,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _GameDataTable(
            games: sortedGames,
            gameManager: _gameManager,
            columns: _columns,
          ),
        ),
      ],
    );
  }
}

class _GameDataTable extends StatefulWidget {
  const _GameDataTable({
    required this.games,
    required this.gameManager,
    required this.columns,
  });

  final List<ExtendedGame> games;
  final GameManager gameManager;
  final List<DataColumn> columns;

  @override
  State<_GameDataTable> createState() => _GameDataTableState();
}

class _GameDataTableState extends State<_GameDataTable> {
  final Map<int, TextEditingController> _teamAControllers = {};
  final Map<int, TextEditingController> _teamBControllers = {};
  final Set<int> _savedGameNumbers = {}; // Track successfully saved games
  final Map<int, (int teamAScore, int teamBScore)> _savedScores =
      {}; // Track saved scores

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(_GameDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when games list changes
    if (oldWidget.games != widget.games) {
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

      // Clear saved status for games that are no longer in the list
      final currentGameNumbersSet =
          widget.games.map((g) => g.gameNumber).toSet();
      _savedGameNumbers.removeWhere(
          (gameNumber) => !currentGameNumbersSet.contains(gameNumber));
      _savedScores.removeWhere(
          (gameNumber, _) => !currentGameNumbersSet.contains(gameNumber));
    }
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

  void _updateSavedStatus(
    int gameNumber,
    TextEditingController teamAController,
    TextEditingController teamBController,
  ) {
    final savedScore = _savedScores[gameNumber];

    if (savedScore == null) {
      // No saved score, nothing to do
      return;
    }

    final newTeamAScore = int.tryParse(teamAController.text);
    final newTeamBScore = int.tryParse(teamBController.text);

    if (newTeamAScore != null && newTeamBScore != null) {
      // Both values are valid numbers
      final matchesSaved =
          newTeamAScore == savedScore.$1 && newTeamBScore == savedScore.$2;

      final isCurrentlySaved = _savedGameNumbers.contains(gameNumber);

      if (matchesSaved && !isCurrentlySaved) {
        // Values match saved values but not marked as saved - mark as saved
        setState(() {
          _savedGameNumbers.add(gameNumber);
        });
      } else if (!matchesSaved && isCurrentlySaved) {
        // Values don't match saved values but marked as saved - remove saved status
        setState(() {
          _savedGameNumbers.remove(gameNumber);
        });
      }
    } else {
      // Invalid input - remove saved status if currently saved
      if (_savedGameNumbers.contains(gameNumber)) {
        setState(() {
          _savedGameNumbers.remove(gameNumber);
        });
      }
    }
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
      rows: widget.games.map((game) {
        // Ensure controllers exist (safety check)
        final teamAController = _teamAControllers[game.gameNumber] ??=
            TextEditingController(text: game.pointsTeamA.toString());
        final teamBController = _teamBControllers[game.gameNumber] ??=
            TextEditingController(text: game.pointsTeamB.toString());

        final isSaved = _savedGameNumbers.contains(game.gameNumber);

        return DataRow(
          color: isSaved
              ? WidgetStateProperty.all(Colors.green.withOpacity(0.3))
              : null,
          cells: [
            DataCell(Text(game.gameNumber.toString(),
                style: Constants.standardTextStyle)),
            DataCell(Text(DateFormat.Hm().format(game.startTime),
                style: Constants.standardTextStyle)),
            DataCell(
                Text(game.ageGroupName, style: Constants.standardTextStyle)),
            DataCell(Text(game.leagueName, style: Constants.standardTextStyle)),
            DataCell(Text(game.teamA, style: Constants.standardTextStyle)),
            DataCell(TextField(
              controller: teamAController,
              onChanged: (_) {
                _updateSavedStatus(
                    game.gameNumber, teamAController, teamBController);
              },
            )),
            const DataCell(Text(':', style: Constants.standardTextStyle)),
            DataCell(TextField(
              controller: teamBController,
              onChanged: (_) {
                _updateSavedStatus(
                    game.gameNumber, teamAController, teamBController);
              },
            )),
            DataCell(Text(game.teamB, style: Constants.standardTextStyle)),
            DataCell(
              IconButton(
                onPressed: () async {
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

                  final result = await widget.gameManager.saveGameCommand
                      .executeWithFuture((
                    game.gameNumber,
                    teamAScore,
                    teamBScore,
                  ));

                  if (!context.mounted) {
                    return;
                  }

                  if (result) {
                    // Mark game as successfully saved and store the saved scores
                    setState(() {
                      _savedGameNumbers.add(game.gameNumber);
                      _savedScores[game.gameNumber] = (teamAScore, teamBScore);
                    });
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
      }).toList(),
    );
  }
}
