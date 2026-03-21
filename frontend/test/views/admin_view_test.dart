import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_manager/src/views/admin_view.dart';

import '../support/fake_game_manager.dart';
import '../support/sample_data.dart';
import '../support/test_di.dart';
import '../support/test_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGameManager gameManager;

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUp(() async {
    gameManager = FakeGameManager(
      ageGroups: [sampleAgeGroup()],
      games: [sampleExtendedGame()],
      pitches: samplePitches(),
    );
    await resetAndRegisterTestDi(gameManager: gameManager);
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  group('layout & smoke', () {
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

    testWidgets('AdminView data table lists game row with team names',
        (tester) async {
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

    testWidgets('AdminView still shows sections when there are no games',
        (tester) async {
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
  });

  group('navigation', () {
    testWidgets('back button pops route', (tester) async {
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminView(),
                      ),
                    );
                  },
                  child: const Text('OPEN_ADMIN'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN_ADMIN'));
      await tester.pumpAndSettle();
      expect(find.text('Admin'), findsOneWidget);

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();
      expect(find.text('OPEN_ADMIN'), findsOneWidget);
    });
  });

  group('save game scores', () {
    testWidgets('invalid format shows snackbar', (tester) async {
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.tap(find.byIcon(Icons.save));
      await settle(tester);

      expect(
        find.textContaining('Falsches Zahlenformat'),
        findsOneWidget,
      );
      expect(gameManager.saveGameInvocations, 0);
    });

    testWidgets('server error shows snackbar', (tester) async {
      gameManager.saveGameReturns = false;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await settle(tester);

      expect(find.textContaining('Server-Fehler'), findsOneWidget);
      expect(gameManager.saveGameInvocations, 1);
    });

    testWidgets('success saves and passes tuple to saveGameCommand', (tester) async {
      gameManager.saveGameReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await settle(tester);

      expect(gameManager.saveGameInvocations, 1);
      expect(gameManager.lastSaveGameNumber, 1);
      expect(gameManager.lastSaveTeamAScore, 2);
      expect(gameManager.lastSaveTeamBScore, 1);
      expect(find.textContaining('Server-Fehler'), findsNothing);
    });

    testWidgets('after save, editing scores allows saving again', (tester) async {
      gameManager.saveGameReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await settle(tester);
      expect(gameManager.saveGameInvocations, 1);

      await tester.enterText(find.byType(TextField).first, '9');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.save));
      await settle(tester);

      expect(gameManager.saveGameInvocations, 2);
      expect(gameManager.lastSaveTeamAScore, 9);
      expect(gameManager.lastSaveTeamBScore, 1);
    });
  });

  group('print pitches', () {
    testWidgets('single pitch failure shows snackbar', (tester) async {
      gameManager.printPitchReturns = false;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).at(1));
      await settle(tester);

      expect(
        find.textContaining('Schiedrichterzettel für Platz'),
        findsOneWidget,
      );
      expect(gameManager.printPitchInvocations, 1);
      expect(gameManager.lastPrintPitchId, 'pitch-1');
    });

    testWidgets('single pitch success does not show error snackbar',
        (tester) async {
      gameManager.printPitchReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).at(1));
      await settle(tester);

      expect(
        find.textContaining('Schiedrichterzettel für Platz'),
        findsNothing,
      );
      expect(gameManager.printPitchInvocations, 1);
    });

    testWidgets('print all pitches failure shows snackbar', (tester) async {
      gameManager.printAllPitchesReturns = false;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).first);
      await settle(tester);

      expect(
        find.textContaining('Ein oder mehrere Schiedrichterzettel'),
        findsOneWidget,
      );
      expect(gameManager.printAllPitchesInvocations, 1);
    });

    testWidgets('print all pitches success', (tester) async {
      gameManager.printAllPitchesReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).first);
      await settle(tester);

      expect(
        find.textContaining('Ein oder mehrere Schiedrichterzettel'),
        findsNothing,
      );
      expect(gameManager.printAllPitchesInvocations, 1);
    });
  });

  group('print results', () {
    testWidgets('single age group failure shows snackbar', (tester) async {
      gameManager.printResultsReturns = false;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).at(3));
      await settle(tester);

      expect(
        find.textContaining('Turnierergebnisse für Altersgruppe'),
        findsOneWidget,
      );
      expect(gameManager.printResultsInvocations, 1);
      expect(gameManager.lastPrintResultsAgeGroupId, testAgeGroupId);
    });

    testWidgets('single age group success', (tester) async {
      gameManager.printResultsReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).at(3));
      await settle(tester);

      expect(
        find.textContaining('Turnierergebnisse für Altersgruppe'),
        findsNothing,
      );
      expect(gameManager.printResultsInvocations, 1);
    });

    testWidgets('print all results failure shows snackbar', (tester) async {
      gameManager.printAllResultsReturns = false;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).at(2));
      await settle(tester);

      expect(
        find.textContaining('Ein oder mehrere Turnierergebnisse'),
        findsOneWidget,
      );
      expect(gameManager.printAllResultsInvocations, 1);
    });

    testWidgets('print all results success', (tester) async {
      gameManager.printAllResultsReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.print).at(2));
      await settle(tester);

      expect(
        find.textContaining('Ein oder mehrere Turnierergebnisse'),
        findsNothing,
      );
      expect(gameManager.printAllResultsInvocations, 1);
    });
  });
}
