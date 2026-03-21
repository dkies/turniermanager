import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/manager/game_manager.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/model/schedule/league.dart';
import 'package:tournament_manager/src/model/schedule/match_schedule_entry.dart';
import 'package:tournament_manager/src/serialization/schedule/item_type.dart';
import 'package:watch_it/watch_it.dart';

class ScheduleView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const ScheduleView(
    this.ageGroupName, {
    super.key,
  });

  final String ageGroupName;

  static const routeName = '/schedule';
  static const ageGroupQueryParam = 'ageGroup';

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  var refreshTimerIsRunning = false;
  var timerWasStarted = false;

  @override
  Widget build(BuildContext context) {
    final GameManager gameManager = di<GameManager>();

    var schedule =
        watchPropertyValue((GameManager manager) => manager.schedule);
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
            'Spielplan',
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
            schedule.roundName,
            style: Constants.largeHeaderTextStyle,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ScheduleContentView(ageGroup: ageGroup),
    );
  }
}

class ScheduleContentView extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const ScheduleContentView({
    super.key,
    required this.ageGroup,
  });

  final AgeGroup ageGroup;

  @override
  State<ScheduleContentView> createState() => _ScheduleContentViewState();
}

class _ScheduleContentViewState extends State<ScheduleContentView> {
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
      gameManager.getScheduleCommand(widget.ageGroup.id);

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
    var schedule =
        watchPropertyValue((GameManager manager) => manager.schedule);
    amountItems = schedule.leagueSchedules.length;

    var screenSize = MediaQuery.sizeOf(context);
    var amountLeagues = schedule.leagueSchedules.length;
    var enclosingPadding = 20;
    var leaguePadding = amountLeagues > 1 ? 10 : 0;
    var displayFactor = amountLeagues > 1 ? 2 : 1;
    var leagueWidgetSize =
        (screenSize.width - enclosingPadding - leaguePadding) / displayFactor;
    leagueWidgetSize = leagueWidgetSize < 500
        ? screenSize.width - enclosingPadding
        : leagueWidgetSize;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: schedule.leagueSchedules.length,
        itemBuilder: (context, index) {
          var entry = schedule.leagueSchedules[index];
          return LeagueView(
            league: entry,
            width: leagueWidgetSize,
          );
        },
      ),
    );
  }
}

class LeagueView extends StatelessWidget {
  const LeagueView({
    super.key,
    required this.league,
    required this.width,
  });

  final League league;
  final double width;

  @override
  Widget build(BuildContext context) {
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
                    league.leagueName,
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
              width: width,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Builder(
                  builder: (context) {
                    final displayItems =
                        _expandScheduleEntriesForBreakGroups(league.entries);
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        if (item is ScheduleBreakGroup) {
                          return ScheduleBreakGroupView(group: item);
                        }
                        return ScheduleEntryView(
                            matchScheduleEntry: item as MatchScheduleEntry);
                      },
                      separatorBuilder: (context, index) => const Divider(),
                      itemCount: displayItems.length,
                    );
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ScheduleEntryView extends StatelessWidget {
  const ScheduleEntryView({
    super.key,
    required this.matchScheduleEntry,
  });

  final MatchScheduleEntry matchScheduleEntry;

  @override
  Widget build(BuildContext context) {
    final isBreak = matchScheduleEntry.itemType == ItemType.break_;
    final textStyle = isBreak
        ? Constants.standardTextStyle.copyWith(color: Colors.black)
        : Constants.standardTextStyle;

    final content = Row(
      children: [
        SizedBox(
          width: 240,
          child: Row(
            children: [
              Text(
                matchScheduleEntry.pitchName,
                style: textStyle,
              ),
              const SizedBox(width: 5),
              Text(
                '|',
                style: textStyle,
              ),
              const SizedBox(width: 5),
              Text(
                '${DateFormat.Hm().format(matchScheduleEntry.startTime)} - ${DateFormat.Hm().format(matchScheduleEntry.endTime)}',
                style: textStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isBreak
                    ? (matchScheduleEntry.teamAName.trim().isEmpty
                        ? 'PAUSE'
                        : 'PAUSE: ${matchScheduleEntry.teamAName}')
                    : '${matchScheduleEntry.teamAName} : ${matchScheduleEntry.teamBName}',
                style: textStyle,
              ),
            ],
          ),
        ),
      ],
    );

    if (isBreak) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.yellow.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: content,
    );
  }
}

/// Consecutive [ItemType.break_] entries sharing the same start/end time.
class ScheduleBreakGroup {
  ScheduleBreakGroup(this.entries);
  final List<MatchScheduleEntry> entries;
}

/// Merges multiple subsequent breaks with identical time slots into [ScheduleBreakGroup].
List<Object> _expandScheduleEntriesForBreakGroups(
    List<MatchScheduleEntry> entries) {
  final out = <Object>[];
  var i = 0;
  while (i < entries.length) {
    final e = entries[i];
    if (e.itemType != ItemType.break_) {
      out.add(e);
      i++;
      continue;
    }
    final group = <MatchScheduleEntry>[e];
    var j = i + 1;
    while (j < entries.length) {
      final n = entries[j];
      if (n.itemType != ItemType.break_) break;
      if (n.startTime != group.first.startTime ||
          n.endTime != group.first.endTime) {
        break;
      }
      group.add(n);
      j++;
    }
    if (group.length > 1) {
      out.add(ScheduleBreakGroup(group));
    } else {
      out.add(group.first);
    }
    i = j;
  }
  return out;
}

class ScheduleBreakGroupView extends StatelessWidget {
  const ScheduleBreakGroupView({
    super.key,
    required this.group,
  });

  final ScheduleBreakGroup group;

  @override
  Widget build(BuildContext context) {
    final first = group.entries.first;
    final textStyle =
        Constants.standardTextStyle.copyWith(color: Colors.black);
    final timeText =
        '${DateFormat.Hm().format(first.startTime)} - ${DateFormat.Hm().format(first.endTime)}';

    final lineWidgets = <Widget>[];
    for (var i = 0; i < group.entries.length; i++) {
      if (i > 0) {
        lineWidgets.add(const SizedBox(height: 4));
      }
      final e = group.entries[i];
      final team = e.teamAName.trim();
      final pauseLine = team.isEmpty
          ? 'PAUSE auf ${e.pitchName}'
          : 'PAUSE auf ${e.pitchName}: $team';
      lineWidgets.add(Text(pauseLine, style: textStyle));
    }

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: Text(
            timeText,
            style: textStyle,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lineWidgets,
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow.shade400,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: content,
    );
  }
}
