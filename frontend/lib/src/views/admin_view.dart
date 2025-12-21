import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/helper/error_helper.dart';
import 'package:tournament_manager/src/manager/game_manager.dart';
import 'package:tournament_manager/src/model/admin/extended_game.dart';
import 'package:watch_it/watch_it.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  static const routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Center(
          child: Text(
            'Admin',
            style: Constants.largeHeaderTextStyle,
          ),
        ),
        leadingWidth: 100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: const [
            GameScoreView(),
            SizedBox(height: 10),
            PitchPrinter(),
          ],
        ),
      ),
    );
  }
}

class PitchPrinter extends StatelessWidget with WatchItMixin {
  const PitchPrinter({super.key});

  final _gameManager = di<GameManager>();

  @override
  Widget build(BuildContext context) {
    final pitches = watchPropertyValue((GameManager manager) => manager.pitches);
    final pitchWidgets = pitches.map(
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
    ).toList();

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
    final result = await _gameManager.printPitchCommand.executeWithFuture(pitchId);

    if (result || !context.mounted) {
      return;
    }

    showError(
      context,
      'Schiedrichterzettel für Platz #$pitchId konnte nicht erstellt werden!',
    );
  }

  Future<void> _handlePrintAllPitches(BuildContext context) async {
    final result = await _gameManager.printAllPitchesCommand.executeWithFuture();

    if (result || !context.mounted) {
      return;
    }

    showError(
      context,
      'Ein oder mehrere Schiedrichterzettel konnten nicht erstellt werden!',
    );
  }
}

class GameScoreView extends StatelessWidget with WatchItMixin {
  const GameScoreView({super.key});

  final _gameManager = di<GameManager>();

  static const _columns = [
    DataColumn(label: Text('#', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Startzeit', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Platz', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Altersklasse', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Liga', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Team A Name', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Team A Score', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text(':', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Team B Score', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Team B Name', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Actions', style: Constants.standardTextStyle.copyWith(fontWeight: FontWeight.bold))),
  ];

  @override
  Widget build(BuildContext context) {
    var games = watchPropertyValue((GameManager manager) => manager.games);
    
    // Create a sorted copy instead of mutating the original list
    final sortedGames = List<ExtendedGame>.from(games)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

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
          child: DataTable(
            columns: _columns,
            rows: sortedGames.map((game) => _GameRow(game: game, gameManager: _gameManager)).toList(),
          ),
        ),
      ],
    );
  }
}

class _GameRow extends StatefulWidget {
  const _GameRow({
    required this.game,
    required this.gameManager,
  });

  final ExtendedGame game;
  final GameManager gameManager;

  @override
  State<_GameRow> createState() => _GameRowState();
}

class _GameRowState extends State<_GameRow> {
  late final TextEditingController _teamAController;
  late final TextEditingController _teamBController;

  @override
  void initState() {
    super.initState();
    _teamAController = TextEditingController(text: widget.game.pointsTeamA.toString());
    _teamBController = TextEditingController(text: widget.game.pointsTeamB.toString());
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DataRow(
      cells: [
        DataCell(Text(widget.game.gameNumber.toString(), style: Constants.standardTextStyle)),
        DataCell(Text(DateFormat.Hm().format(widget.game.startTime), style: Constants.standardTextStyle)),
        DataCell(Text(widget.game.pitch, style: Constants.standardTextStyle)),
        DataCell(Text(widget.game.ageGroupName, style: Constants.standardTextStyle)),
        DataCell(Text(widget.game.leagueName, style: Constants.standardTextStyle)),
        DataCell(Text(widget.game.teamA, style: Constants.standardTextStyle)),
        DataCell(TextField(controller: _teamAController)),
        const DataCell(Text(':', style: Constants.standardTextStyle)),
        DataCell(TextField(controller: _teamBController)),
        DataCell(Text(widget.game.teamB, style: Constants.standardTextStyle)),
        DataCell(
          IconButton(
            onPressed: () async {
              final teamAScore = int.tryParse(_teamAController.text);
              final teamBScore = int.tryParse(_teamBController.text);

              if (teamAScore == null || teamBScore == null) {
                if (context.mounted) {
                  showError(
                    context,
                    "Spiel #${widget.game.gameNumber} konnte nicht gespeichert werden! Falsches Zahlenformat!",
                  );
                }
                return;
              }

              final result = await widget.gameManager.saveGameCommand.executeWithFuture((
                widget.game.gameNumber,
                teamAScore,
                teamBScore,
              ));

              if (!context.mounted) {
                return;
              }

              if (!result) {
                showError(
                  context,
                  "Spiel #${widget.game.gameNumber} konnte nicht gespeichert werden! Server-Fehler / Exception!",
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

