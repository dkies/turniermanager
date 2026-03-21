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

  testWidgets('ScheduleView app bar shows age group and round name', (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleView(testAgeGroupName),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(testAgeGroupName), findsWidgets);
    expect(find.textContaining('Runde 1'), findsWidgets);
    expect(find.textContaining('Liga A'), findsWidgets);
  });

  testWidgets('ScheduleView shows error when age group is unknown', (tester) async {
    await resetAndRegisterTestDi(
      gameManager: FakeGameManager(ageGroups: []),
    );
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleView('Unknown'),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('nicht vorhanden'), findsOneWidget);
  });
}
