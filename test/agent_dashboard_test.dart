import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/agent_dashboard.dart';
import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/viewmodels/ledger_viewmodel.dart';
import 'package:token_ledger/viewmodels/provider_sources_viewmodel.dart';
import 'package:token_ledger/widgets/agent_dashboard_panel.dart';

import 'support/auth_gate_harness.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);
  ProviderUsage row(
    String id, {
    String status = 'ready',
    double used = 20,
    bool expired = false,
  }) => ProviderUsage(
    id: id,
    status: status,
    source: 'test',
    coverage: 'test',
    observedAt: status == 'setup' ? null : now,
    totalTokens: id == 'codex' ? 1000000 : null,
    windows: status == 'setup'
        ? []
        : [
            ProviderQuota(
              '5 giờ',
              used,
              now.add(Duration(hours: expired ? -1 : 2)),
            ),
          ],
  );
  final sources = [
    row('codex'),
    row('antigravity', used: 90),
    row('claude', status: 'setup'),
    row('google', expired: true),
  ];
  setUpAll(AuthGateHarness.loadFonts);
  test('dashboard lists observed agents and counts attention without summing quotas/tokens', () {
    final value = AgentDashboard(sources, now);
    expect(value.connected.length, 3);
    expect(value.quotaCount, 2);
    expect(value.attention, 2);
    expect(value.limiting(sources.last), isNull);
    expect(value.connected.where(value.needsAttention).length, 2);
  });
  test(
    'quota level warns from the attention band and alerts at the user limit',
    () {
      const warn = AgentDashboard.warnUsedPercent * 1.0;
      expect(AgentDashboard.level(warn - 1, null), QuotaLevel.normal);
      expect(AgentDashboard.level(warn, null), QuotaLevel.warning);
      expect(AgentDashboard.level(60, 50), QuotaLevel.alert);
      expect(AgentDashboard.level(40, 50), QuotaLevel.normal);
    },
  );
  for (final width in [360.0, 412.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'dashboard overview differs from account source picker $width text$scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var opened = 0;
          final container = ProviderContainer(
            overrides: [
              providerSourcesProvider.overrideWithValue(sources),
              clockProvider.overrideWithValue(() => now),
            ],
          );
          try {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: buildAppTheme(),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: AgentDashboardPanel(onAnalytics: () => opened++),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('ChatGPT / Codex'), findsOneWidget);
            expect(find.byType(ChoiceChip), findsNothing);
            expect(find.text('Claude'), findsNothing);
            final action = find.byTooltip('Phân tích Antigravity');
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(opened, 1);
            expect(container.read(selectedSourceProvider), 'antigravity');
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox());
            container.dispose();
          }
        },
      );
    }
  }
}
