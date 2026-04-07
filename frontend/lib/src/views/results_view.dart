import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/manager/game_manager_base.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/results/league.dart';
import 'package:watch_it/watch_it.dart';

class ResultsView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const ResultsView(
    this.ageGroupName, {
    super.key,
  });

  final String ageGroupName;

  static const routeName = '/results';
  static const ageGroupQueryParam = 'ageGroup';

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  var refreshTimerIsRunning = false;
  var timerWasStarted = false;

  @override
  Widget build(BuildContext context) {
    final GameManager gameManager = di<GameManager>();

    var results = watchPropertyValue((GameManager manager) => manager.results);
    watchPropertyValue((GameManager manager) =>
        manager.ageGroups); // listen to updates for agegroups
    var ageGroup = gameManager.getAgeGroupByName(widget.ageGroupName);

    if (ageGroup == null) {
      if (!timerWasStarted) {
        timerWasStarted = true;

        Timer(
          const Duration(seconds: 1),
          () {
            setState(
              () {
                refreshTimerIsRunning = false;
              },
            );
          },
        );

        setState(
          () {
            refreshTimerIsRunning = true;
          },
        );
      }

      if (refreshTimerIsRunning) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      timerWasStarted = false;

      return Center(
        child: Text('Altersklasse "${widget.ageGroupName}" nicht vorhanden!'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const Center(
          child: Text(
            'Ergebnisse',
            style: Constants.largeHeaderTextStyle,
          ),
        ),
        leadingWidth: 150,
        actions: [
          Text(
            ageGroup.name,
            style: Constants.largeHeaderTextStyle,
          ),
          const SizedBox(width: 5),
          const Text(
            '|',
            style: Constants.largeHeaderTextStyle,
          ),
          const SizedBox(width: 5),
          Text(
            results.roundName,
            style: Constants.largeHeaderTextStyle,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ResultsContentView(ageGroup: ageGroup),
    );
  }
}

class ResultsContentView extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const ResultsContentView({
    super.key,
    required this.ageGroup,
  });

  final AgeGroup ageGroup;

  @override
  State<ResultsContentView> createState() => _ResultsContentViewState();
}

class _ResultsContentViewState extends State<ResultsContentView> {
  Timer? refreshTimer;

  final ItemScrollController itemScrollController = ItemScrollController();
  var currentScrollIndex = 1;
  var amountItems = 0;

  @override
  void initState() {
    if (refreshTimer != null) {
      refreshTimer?.cancel();
      refreshTimer = null;
    }

    refreshTimer ??= Timer.periodic(
        const Duration(seconds: Constants.refreshDurationInSeconds), (timer) {
      final GameManager gameManager = di<GameManager>();
      gameManager.getResultsCommand(widget.ageGroup.id);

      if (amountItems > 0) {
        itemScrollController.scrollTo(
            index: currentScrollIndex,
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOutCubic);

        currentScrollIndex++;
      }
      if (currentScrollIndex >= amountItems) {
        currentScrollIndex = 0;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    refreshTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var results = watchPropertyValue((GameManager manager) => manager.results);
    amountItems = results.leagueTables.length;

    var amountLeagues = results.leagueTables.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        var enclosingPadding = 20;
        var leaguePadding = amountLeagues > 1 ? 10 : 0;
        var displayFactor = amountLeagues > 1 ? 2 : 1;
        var parentWidth = constraints.maxWidth;
        var leagueWidgetSize =
            (parentWidth - enclosingPadding - leaguePadding) / displayFactor;
        leagueWidgetSize = leagueWidgetSize < 750
            ? parentWidth - enclosingPadding
            : leagueWidgetSize;

        return Padding(
          padding: EdgeInsets.all(enclosingPadding / 2),
          child: ScrollablePositionedList.builder(
            itemScrollController: itemScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: results.leagueTables.length,
            itemBuilder: (context, index) {
              var entry = results.leagueTables[index];
              return LeagueView(
                league: entry,
                width: leagueWidgetSize,
              );
            },
          ),
        );
      },
    );
  }
}

enum LeagueWidgetSize {
  small,
  medium,
  large,
}

class LeagueView extends StatefulWidget {
  const LeagueView({
    super.key,
    required this.league,
    required this.width,
  });

  final League league;
  final double width;

  @override
  State<LeagueView> createState() => _LeagueViewState();
}

class _LeagueViewState extends State<LeagueView> {
  Timer? refreshTimer;
  var controller = ScrollController();

  final Color textColor = Colors.white;

  @override
  void initState() {
    if (refreshTimer != null) {
      refreshTimer?.cancel();
      refreshTimer = null;
    }

    var refreshDurationInSecondsInternal =
        Constants.refreshDurationInSeconds / 2;

    refreshTimer ??= Timer.periodic(
      Duration(seconds: refreshDurationInSecondsInternal.round()),
      (timer) {
        if (controller.offset <= controller.position.minScrollExtent) {
          controller.animateTo(
            controller.position.maxScrollExtent,
            duration: Duration(
                seconds: (refreshDurationInSecondsInternal / 2).round()),
            curve: Curves.linear,
          );
        } else {
          controller.animateTo(
            controller.position.minScrollExtent,
            duration: Duration(
                seconds: (refreshDurationInSecondsInternal / 2).round()),
            curve: Curves.linear,
          );
        }
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    refreshTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LeagueWidgetSize leagueWidgetSize = LeagueWidgetSize.large;
    if (widget.width < 750 && widget.width > 500) {
      leagueWidgetSize = LeagueWidgetSize.medium;
    } else if (widget.width <= 500) {
      leagueWidgetSize = LeagueWidgetSize.small;
    }

    var columnHeaderTextStyle = Constants.standardTextStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    var columnEntryTextStyle = Constants.standardTextStyle.copyWith(
      color: textColor,
    );

    List<DataColumn> columns = [];
    columns.add(DataColumn(
      numeric: true,
      label: Text(
        '#',
        style: columnHeaderTextStyle,
      ),
    ));

    columns.add(DataColumn(
      label: Text(
        'Mannschaft',
        style: columnHeaderTextStyle,
      ),
    ));

    if (leagueWidgetSize == LeagueWidgetSize.large ||
        leagueWidgetSize == LeagueWidgetSize.medium) {
      columns.add(DataColumn(
        numeric: true,
        label: Text(
          'S',
          style: columnHeaderTextStyle,
        ),
      ));

      columns.add(DataColumn(
        numeric: true,
        label: Text(
          'U',
          style: columnHeaderTextStyle,
        ),
      ));

      columns.add(DataColumn(
        numeric: true,
        label: Text(
          'N',
          style: columnHeaderTextStyle,
        ),
      ));
    }

    if (leagueWidgetSize == LeagueWidgetSize.large) {
      columns.add(DataColumn(
        label: Text(
          'Sätze',
          style: columnHeaderTextStyle,
        ),
      ));

      columns.add(DataColumn(
        numeric: true,
        label: Text(
          'Diff.',
          style: columnHeaderTextStyle,
        ),
      ));
    }

    columns.add(DataColumn(
      numeric: true,
      label: Text(
        'Pkt.',
        style: columnHeaderTextStyle,
      ),
    ));

    columns.add(DataColumn(
      numeric: true,
      label: Text(
        'Wertung',
        style: columnHeaderTextStyle,
      ),
    ));

    List<DataRow> rows = [];
    for (var result in widget.league.teams) {
      var index = widget.league.teams.indexOf(result) + 1;
      List<DataCell> cells = [];

      cells.add(
        DataCell(
          Text(
            index.toString(),
            style: columnEntryTextStyle,
          ),
        ),
      );

      cells.add(
        DataCell(
          Text(
            result.teamName,
            style: columnEntryTextStyle,
          ),
        ),
      );

      if (leagueWidgetSize == LeagueWidgetSize.large ||
          leagueWidgetSize == LeagueWidgetSize.medium) {
        cells.add(
          DataCell(
            Text(
              result.victories.toString(),
              style: columnEntryTextStyle,
            ),
          ),
        );

        cells.add(
          DataCell(
            Text(
              result.draws.toString(),
              style: columnEntryTextStyle,
            ),
          ),
        );

        cells.add(
          DataCell(
            Text(
              result.defeats.toString(),
              style: columnEntryTextStyle,
            ),
          ),
        );
      }

      if (leagueWidgetSize == LeagueWidgetSize.large) {
        cells.add(
          DataCell(
            Text(
              '${result.ownScoredGoals} : ${result.enemyScoredGoals}',
              style: columnEntryTextStyle,
            ),
          ),
        );

        cells.add(
          DataCell(
            Text(
              result.goalPointsDifference.toString(),
              style: columnEntryTextStyle,
            ),
          ),
        );
      }

      cells.add(
        DataCell(
          Text(
            result.totalPoints.toString(),
            style: columnEntryTextStyle,
          ),
        ),
      );

      cells.add(
        DataCell(
          Text(
            result.avgGoalDiffScore != null
                ? result.avgGoalDiffScore!.toStringAsFixed(1)
                : '-',
            style: columnEntryTextStyle,
          ),
        ),
      );

      rows.add(DataRow(cells: cells));
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  Text(
                    widget.league.leagueName,
                    style: Constants.mediumHeaderTextStyle,
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.sports_volleyball),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[800],
              width: widget.width,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                    controller: controller,
                    child: DataTable(
                      columnSpacing: 12,
                      columns: columns,
                      rows: rows,
                    )),
              ),
            ),
          )
        ],
      ),
    );
  }
}
