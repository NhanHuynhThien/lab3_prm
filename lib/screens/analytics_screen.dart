import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usage_calculator.dart';
import '../models/cloud_sync_status.dart';
import '../widgets/provider_analytics_panel.dart';
import '../widgets/provider_ledger_feedback.dart';
import '../widgets/data_scope_picker.dart';
import 'usage_form_screen.dart';
import '../utils/formatters.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/ledger_feedback.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import '../widgets/export_report_dialog.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  UsageMetric? _selectedMetric;
  UsageMetric get _metric =>
      _selectedMetric ??
      UsageCalculator.preferredMetric(ref.read(filteredSessionsProvider));
  @override
  Widget build(BuildContext context) {
    final feedback = ledgerFeedback(ref.watch(ledgerProvider), 'Phân tích');
    final cloud = ref.watch(cloudOwnerProvider) != null;
    if (feedback != null) {
      return cloud ? ProviderLedgerFeedback(feedback: feedback) : feedback;
    }
    final projection = ref.watch(analyticsProjectionProvider(_metric));
    final summary = projection.summary;
    final shares = projection.shares;
    final total = projection.total;
    String format(int v) => switch (_metric) {
      UsageMetric.cost => preciseMoney(v),
      UsageMetric.tokens => compactTokens(v),
      UsageMetric.sessions => '$v',
    };
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        const PageHeading(
          'Phân tích sử dụng',
          'Hạn mức cần chú ý, model đang dùng và độ đầy đủ của dữ liệu.',
        ),
        if (cloud) ...[
          const ProviderAnalyticsPanel(),
          const SizedBox(height: 24),
          const SectionTitle('Phân tích các phiên tự ghi'),
          const Text(
            'Bộ lọc bên dưới áp dụng cho sổ thủ công, không thay đổi số liệu từ agent.',
          ),
          const SizedBox(height: 16),
        ],
        const DataScopePicker(),
        const SizedBox(height: 16),
        const RangePicker(),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<UsageMetric>(
            segments: UsageMetric.values
                .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                .toList(),
            selected: {_metric},
            onSelectionChanged: (s) =>
                setState(() => _selectedMetric = s.first),
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Theo mục đích · ${_metric.label.toLowerCase()}'),
              if (total == 0)
                EmptyFeedback(
                  title: 'Chưa có số liệu cho chỉ số này',
                  message: 'Bạn có thể đổi sang số phiên hoặc bổ sung dữ liệu sử dụng.',
                  action: 'Ghi sử dụng',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const UsageFormScreen(),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: AdaptivePair(
                                  breakpoint: 220,
                                  leading: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color:
                                              PurposeRing.colors[shares
                                                  .indexOf(p)
                                                  .clamp(0, 3)],
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
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
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
                            builder: (_) =>
                                HistoryScreen(purpose: share.purpose),
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
                            children: [
                              ring,
                              const SizedBox(height: 20),
                              legend,
                            ],
                          );
                  },
                ),
              const SizedBox(height: 16),
              Text(
                'Chi phí thực do bạn xác nhận: ${preciseMoney(summary.actualCostMicros)} · Nhập tay: ${preciseMoney(summary.manualCostMicros)} · Chưa phân loại: ${preciseMoney(summary.unspecifiedCostMicros)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.unknownCost} phiên thiếu chi phí · ${summary.unknownTokens} phiên thiếu token. Không tính dữ liệu thiếu là 0.',
                style: Theme.of(context).textTheme.bodySmall,
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
                final s = comparison.summary;
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${s.count} phiên · ${s.unknownCost} phiên chưa biết chi phí',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (projection.comparisons.isEmpty)
                const Text('Chưa có tài khoản để so sánh.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Theo nhà cung cấp'),
              if (projection.providers.isEmpty)
                const Text('Chưa có phiên trong kỳ và nguồn đã chọn.'),
              ...projection.providers.map(
                (p) => ActionSurface(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(provider: p.provider),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: AdaptivePair(
                      leading: Text(p.provider),
                      trailing: Text(
                        '${format(p.value)} · ${p.summary.count} phiên',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ExportReportDialog.show(context),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Xuất báo cáo PDF & Cloud Storage'),
        ),
      ],
    );
  }
}
