import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_manager/src/manager/settings_manager.dart';
import 'package:tournament_manager/src/service/sound_player_service.dart';
import 'package:tournament_manager/src/views/referee_view.dart';
import 'package:watch_it/watch_it.dart';

import '../support/fake_game_manager.dart';
import '../support/fake_settings_manager.dart';
import '../support/fake_sound_player_service.dart';
import '../support/sample_data.dart';
import '../support/test_di.dart';
import '../support/test_surface.dart';

/// Deeper flow tests for [RefereeView]: commands, dialogs, snackbars, sounds.
/// (Runs on the VM test runner — no device build.)
///
/// Run: `flutter test test/integration/referee_flows_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGameManager gameManager;
  late FakeSoundPlayerService soundPlayer;

  /// [pumpAndSettle] can hang while [StopWatchTimer] ticks after "Spiel starten".
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpReferee(WidgetTester tester) async {
    bindLargeTestSurface(tester);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => RefereeView(),
            ),
          ],
        ),
      ),
    );
    await settle(tester);
  }

  /// Stops [StopWatchTimer] so the test binding does not report pending timers.
  Future<void> stopCountdownIfPossible(WidgetTester tester) async {
    final reset = find.byTooltip('Spiel zurücksetzen');
    if (reset.evaluate().isEmpty) return;
    await tester.tap(reset);
    await settle(tester);
  }

  setUp(() async {
    gameManager = FakeGameManager(
      ageGroups: [sampleAgeGroup()],
      gameGroups: [sampleGameGroup()],
    );
    soundPlayer = FakeSoundPlayerService();
    await resetAndRegisterTestDi(
      gameManager: gameManager,
      // Enables reset button so we can stop timers after flows that start play.
      settingsManager: FakeSettingsManager(canPause: true),
      soundPlayer: soundPlayer,
    );
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  group('Start / horn', () {
    testWidgets('first start plays horn', (tester) async {
      await pumpReferee(tester);

      await tester.tap(find.byType(Switch));
      await settle(tester);
      await tester.tap(find.byTooltip('Spiel starten'));
      await settle(tester);

      expect(soundPlayer.playSoundLog, contains(Sounds.horn));
      await stopCountdownIfPossible(tester);
    });
  });

  group('End games', () {
    testWidgets('end without start shows error snackbar', (tester) async {
      await pumpReferee(tester);

      await tester.tap(find.byTooltip('Spiel beenden'));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Spiele wurden nicht gestartet'),
        findsOneWidget,
      );
    });

    testWidgets('after start, end shows confirmation when time not elapsed',
        (tester) async {
      await pumpReferee(tester);

      await tester.tap(find.byType(Switch));
      await settle(tester);

      await tester.tap(find.byTooltip('Spiel starten'));
      await settle(tester);

      await tester.tap(find.byTooltip('Spiel beenden'));
      await settle(tester);

      expect(find.text('Spiele beenden'), findsOneWidget);
      expect(
        find.textContaining('Spielzeit ist noch nicht abgelaufen'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Abbrechen'),
        ),
      );
      await settle(tester);
      expect(find.text('Spiele beenden'), findsNothing);
      await stopCountdownIfPossible(tester);
    });

    testWidgets('confirm end calls command and refreshes round on success',
        (tester) async {
      gameManager.endCurrentGamesReturns = true;
      await pumpReferee(tester);

      await tester.tap(find.byType(Switch));
      await settle(tester);

      await tester.tap(find.byTooltip('Spiel starten'));
      await settle(tester);

      expect(gameManager.endCurrentGamesInvocations, 0);
      expect(gameManager.getCurrentRoundInvocations, 0);

      await tester.tap(find.byTooltip('Spiel beenden'));
      await settle(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('OK'),
        ),
      );
      await settle(tester);

      expect(gameManager.endCurrentGamesInvocations, 1);
      expect(gameManager.getCurrentRoundInvocations, 1);
      await stopCountdownIfPossible(tester);
    });

    testWidgets('end failure shows snackbar', (tester) async {
      gameManager.endCurrentGamesReturns = false;
      await pumpReferee(tester);

      await tester.tap(find.byType(Switch));
      await settle(tester);
      await tester.tap(find.byTooltip('Spiel starten'));
      await settle(tester);
      await tester.tap(find.byTooltip('Spiel beenden'));
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('OK'),
        ),
      );
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Spiele konnten nicht beendet werden'),
        findsOneWidget,
      );
      await stopCountdownIfPossible(tester);
    });
  });

  group('Next round', () {
    testWidgets('success runs start command and refreshes round', (tester) async {
      gameManager.startNextRoundReturns = true;
      await pumpReferee(tester);

      expect(gameManager.startNextRoundInvocations, 0);

      await tester.tap(find.textContaining('Nächste Runde'));
      await settle(tester);

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

    testWidgets('failure shows error after dialog', (tester) async {
      gameManager.startNextRoundReturns = false;
      await pumpReferee(tester);

      await tester.tap(find.textContaining('Nächste Runde'));
      await settle(tester);
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

  group('Break insert / delete', () {
    testWidgets('insert break success refreshes round', (tester) async {
      gameManager.addBreakReturns = true;
      await pumpReferee(tester);

      await tester.tap(find.textContaining('Pause einfügen'));
      await settle(tester);

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
      await pumpReferee(tester);

      await tester.tap(find.textContaining('Pause einfügen'));
      await settle(tester);
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

    testWidgets('delete break success refreshes round', (tester) async {
      gameManager.deleteBreakReturns = true;
      // Do not call resetAndRegisterTestDi again here: setUp already registered
      // this [gameManager]. A second di.reset() reuses the same instance and can
      // break watch_it subscriptions and hang tests.
      gameManager.setGameGroups([sampleGameGroupWithBreak()]);

      await pumpReferee(tester);

      await tester.tap(find.byTooltip('Pause entfernen'));
      await settle(tester);

      expect(gameManager.deleteBreakInvocations, 1);
      expect(gameManager.getCurrentRoundInvocations, 1);
    });

    testWidgets('delete break failure shows snackbar', (tester) async {
      gameManager.deleteBreakReturns = false;
      gameManager.setGameGroups([sampleGameGroupWithBreak()]);

      await pumpReferee(tester);

      await tester.tap(find.byTooltip('Pause entfernen'));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Pause konnte nicht entfernt werden'),
        findsOneWidget,
      );
    });
  });

  group('Unmute barrier', () {
    testWidgets('tapping modal barrier dismisses overlay', (tester) async {
      // Do not call resetAndRegisterTestDi here: it disposes the registered
      // [SoundPlayerService] (closing the fake's stream) while we keep the
      // same [soundPlayer] instance from setUp.
      final settings = di<SettingsManager>() as FakeSettingsManager;
      settings.currentlyRunningGames = sampleGameGroupStartTime();
      settings.notifyListeners();

      await pumpReferee(tester);

      Finder largeUnmuteIcon() => find.byWidgetPredicate(
            (w) => w is Icon && w.icon == Icons.volume_up && w.size == 100,
          );

      expect(largeUnmuteIcon(), findsOneWidget);

      // Center is covered by the large IconButton; tap the corner to hit the barrier.
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);

      expect(largeUnmuteIcon(), findsNothing);
      await stopCountdownIfPossible(tester);
    });
  });
}
