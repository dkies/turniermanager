import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_manager/src/constants.dart';
import 'package:tournament_manager/src/manager/game_manager_base.dart';
import 'package:tournament_manager/src/model/age_group.dart';
import 'package:tournament_manager/src/views/admin_view.dart';
import 'package:tournament_manager/src/views/age_group_view.dart';
import 'package:tournament_manager/src/views/referee_view.dart';
import 'package:tournament_manager/src/views/results_view.dart';
import 'package:tournament_manager/src/views/schedule_view.dart';
import 'package:watch_it/watch_it.dart';

class LinkOverview extends StatelessWidget {
  const LinkOverview({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Turniermanager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        leadingWidth: 80,
      ),
      body: const LinkContentView(),
    );
  }
}

class LinkContentView extends StatelessWidget with WatchItMixin {
  const LinkContentView({super.key});

  @override
  Widget build(BuildContext context) {
    var ageGroups =
        watchPropertyValue((GameManager manager) => manager.ageGroups);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spielplan & Ergebnisse',
                    style: Constants.largeHeaderTextStyle,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        var ageGroup = ageGroups[index];

                        return ScheduleAndResultsLinkView(ageGroup: ageGroup);
                      },
                      itemCount: ageGroups.length,
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: LinkView(
                    header: 'Spielleiter',
                    onPressed: () {
                      context.go(".${Uri(path: RefereeView.routeName)}");
                    },
                  ),
                ),
                Expanded(
                  child: LinkView(
                    header: 'Admin',
                    onPressed: () {
                      context.go(".${Uri(path: AdminView.routeName)}");
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LinkView extends StatelessWidget {
  const LinkView({
    super.key,
    required this.header,
    required this.onPressed,
  });

  final String header;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: Constants.largeHeaderTextStyle,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: ElevatedButton(
                  style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                  onPressed: onPressed,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.double_arrow,
                        color: Colors.white,
                        size: 100,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Link folgen',
                        style: TextStyle(
                          fontSize: 44,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.double_arrow,
                        color: Colors.white,
                        size: 100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleAndResultsLinkView extends StatelessWidget {
  const ScheduleAndResultsLinkView({
    super.key,
    required this.ageGroup,
  });

  final AgeGroup ageGroup;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 495,
      child: Card(
        color: Colors.blue,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                ageGroup.name,
                style: Constants.standardTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.go(
                                ".${Uri(
                                  path: ScheduleView.routeName,
                                  queryParameters: {
                                    ScheduleView.ageGroupQueryParam:
                                        ageGroup.name
                                  },
                                )}",
                              );
                            },
                            child: const Text(
                              'Spielübersicht',
                              style: Constants.standardTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.go(
                                ".${Uri(
                                  path: ResultsView.routeName,
                                  queryParameters: {
                                    ResultsView.ageGroupQueryParam:
                                        ageGroup.name
                                  },
                                )}",
                              );
                            },
                            child: const Text(
                              'Ergebnisse',
                              style: Constants.standardTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        context.go(
                          ".${Uri(
                            path: AgeGroupView.routeName,
                            queryParameters: {
                              AgeGroupView.ageGroupQueryParam: ageGroup.name
                            },
                          )}",
                        );
                      },
                      child: const Text(
                        'Spielplan & Ergebnisse',
                        style: Constants.standardTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
