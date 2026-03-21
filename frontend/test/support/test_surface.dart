import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Default [WidgetTester] surface is small; these views assume a kiosk/large layout.
void bindLargeTestSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
