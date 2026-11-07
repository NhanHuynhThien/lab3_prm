import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/dashboard_screen.dart';
import 'package:token_ledger/screens/purpose_screen.dart';
import 'package:token_ledger/screens/shell_screen.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/widgets/charts.dart';
import 'package:token_ledger/widgets/common.dart';

import 'support/accessibility_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AccessibilityHarness h;

  setUpAll(() async {
    await AccessibilityHarness.loadFonts();
  });

  setUp(() {
    h = AccessibilityHarness();
  });

  test('B11 Lab2 text/control contrast pairs meet explicit thresholds', () {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    for (final bg in [
      AppColors.surface,
      AppColors.background,
      AppColors.soft,
      AppColors.neutral,
    ]) {
      for (final fg in [
        AppColors.text,
        AppColors.muted,
        AppColors.primary,
        AppColors.danger,
      ]) {
        expect(ratio(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg / $bg');
      }
    }
    expect(ratio(Colors.white, AppColors.primary), greaterThanOrEqualTo(4.5));
    expect(ratio(AppColors.border, AppColors.surface), greaterThanOrEqualTo(3));
  });

  testWidgets(
    'B11 action row supports semantic button/selection, Tab and Enter',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ActionSurface(
              selected: true,
              onTap: () => taps++,
              child: const Text('Mở lịch sử'),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ActionSurface)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(find.byType(ActionSurface)),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasFocusAction: true,
          hasTapAction: true,
          label: 'Mở lịch sử',
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.foregroundDecoration is BoxDecoration &&
              (w.foregroundDecoration! as BoxDecoration).border != null,
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'B11 chart dates/units and progress have one final semantic value',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 328,
                  child: UsageBarChart(
                    values: const [0, 1000000, 0, 0, 0, 0, 2000000],
                    now: DateTime(2026, 1, 1),
                  ),
                ),
                const AnimatedProgress(value: .25),
                const AnimatedMoney(micros: 12340000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Chi phí nhập tay, USD.*26/12/2025: \$0.00.*1/1/2026: \$2.00',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byType(AnimatedProgress)),
        matchesSemantics(value: '25%'),
      );
      expect(find.bySemanticsLabel(r'$12.34'), findsOneWidget);
      semantics.dispose();
    },
  );

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'B11 labels, contrast and touch targets on purpose and shell $width',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final repo = StateRepository();
        final container = h.owner(repo);
        await container.read(ledgerProvider.future);
        try {
          await h.open(
            tester,
            container,
            const PurposeScreen(selected: Purpose.code),
            width: width,
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await h.open(tester, container, const ShellScreen(), width: width);
          await tester.pumpAndSettle();
          for (final tab in ['Tổng quan', 'Đánh giá', 'Phân tích', 'Cá nhân']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
        } finally {
          semantics.dispose();
          await h.close(tester, container);
        }
      },
    );
  }

  testWidgets(
    'B11 unknown/stale quota and missing budget never speak measured zero percent',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final unknown = AIAccount(
          id: 'unknown',
          alias: 'Chưa biết',
          provider: 'OpenAI',
          product: 'Codex',
          billingMode: BillingMode.api,
          plan: '',
          createdAt: h.now,
        );
        final stale = unknown.copyWith(
          quota: QuotaSnapshot(
            window: '5 giờ',
            usedPercent: 70,
            observedAt: h.now.subtract(const Duration(hours: 6)),
            resetAt: h.now.subtract(const Duration(hours: 1)),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Column(
                children: [
                  QuotaRow(account: unknown, now: h.now),
                  QuotaRow(account: stale, now: h.now),
                  const AnimatedProgress(
                    value: 0,
                    semanticValue: 'Chưa đặt ngân sách',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final nodes = find.byType(AnimatedProgress);
        expect(
          tester.getSemantics(nodes.at(0)).getSemanticsData().value,
          'Chưa có dữ liệu quota',
        );
        expect(
          tester.getSemantics(nodes.at(1)).getSemanticsData().value,
          'Quota đã quá reset; cần cập nhật',
        );
        expect(
          tester.getSemantics(nodes.at(2)).getSemanticsData().value,
          'Chưa đặt ngân sách',
        );
      } finally {
        semantics.dispose();
      }
    },
  );
}
