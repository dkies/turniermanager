import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_manager/src/views/referee_view.dart';

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
        gameGroups: [sampleGameGroup()],
      ),
    );
  });

  tearDown(() async {
    await resetAndRegisterTestDi();
  });

  testWidgets('RefereeView shows overview and actions', (tester) async {
    bindLargeTestSurface(tester);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => RefereeView(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Spielübersicht'), findsOneWidget);
    expect(find.textContaining('Pause einfügen'), findsOneWidget);
  });
}
