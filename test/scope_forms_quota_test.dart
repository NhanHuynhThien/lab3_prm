import 'package:flutter/material.dart';
import 'package:token_ledger/widgets/action_buttons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger.dart';
import 'package:token_ledger/screens/analytics_screen.dart';
import 'package:token_ledger/screens/history_screen.dart';
import 'package:token_ledger/screens/quota_form_screen.dart';
import 'package:token_ledger/services/usage_calculator.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/widgets/charts.dart';

import 'support/scope_forms_harness.dart';

void main() {
  late ScopeFormsHarness h;

  setUp(() async {
    h = ScopeFormsHarness();
    await h.init();
  });

  tearDown(() => h.container.dispose());

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'second quota window source/note survive failed save without replacing week at ${width.toInt()}',
      (tester) async {
        await h.open(
          tester,
          QuotaFormScreen(account: h.repo.data!.account('a')!, newWindow: true),
          width,
        );
        await tester.enterText(
          find.byKey(const ValueKey('quota-percent')),
          '0',
        );
        final source = find.byKey(const ValueKey('quota-source'));
        await h.reveal(tester, source);
        await tester.enterText(source, 'Trang usage đã quan sát');
        final note = find.byKey(const ValueKey('quota-note'));
        await h.reveal(tester, note);
        await tester.enterText(note, 'Giữ độc lập với tuần');
        h.repo.failWrites = true;
        await tester.tap(find.text('Lưu hạn mức nhập tay'));
        await tester.pumpAndSettle();
        expect(h.repo.data!.account('a')!.quotaWindows.length, 1);
        expect(
          tester.widget<TextFormField>(note).controller!.text,
          'Giữ độc lập với tuần',
        );
        h.repo.failWrites = false;
        await tester.tap(find.text('Lưu hạn mức nhập tay'));
        await tester.pumpAndSettle();
        final windows = h.repo.data!.account('a')!.quotaWindows;
        expect(windows.length, 2);
        expect(windows.first.usedPercent, 40);
        expect(windows.last.usedPercent, 0);
        expect(windows.last.source, DataSource.manual);
        expect(windows.last.sourceLabel, 'Trang usage đã quan sát');
        expect(windows.last.note, 'Giữ độc lập với tuần');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'provider history groups days in selected timezone; zone save failure preserves draft and search',
    (tester) async {
      h.repo.data = h.repo.data!.copyWith(
        sessions: [
          UsageSession(
            id: 'x',
            accountId: 'a',
            title: 'Công việc tối',
            purpose: Purpose.code,
            occurredAt: DateTime.utc(2026, 10, 20, 17, 30),
          ),
          UsageSession(
            id: 'y',
            accountId: 'a',
            title: 'Công việc chiều',
            purpose: Purpose.code,
            occurredAt: DateTime.utc(2026, 10, 20, 16),
          ),
          UsageSession(
            id: 'z',
            accountId: 'b',
            title: 'Không thuộc provider',
            purpose: Purpose.code,
            occurredAt: h.now,
          ),
        ],
      );
      h.container.invalidate(ledgerProvider);
      await h.container.read(ledgerProvider.future);
      await h.open(tester, const HistoryScreen(provider: 'OpenAI'), 412);
      await tester.enterText(find.byType(TextField).first, 'Công việc');
      await tester.pumpAndSettle();
      await h.reveal(tester, find.text('21/10/2026'));
      expect(find.text('21/10/2026'), findsOneWidget);
      await h.reveal(tester, find.text('20/10/2026'));
      expect(find.text('20/10/2026'), findsOneWidget);
      expect(find.text('Không thuộc provider'), findsNothing);
      await h.reveal(tester, find.byTooltip('Múi giờ báo cáo'), step: -240);
      await tester.tap(find.byTooltip('Múi giờ báo cáo'));
      await tester.pumpAndSettle();
      final zone = find.byKey(const ValueKey('reporting-timezone'));
      await tester.enterText(zone, 'Made/Up');
      await tester.tap(find.text('Lưu múi giờ'));
      await tester.pumpAndSettle();
      expect(find.text('Múi giờ IANA không hợp lệ.'), findsOneWidget);
      await tester.enterText(zone, 'UTC');
      h.repo.failWrites = true;
      await tester.tap(find.text('Lưu múi giờ'));
      await tester.pumpAndSettle();
      expect(h.repo.data!.reportingTimezone, 'Asia/Ho_Chi_Minh');
      expect(tester.widget<TextFormField>(zone).controller!.text, 'UTC');
      h.repo.failWrites = false;
      await tester.tap(find.text('Lưu múi giờ'));
      await tester.pumpAndSettle();
      expect(h.repo.data!.reportingTimezone, 'UTC');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Công việc',
      );
      await h.reveal(tester, find.text('20/10/2026'));
      expect(find.text('20/10/2026'), findsOneWidget);
      expect(find.text('21/10/2026'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown cost defaults analytics to count; provider tap opens exact history',
    (tester) async {
      h.repo.data = h.repo.data!.copyWith(
        sessions: [
          UsageSession(
            id: 'x',
            accountId: 'a',
            title: 'Chưa biết tiền',
            purpose: Purpose.code,
            occurredAt: h.now,
          ),
        ],
      );
      h.container.invalidate(ledgerProvider);
      await h.container.read(ledgerProvider.future);
      await h.open(tester, const Scaffold(body: AnalyticsScreen()), 412);
      expect(
        tester
            .widget<SelectionButton>(
              find.widgetWithText(SelectionButton, UsageMetric.sessions.label),
            )
            .selected,
        isTrue,
      );
      await h.reveal(tester, find.text('OpenAI'));
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HistoryScreen>(find.byType(HistoryScreen)).provider,
        'OpenAI',
      );
      await h.reveal(tester, find.text('Chưa biết tiền'));
      expect(find.text('Chưa biết tiền'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'donut sector opens same purpose filter as its accessible legend',
    (tester) async {
      h.repo.data = h.repo.data!.copyWith(
        sessions: [
          UsageSession(
            id: 'x',
            accountId: 'a',
            title: 'Lập trình',
            purpose: Purpose.code,
            occurredAt: h.now,
          ),
          UsageSession(
            id: 'y',
            accountId: 'a',
            title: 'Review',
            purpose: Purpose.review,
            occurredAt: h.now,
          ),
        ],
      );
      h.container.invalidate(ledgerProvider);
      await h.container.read(ledgerProvider.future);
      await h.open(tester, const Scaffold(body: AnalyticsScreen()), 412);
      await h.reveal(tester, find.byType(PurposeRing));
      final start = tester.getTopLeft(find.byType(PurposeRing));
      await tester.tapAt(start + const Offset(162, 86));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HistoryScreen>(find.byType(HistoryScreen)).purpose,
        Purpose.code,
      );
      await h.reveal(tester, find.text('Lập trình').last);
      expect(find.text('Review'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
