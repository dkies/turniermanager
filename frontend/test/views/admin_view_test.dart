import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_manager/src/views/admin_view.dart';

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
        games: [sampleExtendedGame()],
        pitches: samplePitches(),
      ),
    );
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  testWidgets('AdminView shows headers and sections', (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget);
    expect(find.textContaining('Spielwertungen'), findsOneWidget);
    expect(find.textContaining('Schiedsrichterzettel'), findsOneWidget);
    expect(find.textContaining('Turnierergebnisse'), findsOneWidget);
    expect(find.textContaining('Platz 1'), findsWidgets);
  });

  testWidgets('AdminView data table lists game row with team names', (tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Team A'), findsWidgets);
    expect(find.textContaining('Team B'), findsWidgets);
    expect(find.byIcon(Icons.print), findsWidgets);
  });

  testWidgets('AdminView still shows sections when there are no games', (tester) async {
    await resetAndRegisterTestDi(
      gameManager: FakeGameManager(
        ageGroups: [sampleAgeGroup()],
        games: [],
        pitches: samplePitches(),
      ),
    );
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Spielwertungen'), findsOneWidget);
    expect(find.textContaining('Schiedsrichterzettel'), findsOneWidget);
  });
}
