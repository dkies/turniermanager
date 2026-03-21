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
}
