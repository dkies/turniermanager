import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_manager/src/serialization/game_status.dart';
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
      expect(find.textContaining('Pause einfügen'), findsOneWidget);
      expect(find.byTooltip('Einstellungen (nächste Runde)'), findsOneWidget);
      expect(find.textContaining('Nächste Runde'), findsOneWidget);
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

    testWidgets('back shows leave dialog when local changes are dirty',
        (tester) async {
      final game = sampleExtendedGame()..status = GameStatus.completedAndStated;
      await resetAndRegisterTestDi(
        gameManager: FakeGameManager(
          ageGroups: [sampleAgeGroup()],
          games: [game],
          pitches: samplePitches(),
        ),
      );

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

      await tester.enterText(find.byType(TextField).first, '9');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();

      expect(find.text('Ungespeicherte Änderungen'), findsOneWidget);
      expect(
        find.textContaining('Seite wirklich verlassen'),
        findsOneWidget,
      );

      await tester.tap(find.text('Bleiben'));
      await tester.pumpAndSettle();
      expect(find.text('Admin'), findsOneWidget);

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verlassen'));
      await tester.pumpAndSettle();
      expect(find.text('OPEN_ADMIN'), findsOneWidget);
    });
  });

  group('save game scores', () {
    testWidgets('save button is disabled for non-completable status',
        (tester) async {
      final game = sampleExtendedGame()..status = GameStatus.scheduled;
      final scheduledManager = FakeGameManager(
        ageGroups: [sampleAgeGroup()],
        games: [game],
        pitches: samplePitches(),
      );
      await resetAndRegisterTestDi(
        gameManager: scheduledManager,
      );

      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      final saveButtonFinder = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Icon &&
            (w.icon as Icon).icon == Icons.save,
      );
      final saveButton = tester.widget<IconButton>(saveButtonFinder);
      expect(saveButton.onPressed, isNull);

      await tester.tap(saveButtonFinder);
      await settle(tester);
      expect(scheduledManager.saveGameInvocations, 0);
    });

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
      expect(gameManager.games.single.status, GameStatus.completed);
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
      expect(gameManager.games.single.status, GameStatus.completedAndStated);
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

  group('round management actions', () {
    testWidgets('settings dialog opens and closes', (tester) async {
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Einstellungen (nächste Runde)'));
      await tester.pumpAndSettle();

      expect(find.text('Einstellungen (nächste Runde)'), findsOneWidget);
      expect(find.text('Max. Anzahl Teams / Runde'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('OK'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Einstellungen (nächste Runde)'), findsNothing);
    });

    testWidgets('insert break success refreshes round', (tester) async {
      gameManager.addBreakReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Pause einfügen'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Einfügen'),
        ),
      );
      await settle(tester);

      expect(gameManager.addBreakInvocations, 1);
      expect(gameManager.getCurrentRoundInvocations, 1);
    });

    testWidgets('insert break failure shows snackbar', (tester) async {
      gameManager.addBreakReturns = false;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Pause einfügen'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Einfügen'),
        ),
      );
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Pause konnte nicht eingefügt werden'),
        findsOneWidget,
      );
    });

    testWidgets('next round success starts next round and refreshes', (tester) async {
      gameManager.startNextRoundReturns = true;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Nächste Runde'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('OK'),
        ),
      );
      await settle(tester);

      expect(gameManager.startNextRoundInvocations, 1);
      expect(gameManager.getCurrentRoundInvocations, 1);
    });

    testWidgets('next round failure shows snackbar', (tester) async {
      gameManager.startNextRoundReturns = false;
      bindLargeTestSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Nächste Runde'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('OK'),
        ),
      );
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Nächste Runde konnte nicht gestartet werden'),
        findsOneWidget,
      );
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
