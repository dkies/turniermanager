import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_manager/src/views/age_group_view.dart';

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
        results: sampleResults(),
      ),
    );
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  testWidgets('AgeGroupView shows combined header and schedule/results content',
      (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: AgeGroupView(ageGroupName: testAgeGroupName),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Spielplan & Ergebnisse'), findsOneWidget);
    expect(find.textContaining('Team Alpha'), findsWidgets);
  });

  testWidgets('AgeGroupView schedule area shows pause line for breaks', (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: AgeGroupView(ageGroupName: testAgeGroupName),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('PAUSE auf'), findsWidgets);
    expect(find.textContaining('Mittagspause'), findsWidgets);
  });

  testWidgets('AgeGroupView shows error when age group is unknown', (tester) async {
    await resetAndRegisterTestDi(
      gameManager: FakeGameManager(ageGroups: []),
    );
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: AgeGroupView(ageGroupName: 'Unknown'),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('nicht vorhanden'), findsOneWidget);
  });
}
