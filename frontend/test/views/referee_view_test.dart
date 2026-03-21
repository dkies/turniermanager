import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_manager/src/manager/settings_manager.dart';
import 'package:tournament_manager/src/views/referee_view.dart';
import 'package:watch_it/watch_it.dart';

import '../support/fake_game_manager.dart';
import '../support/fake_settings_manager.dart';
import '../support/sample_data.dart';
import '../support/test_di.dart';
import '../support/test_surface.dart';

GoRouter _routerRefereeOnly() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => RefereeView(),
        ),
      ],
    );

/// Stack: home screen then push /referee so back works.
GoRouter _routerWithPushToReferee() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/referee'),
                child: const Text('OPEN_REFEREE'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/referee',
          builder: (context, state) => RefereeView(),
        ),
      ],
    );

Future<void> _pumpReferee(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  bindLargeTestSurface(tester);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetAndRegisterTestDi(
      gameManager: FakeGameManager(
        ageGroups: [sampleAgeGroup()],
        gameGroups: [sampleGameGroup()],
      ),
    );
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  group('RefereeView shell', () {
    testWidgets('shows app bar title and primary actions', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      expect(find.textContaining('Spielübersicht'), findsOneWidget);
      expect(find.textContaining('Pause einfügen'), findsOneWidget);
      expect(find.textContaining('Sounds'), findsOneWidget);
      expect(find.textContaining('Nächste Runde'), findsOneWidget);
      expect(find.byTooltip('Einstellungen (nächste Runde)'), findsOneWidget);
      expect(find.byTooltip('Zurück'), findsOneWidget);
    });

    testWidgets('bottom bar shows reload warning', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      expect(
        find.textContaining('Seite neu laden vermeiden'),
        findsOneWidget,
      );
    });

    testWidgets('game card shows league, teams, and time header', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      expect(find.textContaining('Liga A'), findsWidgets);
      expect(find.text('A'), findsWidgets);
      expect(find.text('B'), findsWidgets);
      expect(find.textContaining('Spielzeit:'), findsOneWidget);
    });
  });

  group('Dialogs', () {
    testWidgets('sound preview lists all sounds and closes', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      await tester.tap(find.textContaining('Sounds'));
      await tester.pumpAndSettle();

      expect(find.text('Verfügbare Sounds'), findsOneWidget);
      expect(find.text('Gong'), findsOneWidget);
      expect(find.text('Horn'), findsOneWidget);
      expect(find.text('Schlusslied'), findsOneWidget);

      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
      expect(find.text('Verfügbare Sounds'), findsNothing);
    });

    testWidgets('settings dialog shows round options', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      await tester.tap(find.byTooltip('Einstellungen (nächste Runde)'));
      await tester.pumpAndSettle();

      expect(find.text('Einstellungen (nächste Runde)'), findsOneWidget);
      expect(find.text('Max. Anzahl Teams / Runde'), findsOneWidget);
      expect(find.textContaining('Pausenzeit'), findsOneWidget);
      expect(find.textContaining('Spielzeit / Spiel'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('OK'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Einstellungen (nächste Runde)'), findsNothing);
    });

    testWidgets('insert pause dialog opens and cancels', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      await tester.tap(find.text('Pause einfügen').first);
      await tester.pumpAndSettle();

      expect(find.text('Pause einfügen'), findsWidgets);
      expect(find.text('Global (alle Altersgruppen)'), findsOneWidget);
      expect(find.text('Einfügen'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Abbrechen'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Global (alle Altersgruppen)'), findsNothing);
    });

    testWidgets('next round dialog shows warning and cancels', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      await tester.tap(find.textContaining('Nächste Runde'));
      await tester.pumpAndSettle();

      expect(find.text('Wechsel zur nächsten Runde'), findsOneWidget);
      expect(
        find.textContaining('kann nicht rückgängig gemacht werden'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Abbrechen'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wechsel zur nächsten Runde'), findsNothing);
    });
  });

  group('Settings: pause switch', () {
    testWidgets('toggling switch updates canPause via command', (tester) async {
      await _pumpReferee(tester, router: _routerRefereeOnly());

      final sm = di<SettingsManager>() as FakeSettingsManager;
      expect(sm.canPause, false);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(sm.canPause, true);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(sm.canPause, false);
    });
  });

  group('Navigation', () {
    testWidgets('back button pops to previous route', (tester) async {
      await resetAndRegisterTestDi(
        gameManager: FakeGameManager(
          ageGroups: [sampleAgeGroup()],
          gameGroups: [sampleGameGroup()],
        ),
      );
      bindLargeTestSurface(tester);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _routerWithPushToReferee(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN_REFEREE'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Spielübersicht'), findsOneWidget);

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();

      expect(find.text('OPEN_REFEREE'), findsOneWidget);
    });
  });

  group('Game groups variants', () {
    testWidgets('empty game groups shows empty list', (tester) async {
      await resetAndRegisterTestDi(
        gameManager: FakeGameManager(
          ageGroups: [sampleAgeGroup()],
          gameGroups: [],
        ),
      );
      await _pumpReferee(tester, router: _routerRefereeOnly());

      expect(find.textContaining('Liga A'), findsNothing);
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('break-only group shows Pause header and PAUSE rows', (tester) async {
      await resetAndRegisterTestDi(
        gameManager: FakeGameManager(
          ageGroups: [sampleAgeGroup()],
          gameGroups: [sampleBreakOnlyGameGroup()],
        ),
      );
      await _pumpReferee(tester, router: _routerRefereeOnly());

      expect(find.textContaining('Pause:'), findsWidgets);
      expect(find.text('PAUSE'), findsWidgets);
      expect(find.textContaining('Spielzeit:'), findsNothing);
    });
  });

  group('Unmute barrier', () {
    Finder largeUnmuteIconFinder() {
      return find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.volume_up && w.size == 100,
      );
    }

    Finder largeUnmuteIconButtonFinder() {
      return find.byWidgetPredicate(
        (w) {
          if (w is! IconButton) return false;
          final icon = w.icon;
          return icon is Icon &&
              icon.icon == Icons.volume_up &&
              icon.size == 100;
        },
      );
    }

    testWidgets('shows large unmute icon when currentlyRunningGames is set',
        (tester) async {
      await resetAndRegisterTestDi(
        gameManager: FakeGameManager(
          ageGroups: [sampleAgeGroup()],
          gameGroups: [sampleGameGroup()],
        ),
        settingsManager: FakeSettingsManager(
          currentlyRunningGames: sampleGameGroupStartTime(),
        ),
      );
      await _pumpReferee(tester, router: _routerRefereeOnly());

      expect(largeUnmuteIconFinder(), findsOneWidget);
      expect(largeUnmuteIconButtonFinder(), findsOneWidget);
    });

    testWidgets('dismisses barrier when large unmute IconButton tapped',
        (tester) async {
      await resetAndRegisterTestDi(
        gameManager: FakeGameManager(
          ageGroups: [sampleAgeGroup()],
          gameGroups: [sampleGameGroup()],
        ),
        settingsManager: FakeSettingsManager(
          currentlyRunningGames: sampleGameGroupStartTime(),
        ),
      );
      await _pumpReferee(tester, router: _routerRefereeOnly());

      expect(largeUnmuteIconButtonFinder(), findsOneWidget);

      await tester.tap(largeUnmuteIconButtonFinder());
      await tester.pumpAndSettle();

      expect(largeUnmuteIconFinder(), findsNothing);
    });
  });
}
