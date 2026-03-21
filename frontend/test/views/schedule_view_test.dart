import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_manager/src/views/schedule_view.dart';

import '../support/fake_game_manager.dart';
import '../support/sample_data.dart';
import '../support/test_di.dart';
import '../support/test_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetAndRegisterTestDi(
      gameManager: FakeGameManager(
        ageGroups: [sampleAgeGroup()],
        schedule: sampleMatchSchedule(),
      ),
    );
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  testWidgets('ScheduleView shows plan title and break line like grouped layout',
      (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleView(testAgeGroupName),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spielplan'), findsOneWidget);
    expect(find.textContaining('PAUSE auf'), findsOneWidget);
    expect(find.textContaining('Mittagspause'), findsOneWidget);
    expect(find.textContaining('Alpha'), findsWidgets);
  });
}
