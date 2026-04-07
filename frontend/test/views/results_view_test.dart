import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_manager/src/views/results_view.dart';

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
        results: sampleResults(),
      ),
    );
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  testWidgets('ResultsView shows title and team from results', (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultsView(testAgeGroupName),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ergebnisse'), findsOneWidget);
    expect(find.textContaining('Team Alpha'), findsWidgets);
  });

  testWidgets('ResultsView app bar shows round and league content', (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultsView(testAgeGroupName),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Runde 1'), findsWidgets);
    expect(find.textContaining('Liga A'), findsWidgets);
  });

  testWidgets('ResultsView shows error when age group is unknown', (tester) async {
    await resetAndRegisterTestDi(
      gameManager: FakeGameManager(ageGroups: []),
    );
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultsView('Unknown'),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('nicht vorhanden'), findsOneWidget);
  });
}
