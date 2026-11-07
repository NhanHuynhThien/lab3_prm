import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/widgets/action_buttons.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('actions share their row at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ActionButtons(
                  children: [
                    FilledButton(
                      key: const ValueKey('primary'),
                      onPressed: () {},
                      child: const Text('Cập nhật ngay'),
                    ),
                    const OutlinedButton(
                      key: ValueKey('secondary'),
                      onPressed: null,
                      child: Text('Ngắt kết nối'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final primary = tester.getRect(find.byKey(const ValueKey('primary')));
      final secondary = tester.getRect(find.byKey(const ValueKey('secondary')));
      expect(primary.width, secondary.width);
      expect(primary.height, greaterThanOrEqualTo(52));
      expect(secondary.right, lessThanOrEqualTo(344));
      if (scale == 1) {
        expect(primary.height, secondary.height);
        expect(primary.top, secondary.top);
        expect(primary.right + 8, secondary.left);
      } else {
        expect(primary.width, 328);
        expect(primary.bottom + 8, secondary.top);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('filter surfaces fill equal cells and the final row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ActionButtons(
              children: [
                for (final label in ['Codex', 'Claude', 'Gemini web'])
                  SelectionButton(
                    label: label,
                    selected: label == 'Codex',
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    Rect surface(String label) =>
        tester.getRect(find.widgetWithText(OutlinedButton, label));
    expect(surface('Codex').width, 176);
    expect(surface('Claude').width, 176);
    expect(surface('Codex').height, surface('Claude').height);
    expect(surface('Gemini web').width, 360);
    expect(surface('Gemini web').top, surface('Codex').bottom + 8);
    expect(tester.takeException(), isNull);
  });
}
