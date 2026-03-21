import 'dart:async';
import 'package:flutter/material.dart';
import 'package:separated_column/separated_column.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/manager/game_manager_base.dart';
import 'package:tournament_manager/src/views/results_view.dart';
import 'package:tournament_manager/src/views/schedule_view.dart';
import 'package:watch_it/watch_it.dart';

class AgeGroupView extends StatefulWidget with WatchItStatefulWidgetMixin {
  const AgeGroupView({
    super.key,
    required this.ageGroupName,
  });

  final String ageGroupName;

  static const routeName = '/scheduleandresults';
  static const ageGroupQueryParam = 'ageGroup';

  @override
  State<AgeGroupView> createState() => _AgeGroupViewState();
}

class _AgeGroupViewState extends State<AgeGroupView> {
  var refreshTimerIsRunning = false;
  var timerWasStarted = false;

  @override
  Widget build(BuildContext context) {
    final GameManager gameManager = di<GameManager>();
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
            'Spielplan & Ergebnisse',
            style: Constants.largeHeaderTextStyle,
          ),
        ),
        leadingWidth: 300,
        actions: [
          Text(
            ageGroup.name,
            style: Constants.largeHeaderTextStyle,
          ),
        ],
      ),
      body: SeparatedColumn(
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        children: [
          Expanded(
            child: ScheduleContentView(ageGroup: ageGroup),
          ),
          Expanded(
            flex: 2,
            child: ResultsContentView(ageGroup: ageGroup),
          ),
        ],
      ),
    );
  }
}
