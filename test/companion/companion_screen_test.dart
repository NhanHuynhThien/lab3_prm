import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/companion/screens/companion_screen.dart';
import 'package:token_ledger/companion/viewmodels/companion_controller.dart';
import 'package:token_ledger/theme/app_theme.dart';

import 'companion_controller_test.dart' show FakeHost;

void main() {
  for (final size in const [Size(840, 820), Size(620, 690)]) {
    testWidgets('signed-out window renders without overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companionDependenciesProvider.overrideWithValue(FakeHost().deps()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const CompanionScreen(),
          ),
        ),
      );
      expect(find.text('Chưa kết nối'), findsOneWidget);
      expect(find.text('Đăng nhập Google'), findsOneWidget);
      expect(find.text('Nguồn trên máy này'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull, reason: 'consent required first');
      await tester.tap(find.textContaining('Tôi đồng ý'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  }
}
