import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/antigravity_analysis.dart';
import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/utils/formatters.dart';
import 'package:token_ledger/widgets/antigravity_analysis_panel.dart';

import 'support/auth_gate_harness.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);
  ProviderUsage source({bool stale = false}) => ProviderUsage(
    id: 'antigravity',
    status: 'ready',
    source: 'Official /usage',
    coverage: 'Quota only',
    observedAt: stale ? now.subtract(const Duration(hours: 1)) : now,
    windows: [
      ProviderQuota(
        'Gemini · weekly',
        20,
        now.add(const Duration(days: 3)),
        group: 'Gemini Models',
        window: 'weekly',
      ),
      ProviderQuota(
        'Gemini · 5h',
        92,
        now.add(const Duration(hours: 2)),
        group: 'Gemini Models',
        window: '5h',
      ),
      ProviderQuota(
        'Claude/GPT · weekly',
        40,
        now.add(const Duration(days: 3)),
        group: 'Claude and GPT models',
        window: 'weekly',
      ),
      ProviderQuota(
        'Claude/GPT · 5h',
        10,
        now.add(const Duration(hours: 2)),
        group: 'Claude and GPT models',
        window: '5h',
      ),
    ],
  );
  setUpAll(AuthGateHarness.loadFonts);
  test('each model group uses its own limiting window; never sums quota', () {
    final groups = antigravityGroups(source(), now);
    expect(groups.length, 2);
    expect(groups.first.title, 'Nhóm Gemini');
    expect(groups.first.remaining, 8);
    expect(groups.first.limiting!.windowLabel, '5 giờ');
    expect(groups.last.title, 'Nhóm Claude & GPT');
    expect(groups.last.remaining, 60);
    expect(groups.last.limiting!.windowLabel, '7 ngày');
    expect(source().totalTokens, isNull);
  });
  test('stale windows cannot produce a healthy assessment', () {
    final groups = antigravityGroups(source(stale: true), now);
    expect(groups.every((g) => g.remaining == null), isTrue);
    expect(groups.first.assessment, contains('Cần cập nhật'));
  });
  test('structured window metadata parses with backward compatibility', () {
    final json = {
      'label': 'Gemini · 5h',
      'usedPercent': 30,
      'resetsAt': now.toIso8601String(),
      'group': 'Gemini Models',
      'window': '5h',
    };
    expect(ProviderQuota.fromJson(json).windowLabel, '5 giờ');
    expect(
      ProviderQuota.fromJson(
        {...json}
          ..remove('group')
          ..remove('window'),
      ).displayLabel,
      'Gemini · 5h',
    );
    expect(
      () => ProviderQuota.fromJson({...json, 'group': 'x' * 101}),
      throwsFormatException,
    );
  });
  test(
    'usage detail retains micro USD instead of showing a nonzero cost as zero',
    () {
      expect(preciseMoney(1234), '\$0.001234');
      expect(preciseMoney(1), '\$0.000001');
      expect(preciseMoney(0), '\$0.00');
      expect(preciseMoney(null), 'Chưa biết');
      expect(preciseMoney(1200000), '\$1.20');
    },
  );
  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('all four windows fit $width text$scale', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: AntigravityAnalysisPanel(source: source(), now: now),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Nhóm Gemini'), findsOneWidget);
        expect(find.text('Nhóm Claude & GPT'), findsOneWidget);
        expect(find.text('5 giờ'), findsNWidgets(2));
        expect(find.text('7 ngày'), findsNWidgets(2));
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        for (double y = 0; y < scroll.maxScrollExtent; y += 300) {
          scroll.jumpTo(y);
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        scroll.jumpTo(scroll.maxScrollExtent);
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
