import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:token_ledger/viewmodels/token_limit_viewmodel.dart';
import 'package:token_ledger/widgets/token_limit_dialog.dart';

void main() {
  testWidgets(
    'saving a limit closes the dialog without using a disposed controller',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TokenMeter(
                  limitKey: 'agent:codex',
                  tokens: 900,
                  caption: 'token',
                  footer: 'test',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Đặt giới hạn'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1000');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(container.read(tokenLimitsProvider)['agent:codex'], 1000);
      expect(find.text('/ 1k token'), findsOneWidget);
    },
  );
}
