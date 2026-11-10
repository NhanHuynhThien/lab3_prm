import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usage_calculator.dart';
import '../theme/app_theme.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../widgets/provider_analytics_panel.dart';
import '../widgets/provider_ledger_feedback.dart';
import 'provider_connections_screen.dart';
import '../utils/formatters.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/ledger_feedback.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import '../widgets/export_report_dialog.dart';
import '../widgets/gemini_analysis_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  UsageMetric? _selectedMetric;
  bool get _hasCost =>
      ref.read(filteredSessionsProvider).any((s) => s.costMicros != null);

  /// A cost pick falls back once the period has no costed session.
  UsageMetric get _metric => _selectedMetric == UsageMetric.cost && !_hasCost
      ? UsageCalculator.preferredMetric(ref.read(filteredSessionsProvider))
      : _selectedMetric ??
            UsageCalculator.preferredMetric(ref.read(filteredSessionsProvider));
  @override
  Widget build(BuildContext context) {
    final feedback = ledgerFeedback(ref.watch(ledgerProvider), 'Phân tích');
    final hasSources = ref.watch(hasObservedSourcesProvider);
    if (feedback != null) {
      return hasSources ? ProviderLedgerFeedback(feedback: feedback) : feedback;
    }
    // One ledger now (Companion rows and any manual history), so there is
    // no Agent / ledger switch: totals first, then each agent's live quota.
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        const PageHeading(
          'Phân tích sử dụng',
          'Chi tiết từng agent và gợi ý tối ưu từ Gemini.',
        ),
        ..._ledgerSections(context),
        if (hasSources) ...[
          const SizedBox(height: AppSpace.xl),
          const SectionTitle('Từng agent'),
          const ProviderAnalyticsPanel(),
        ],
      ],
    );
  }

  List<Widget> _ledgerSections(BuildContext context) {
    final projection = ref.watch(analyticsProjectionProvider(_metric));
    final summary = projection.summary;
    final shares = projection.shares;
    final total = projection.total;
    String format(int v) => switch (_metric) {
      UsageMetric.cost => preciseMoney(v),
      UsageMetric.tokens => compactTokens(v),
      UsageMetric.sessions => '$v',
    };
    return [
      const FilterBar(),
      const SizedBox(height: 16),
      // One row; cost only when some session in the period has a cost
      // (subscription CLI usage never does).
      SegmentedButton<UsageMetric>(
        expandedInsets: EdgeInsets.zero,
        showSelectedIcon: false,
        segments: [
          for (final metric in UsageMetric.values)
            if (metric != UsageMetric.cost || _hasCost)
              ButtonSegment(value: metric, label: Text(metric.label)),
        ],
        selected: {_metric},
        onSelectionChanged: (s) => setState(() => _selectedMetric = s.first),
      ),
      const SizedBox(height: 24),
      const GeminiAnalysisCard(),
      const SizedBox(height: 24),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              'Theo mục đích · ${_metric.label.toLowerCase()}',
              action: 'Cách tính',
              onAction: () => showInfo(context, 'Cách tính số liệu', [
                'Chi phí thực do bạn xác nhận: ${preciseMoney(summary.actualCostMicros)}',
                'Nhập tay: ${preciseMoney(summary.manualCostMicros)} · Chưa phân loại: ${preciseMoney(summary.unspecifiedCostMicros)}',
                '${summary.unknownCost} phiên thiếu chi phí · ${summary.unknownTokens} phiên thiếu token. Không tính dữ liệu thiếu là 0.',
              ]),
            ),
            if (total == 0)
              EmptyFeedback(
                title: 'Chưa có số liệu cho chỉ số này',
                message: 'Đổi sang số phiên, hoặc kết nối Companion để dữ liệu tự cập nhật.',
                action: 'Kết nối nguồn AI',
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ProviderConnectionsScreen(),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, c) {
                  final legend = Column(
                    children: shares
                        .map(
                          (p) => ActionSurface(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    HistoryScreen(purpose: p.purpose),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: AdaptivePair(
                                breakpoint: 220,
                                leading: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            PurposeRing.colors[shares.indexOf(
                                                  p,
                                                ) %
                                                PurposeRing.colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(p.purpose.label)),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${(p.value / total * 100).toStringAsFixed(1)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    Text(
                                      format(p.value),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    const Icon(Icons.chevron_right, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                  final ring = Semantics(
                    excludeSemantics: true,
                    label:
                        'Tổng ${format(total)}. Chi tiết từng mục đích ở danh sách.',
                    child: PurposeRing(
                      shares: shares,
                      center: format(total),
                      onSelected: (share) => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => HistoryScreen(purpose: share.purpose),
                        ),
                      ),
                    ),
                  );
                  return c.maxWidth >= 660
                      ? Row(
                          children: [
                            SizedBox(width: 240, child: Center(child: ring)),
                            const SizedBox(width: 32),
                            Expanded(child: legend),
                          ],
                        )
                      : Column(
                          children: [ring, const SizedBox(height: 20), legend],
                        );
                },
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('So sánh tài khoản'),
            ...projection.comparisons.map((comparison) {
              final a = comparison.account;
              final value = comparison.value;
              return ActionSurface(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HistoryScreen(accountId: a.id),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      AdaptivePair(
                        leading: Text(
                          a.alias,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        trailing: Text(format(value)),
                      ),
                      const SizedBox(height: 8),
                      AnimatedProgress(value: total == 0 ? 0 : value / total),
                    ],
                  ),
                ),
              );
            }),
            if (projection.comparisons.isEmpty)
              const Text('Chưa có phiên trong kỳ để so sánh tài khoản.'),
          ],
        ),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () => ExportReportDialog.show(context),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Xuất báo cáo PDF'),
      ),
    ];
  }
}
